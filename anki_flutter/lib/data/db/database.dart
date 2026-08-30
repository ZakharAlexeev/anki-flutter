import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../domain/scheduler/models.dart' show CardQueue;
import 'tables.dart';

export '../../domain/scheduler/models.dart' show CardQueue, Rating, CardSchedState;

part 'database.g.dart';

@DriftDatabase(tables: [
  DeckConfigs,
  Decks,
  Notetypes,
  NotetypeFields,
  NotetypeTemplates,
  Notes,
  Cards,
  RevLog,
  CollectionMeta,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createPerformanceIndexes();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(decks, decks.newShownToday);
            await m.addColumn(decks, decks.newShownDay);
            await m.addColumn(decks, decks.reviewsShownToday);
            await m.addColumn(decks, decks.reviewsShownDay);

            // v1 accidentally stored createdAt in *microseconds* (reusing
            // the ID generator) instead of milliseconds. A real millisecond
            // "now" is ~13 digits; a microsecond value misread as millis is
            // ~16, comfortably past this threshold (year ~5138 in millis).
            const microsecondThreshold = 100000000000000; // 1e14
            await customStatement(
              'UPDATE collection_meta SET created_at = created_at / 1000 WHERE created_at > $microsecondThreshold',
            );
            await customStatement(
              'UPDATE notes SET created_at = created_at / 1000 WHERE created_at > $microsecondThreshold',
            );
          }
          if (from < 3) await _createPerformanceIndexes();
        },
        beforeOpen: (details) async {
          // SQLite defaults foreign-key enforcement to OFF for backwards
          // compatibility - without this, deleting a deck/notetype out from
          // under a card would silently leave a dangling reference instead
          // of erroring, masking bugs in the cleanup code that's supposed
          // to delete dependents first (see deck_repository.dart,
          // notetype_repository.dart, note_repository.dart).
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<void> _createPerformanceIndexes() async {
    await customStatement('CREATE INDEX IF NOT EXISTS idx_cards_deck_queue_due ON cards(deck_id, queue, due)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_cards_note_template ON cards(note_id, template_ord)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_revlog_card_reviewed ON rev_log(card_id, reviewed_at)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_revlog_reviewed ON rev_log(reviewed_at)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_fields_notetype_ord ON notetype_fields(notetype_id, ord)');
    await customStatement('CREATE INDEX IF NOT EXISTS idx_templates_notetype_ord ON notetype_templates(notetype_id, ord)');
  }

  /// Ensures a single [CollectionMeta] row and the built-in starter content
  /// exist. Safe to call on every startup.
  Future<void> ensureSeeded() async {
    await transaction(() async {
      // getSingleOrNull() throws if more than one row comes back, so every
      // "does this table already have anything in it" check here is capped
      // with limit(1) - otherwise this crashes on every startup after the
      // first, once these tables legitimately hold more than one row.
      final metaExists = await (select(collectionMeta)..limit(1)).getSingleOrNull();
      if (metaExists == null) {
        await into(collectionMeta).insert(const CollectionMetaCompanion(id: Value(1)));
      }

      final anyDeckConfig = await (select(deckConfigs)..limit(1)).getSingleOrNull();
      var deckConfigId = anyDeckConfig?.id;
      deckConfigId ??= await into(deckConfigs).insert(const DeckConfigsCompanion(name: Value('Default')));

      final defaultDeck = await (select(decks)..where((d) => d.name.equals('Default'))).getSingleOrNull();
      if (defaultDeck == null) {
        await into(decks).insert(DecksCompanion(name: const Value('Default'), deckConfigId: Value(deckConfigId)));
      }

      await _ensureEnglishVocabularySeed(deckConfigId);
    });
  }

  Future<void> _ensureEnglishVocabularySeed(int deckConfigId) async {
    const deckName = 'Английский';
    const notetypeName = 'English Vocabulary RU→EN';

    final existingEnglishDeck =
        await (select(decks)..where((d) => d.name.equals(deckName))).getSingleOrNull();
    final int englishDeckId;
    if (existingEnglishDeck == null) {
      englishDeckId = await into(decks).insert(
        DecksCompanion(name: const Value(deckName), deckConfigId: Value(deckConfigId)),
      );
    } else {
      englishDeckId = existingEnglishDeck.id;
    }

    final existingVocabularyType =
        await (select(notetypes)..where((n) => n.name.equals(notetypeName))).getSingleOrNull();
    final int vocabularyTypeId;
    if (existingVocabularyType == null) {
      vocabularyTypeId = await into(notetypes).insert(
        const NotetypesCompanion(name: Value(notetypeName)),
      );
      await into(notetypeFields).insert(
        NotetypeFieldsCompanion(
          notetypeId: Value(vocabularyTypeId),
          name: const Value('Russian'),
          ord: const Value(0),
        ),
      );
      await into(notetypeFields).insert(
        NotetypeFieldsCompanion(
          notetypeId: Value(vocabularyTypeId),
          name: const Value('English'),
          ord: const Value(1),
        ),
      );
      await into(notetypeTemplates).insert(
        NotetypeTemplatesCompanion(
          notetypeId: Value(vocabularyTypeId),
          name: const Value('Russian → English'),
          ord: const Value(0),
          questionFormat: const Value('{{Russian}}'),
          answerFormat: const Value('{{English}}'),
        ),
      );
    } else {
      vocabularyTypeId = existingVocabularyType.id;
    }

    // The notetype itself is the idempotency marker. If it already owns any
    // notes, this starter pack has been installed before and must not be
    // duplicated on future launches.
    final existingSeed = await (select(notes)
          ..where((n) => n.notetypeId.equals(vocabularyTypeId))
          ..limit(1))
        .getSingleOrNull();
    if (existingSeed != null) return;

    for (var i = 0; i < _englishVocabularySeed.length; i++) {
      final entry = _englishVocabularySeed[i];
      final noteId = await into(notes).insert(
        NotesCompanion(
          notetypeId: Value(vocabularyTypeId),
          fieldsJson: Value(jsonEncode([entry.russian, entry.english])),
          tags: const Value('seed::english'),
        ),
      );
      await into(cards).insert(
        CardsCompanion(
          noteId: Value(noteId),
          deckId: Value(englishDeckId),
          templateOrd: const Value(0),
          due: Value(i),
        ),
      );
    }
  }
}

