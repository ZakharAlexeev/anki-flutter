import 'package:drift/drift.dart';

import '../../domain/scheduler/models.dart' show CardQueue;

/// IDs default to a locally-monotonic microsecond timestamp. Plain
/// `DateTime.now().millisecondsSinceEpoch` collides when two rows are
/// inserted in the same millisecond - e.g. creating a note from a two-sided
/// note type inserts two cards back to back - which trips SQLite's UNIQUE
/// constraint on the primary key. Bumping to the previous value + 1 whenever
/// the clock hasn't advanced keeps every locally-generated ID unique. Being
/// microsecond-precision also keeps these well clear of the epoch-*millis*
/// IDs an imported .apkg carries over (those are ~1000x smaller), so the two
/// ID spaces never collide either.
///
/// This is an ID generator, not a clock - never use it for a column that's
/// actually supposed to hold a wall-clock timestamp (see [epochMillisNow]).
int _lastIssuedId = 0;
int epochMillisId() {
  final now = DateTime.now().microsecondsSinceEpoch;
  _lastIssuedId = now > _lastIssuedId ? now : _lastIssuedId + 1;
  return _lastIssuedId;
}

/// A real `millisecondsSinceEpoch` wall-clock timestamp, for columns like
/// `createdAt` that other code reads back with `DateTime.fromMillisecondsSinceEpoch`
/// - as opposed to [epochMillisId], which is microsecond-precision and meant
/// only for primary keys.
int epochMillisNow() => DateTime.now().millisecondsSinceEpoch;

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

  /// How many new cards have been *first shown* today, and which collection
  /// day-number that count is for (so it lazily resets whenever `today`
  /// moves on, without needing a background job). Mirrors Anki's own
  /// per-deck `newToday`/`revToday` counters - without these, "new cards
  /// per day" is just a query LIMIT, so leaving and re-entering a deck
  /// resets it to the full limit again.
  IntColumn get newShownToday => integer().withDefault(const Constant(0))();
  IntColumn get newShownDay => integer().withDefault(const Constant(-1))();
  IntColumn get reviewsShownToday => integer().withDefault(const Constant(0))();
  IntColumn get reviewsShownDay => integer().withDefault(const Constant(-1))();

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
  IntColumn get createdAt => integer().clientDefault(epochMillisNow)();

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
  IntColumn get createdAt => integer().clientDefault(epochMillisNow)();
  IntColumn get rolloverHour => integer().withDefault(const Constant(4))();

  @override
  Set<Column> get primaryKey => {id};
}
