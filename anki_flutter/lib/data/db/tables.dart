import 'package:drift/drift.dart';

import '../../domain/scheduler/models.dart' show CardQueue;

/// IDs default to the current epoch-millis timestamp, matching Anki's own
/// scheme - this keeps imported Anki IDs and locally-created IDs in the same
/// space and lets an .apkg import simply carry over the source IDs (with a
/// collision offset applied by the importer when needed).
int epochMillisId() => DateTime.now().millisecondsSinceEpoch;

class DeckConfigs extends Table {
  IntColumn get id => integer().clientDefault(epochMillisId)();
  TextColumn get name => text()();
  TextColumn get learningStepsMin => text().withDefault(const Constant('1,10'))();
  TextColumn get relearningStepsMin => text().withDefault(const Constant('10'))();
  IntColumn get graduatingIntervalDays => integer().withDefault(const Constant(1))();
  IntColumn get easyIntervalDays => integer().withDefault(const Constant(4))();
  IntColumn get startingEase => integer().withDefault(const Constant(2500))();
  IntColumn get easyBonusPct => integer().withDefault(const Constant(130))();
  IntColumn get intervalModifierPct => integer().withDefault(const Constant(100))();
  IntColumn get hardIntervalPct => integer().withDefault(const Constant(120))();
  IntColumn get newIntervalPct => integer().withDefault(const Constant(0))();
  IntColumn get leechThreshold => integer().withDefault(const Constant(8))();
  IntColumn get maximumIntervalDays => integer().withDefault(const Constant(36500))();
  IntColumn get minEase => integer().withDefault(const Constant(1300))();
  IntColumn get newPerDay => integer().withDefault(const Constant(20))();
  IntColumn get reviewsPerDay => integer().withDefault(const Constant(200))();

  @override
  Set<Column> get primaryKey => {id};
}

class Decks extends Table {
  IntColumn get id => integer().clientDefault(epochMillisId)();
  TextColumn get name => text().unique()();
  IntColumn get deckConfigId => integer().references(DeckConfigs, #id)();
  IntColumn get newPerDayOverride => integer().nullable()();
  IntColumn get reviewsPerDayOverride => integer().nullable()();
  BoolColumn get collapsed => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Notetypes extends Table {
  IntColumn get id => integer().clientDefault(epochMillisId)();
  TextColumn get name => text()();
  TextColumn get css => text().withDefault(const Constant(''))();
  IntColumn get sortFieldIndex => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class NotetypeFields extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get notetypeId => integer().references(Notetypes, #id)();
  TextColumn get name => text()();
  IntColumn get ord => integer()();
}

class NotetypeTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get notetypeId => integer().references(Notetypes, #id)();
  TextColumn get name => text()();
  IntColumn get ord => integer()();
  TextColumn get questionFormat => text().withDefault(const Constant(''))();
  TextColumn get answerFormat => text().withDefault(const Constant(''))();
}

class Notes extends Table {
  IntColumn get id => integer().clientDefault(epochMillisId)();
  IntColumn get notetypeId => integer().references(Notetypes, #id)();
  /// JSON-encoded `List<String>`, one entry per NotetypeField, in `ord` order.
  TextColumn get fieldsJson => text()();
  /// Space-separated, same convention Anki uses.
  TextColumn get tags => text().withDefault(const Constant(''))();
  IntColumn get createdAt => integer().clientDefault(epochMillisId)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CardEntry') // avoid colliding with Flutter's own Card widget
class Cards extends Table {
  IntColumn get id => integer().clientDefault(epochMillisId)();
  IntColumn get noteId => integer().references(Notes, #id)();
  IntColumn get deckId => integer().references(Decks, #id)();
  IntColumn get templateOrd => integer()();
  TextColumn get queue => textEnum<CardQueue>().withDefault(Constant(CardQueue.newCard.name))();
  /// Day-number while [queue] is review/suspended; epoch-seconds while
  /// learning/relearning; a stable per-deck ordering key while new.
  IntColumn get due => integer().withDefault(const Constant(0))();
  IntColumn get ivl => integer().withDefault(const Constant(0))();
  IntColumn get ease => integer().withDefault(const Constant(2500))();
  IntColumn get reps => integer().withDefault(const Constant(0))();
  IntColumn get lapses => integer().withDefault(const Constant(0))();
  IntColumn get stepIndex => integer().withDefault(const Constant(0))();
  IntColumn get lastReviewedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class RevLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get cardId => integer().references(Cards, #id)();
  IntColumn get reviewedAt => integer()();
  /// 1=Again, 2=Hard, 3=Good, 4=Easy - matches Anki's revlog.ease convention.
  IntColumn get rating => integer()();
  IntColumn get ivlBefore => integer()();
  IntColumn get ivlAfter => integer()();
  IntColumn get easeAfter => integer()();
  IntColumn get timeTakenMs => integer().withDefault(const Constant(0))();
}

class CollectionMeta extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  IntColumn get createdAt => integer().clientDefault(epochMillisId)();
  IntColumn get rolloverHour => integer().withDefault(const Constant(4))();

  @override
  Set<Column> get primaryKey => {id};
}