class _VocabularySeedEntry {
  const _VocabularySeedEntry(this.russian, this.english);

  final String russian;
  final String english;
}

const _englishVocabularySeed = <_VocabularySeedEntry>[
  _VocabularySeedEntry('придерживаться своих принципов', 'adhere to your principles'),
  _VocabularySeedEntry('вызвать у кого-либо интерес', "arouse someone's interest"),
  _VocabularySeedEntry('предложить / выступить с предложением', 'come up with a suggestion'),
  _VocabularySeedEntry('категорически противоречить', 'flatly contradict'),
  _VocabularySeedEntry('принципиально разные', 'fundamentally different'),
  _VocabularySeedEntry('начать экономить', 'go on an economy drive'),
  _VocabularySeedEntry('сильный дождь', 'heavy rain'),
  _VocabularySeedEntry('вести семинар', 'lead a seminar'),
  _VocabularySeedEntry('слой краски', 'a lick of paint'),
  _VocabularySeedEntry('играть на бирже', 'play the stock market'),
  _VocabularySeedEntry('мудрые слова / мудрость', 'words of wisdom'),
  _VocabularySeedEntry('аппетитный; такой, что слюнки текут', 'mouth-watering'),
  _VocabularySeedEntry('красивый, как на картине', 'picturesque'),
  _VocabularySeedEntry('очень красивый; потрясающий', 'stunning'),
  _VocabularySeedEntry('просторный', 'spacious'),
  _VocabularySeedEntry('уединённый', 'secluded'),
  _VocabularySeedEntry('отступать от; отклоняться от', 'depart from'),
  _VocabularySeedEntry('смягчающие обстоятельства / факторы', 'mitigating circumstances / factors'),
  _VocabularySeedEntry('ненастная / плохая погода', 'inclement weather'),
  _VocabularySeedEntry('каштановые волосы', 'auburn hair'),
  _VocabularySeedEntry('очень счастливый', 'deliriously happy'),
  _VocabularySeedEntry('прервать / отложить встречу', 'adjourn the meeting'),
  _VocabularySeedEntry('туда и сюда', 'to and fro'),
  _VocabularySeedEntry('согласие по основным вопросам', 'in broad agreement'),
  _VocabularySeedEntry('широкий проспект', 'a broad avenue'),
  _VocabularySeedEntry('широкая улыбка / широкие плечи', 'a broad smile / broad shoulders'),
  _VocabularySeedEntry('сильный, ярко выраженный акцент', 'a broad accent'),
  _VocabularySeedEntry('явный намёк', 'a broad hint'),
  _VocabularySeedEntry('широкий спектр', 'a broad range'),
  _VocabularySeedEntry('длинное путешествие, как правило по морю', 'voyage'),
  _VocabularySeedEntry('поездка из одного места в другое', 'journey'),
  _VocabularySeedEntry('короткая поездка, обычно с определённой целью', 'trip'),
  _VocabularySeedEntry('перемещение / путешествие как процесс', 'travel'),
  _VocabularySeedEntry('панорама; то, что видно из конкретного места', 'view'),
  _VocabularySeedEntry('достопримечательность; то, что привлекает внимание', 'sight'),
  _VocabularySeedEntry('область; площадь', 'area'),
  _VocabularySeedEntry('территория под управлением', 'territory'),
  _VocabularySeedEntry('период регулярного события или пик активности', 'season'),
  _VocabularySeedEntry('отрезок времени с чётким началом и концом', 'period'),
  _VocabularySeedEntry('билет', 'ticket'),
  _VocabularySeedEntry('тариф; стоимость проезда', 'fare'),
  _VocabularySeedEntry('оплата услуги', 'fee'),
  _VocabularySeedEntry('принести', 'bring'),
  _VocabularySeedEntry('отнести', 'take'),
  _VocabularySeedEntry('идти', 'go'),
  _VocabularySeedEntry('идти впереди и вести за собой', 'lead'),
  _VocabularySeedEntry('указывать путь', 'guide'),
  _VocabularySeedEntry('догнать; поравняться с', 'catch up with'),
  _VocabularySeedEntry('зарегистрироваться в аэропорту / отеле', 'check in'),
  _VocabularySeedEntry('выписаться из отеля', 'check out'),
  _VocabularySeedEntry('высадить кого-либо из транспорта', 'drop off'),
  _VocabularySeedEntry('вернуться из какого-либо места', 'get back'),
  _VocabularySeedEntry('уехать; отправиться в отпуск', 'go away'),
  _VocabularySeedEntry('держаться в том же темпе; не отставать от', 'keep up with'),
  _VocabularySeedEntry('направляться к / в сторону', 'make for'),
  _VocabularySeedEntry('подобрать кого-либо на транспорте', 'pick up'),
  _VocabularySeedEntry('прибыть / подъехать', 'pull in'),
  _VocabularySeedEntry('задавить кого-либо транспортом', 'run over'),
  _VocabularySeedEntry('проводить уезжающего', 'see off'),
  _VocabularySeedEntry('отправиться в поездку / путь', 'set out'),
  _VocabularySeedEntry('взлететь', 'take off'),
  _VocabularySeedEntry('развернуться', 'turn round'),
];

QueryExecutor _openConnection() {
  return driftDatabase(name: 'anki_flutter');
}
