import 'dart:math';

import 'package:drift/drift.dart';

import '../../domain/scheduler/day_calendar.dart';
import '../../domain/scheduler/models.dart';
import '../../domain/scheduler/scheduler.dart';
import '../db/database.dart';
import 'sched_config_mapper.dart';

class DueQueueCounts {
  final int newCount;
  final int learningCount;
  final int reviewCount;

  const DueQueueCounts({required this.newCount, required this.learningCount, required this.reviewCount});

  int get total => newCount + learningCount + reviewCount;
}

/// Bridges the pure [Scheduler] to persisted state: builds each deck's due
/// queue, and applies + records answers inside a transaction.
class StudyRepository {
  StudyRepository(this._db);

  final AppDatabase _db;
  static const _scheduler = Scheduler();

  Future<int> today(DateTime now) async {
    final meta = await _db.select(_db.collectionMeta).getSingle();
    return dayNumber(now, DateTime.fromMillisecondsSinceEpoch(meta.createdAt), rolloverHour: meta.rolloverHour);
  }

  Future<DeckConfig> _configRowForDeck(int deckId) async {
    final deck = await (_db.select(_db.decks)..where((d) => d.id.equals(deckId))).getSingle();
    return (_db.select(_db.deckConfigs)..where((c) => c.id.equals(deck.deckConfigId))).getSingle();
  }

  /// Cards ready to study right now, ordered learning -> review -> new
  /// (a simplified but faithful approximation of Anki's default mix).
  Future<List<CardEntry>> dueQueue(int deckId, {DateTime? now}) async {
    final n = now ?? DateTime.now();
    final t = await today(n);
    final nowSec = n.millisecondsSinceEpoch ~/ 1000;
    final cfg = await _configRowForDeck(deckId);

    final learning = await (_db.select(_db.cards)
          ..where((c) =>
              c.deckId.equals(deckId) &
              (c.queue.equalsValue(CardQueue.learning) | c.queue.equalsValue(CardQueue.relearning)) &
              c.due.isSmallerOrEqualValue(nowSec))
          ..orderBy([(c) => OrderingTerm.asc(c.due)]))
        .get();

    final review = await (_db.select(_db.cards)
          ..where((c) =>
              c.deckId.equals(deckId) & c.queue.equalsValue(CardQueue.review) & c.due.isSmallerOrEqualValue(t))
          ..orderBy([(c) => OrderingTerm.asc(c.due)])
          ..limit(cfg.reviewsPerDay))
        .get();

    final newCards = await (_db.select(_db.cards)
          ..where((c) => c.deckId.equals(deckId) & c.queue.equalsValue(CardQueue.newCard))
          ..orderBy([(c) => OrderingTerm.asc(c.id)])
          ..limit(cfg.newPerDay))
        .get();

    return [...learning, ...review, ...newCards];
  }

  Future<DueQueueCounts> counts(int deckId, {DateTime? now}) async {
    final cards = await dueQueue(deckId, now: now);
    return DueQueueCounts(
      newCount: cards.where((c) => c.queue == CardQueue.newCard).length,
      learningCount: cards.where((c) => c.queue == CardQueue.learning || c.queue == CardQueue.relearning).length,
      reviewCount: cards.where((c) => c.queue == CardQueue.review).length,
    );
  }

  /// What each of the four buttons would do to [cardId] right now, without
  /// persisting anything - used to render interval previews under the
  /// Again/Hard/Good/Easy buttons.
  Future<Map<Rating, CardSchedState>> previewOutcomes(int cardId, {DateTime? now}) async {
    final n = now ?? DateTime.now();
    final entry = await (_db.select(_db.cards)..where((c) => c.id.equals(cardId))).getSingle();
    final cfgRow = await _configRowForDeck(entry.deckId);
    final config = schedConfigFromRow(cfgRow);
    final t = await today(n);
    return _scheduler.previewOutcomes(card: _stateFromEntry(entry), config: config, now: n, today: t);
  }

  /// Applies [rating] to [cardId], persists the new scheduling state and
  /// appends a revlog entry, all in one transaction.
  Future<AnswerOutcome> answerCard({
    required int cardId,
    required Rating rating,
    DateTime? now,
    Random? random,
  }) async {
    final n = now ?? DateTime.now();
    final entry = await (_db.select(_db.cards)..where((c) => c.id.equals(cardId))).getSingle();
    final cfgRow = await _configRowForDeck(entry.deckId);
    final config = schedConfigFromRow(cfgRow);
    final t = await today(n);
    final nowSec = n.millisecondsSinceEpoch ~/ 1000;

    final outcome = _scheduler.answerCard(
      card: _stateFromEntry(entry),
      config: config,
      rating: rating,
      now: n,
      today: t,
      random: random ?? Random(),
    );

    await _db.transaction(() async {
      await (_db.update(_db.cards)..where((c) => c.id.equals(cardId))).write(CardsCompanion(
        queue: Value(outcome.state.queue),
        due: Value(outcome.state.due),
        ivl: Value(outcome.state.ivl),
        ease: Value(outcome.state.ease),
        reps: Value(outcome.state.reps),
        lapses: Value(outcome.state.lapses),
        stepIndex: Value(outcome.state.stepIndex),
        lastReviewedAt: Value(nowSec),
      ));
      await _db.into(_db.revLog).insert(RevLogCompanion.insert(
            cardId: cardId,
            reviewedAt: nowSec,
            rating: ratingToInt(rating),
            ivlBefore: entry.ivl,
            ivlAfter: outcome.state.ivl,
            easeAfter: outcome.state.ease,
          ));
    });

    return outcome;
  }

  CardSchedState _stateFromEntry(CardEntry entry) => CardSchedState(
        queue: entry.queue,
        due: entry.due,
        ivl: entry.ivl,
        ease: entry.ease,
        reps: entry.reps,
        lapses: entry.lapses,
        stepIndex: entry.stepIndex,
      );
}
