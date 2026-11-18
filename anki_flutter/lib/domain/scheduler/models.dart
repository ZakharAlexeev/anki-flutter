/// Pure data types for the scheduler. No Flutter/Drift dependencies here so
/// the algorithm stays independently testable.
library;

/// A card's queue. `interdayLearning`/`interdayRelearning` are Anki's
/// "day learn" queue: a learning step that crosses the day boundary (e.g. a
/// 1-day step), due on a day number rather than at a time.
enum CardQueue { newCard, learning, review, relearning, suspended, interdayLearning, interdayRelearning }

enum Rating { again, hard, good, easy }

/// Scheduling options of a deck preset (Anki's DeckConfig).
class DeckSchedConfig {
  final List<int> learningStepsMin;
  final List<int> relearningStepsMin;
  final int graduatingIntervalDays;
  final int easyIntervalDays;
  final int startingEase; // ease * 1000, default 2500 (250%)
  final double easyBonus; // default 1.3
  final double intervalModifier; // default 1.0
  final double hardIntervalMultiplier; // default 1.2
  final double newIntervalMultiplier; // lapse multiplier, default 0.0
  final int minimumLapseInterval; // days, default 1
  final int leechThreshold; // lapses count that triggers a leech, default 8
  final bool leechSuspends; // leech action: suspend (true) or only tag (false, Anki's default)
  final int maximumIntervalDays; // default 36500
  final int minEase; // ease floor * 1000, default 1300 (130%), fixed in Anki

  // FSRS (used when FSRS is enabled for the collection).
  final List<double> fsrsParams; // empty = defaults
  final double desiredRetention; // default 0.9
  final double historicalRetention; // "SM-2 retention", default 0.9
  /// Revlog entries before this time (epoch ms) are ignored when deriving
  /// memory states; 0 = none.
  final int ignoreRevlogsBeforeMs;

  /// Load-balancer "easy days" (Mon..Sun): 1.0 normal, 0.0 minimum, else
  /// reduced. Empty = all normal.
  final List<double> easyDaysPercentages;

  const DeckSchedConfig({
    this.learningStepsMin = const [1, 10],
    this.relearningStepsMin = const [10],
    this.graduatingIntervalDays = 1,
    this.easyIntervalDays = 4,
    this.startingEase = 2500,
    this.easyBonus = 1.3,
    this.intervalModifier = 1.0,
    this.hardIntervalMultiplier = 1.2,
    this.newIntervalMultiplier = 0.0,
    this.minimumLapseInterval = 1,
    this.leechThreshold = 8,
    this.leechSuspends = false,
    this.maximumIntervalDays = 36500,
    this.minEase = 1300,
    this.fsrsParams = const [],
    this.desiredRetention = 0.9,
    this.historicalRetention = 0.9,
    this.ignoreRevlogsBeforeMs = 0,
    this.easyDaysPercentages = const [],
  });
}

/// Result of answering a card: the new persisted state plus flags the caller
/// (repository/UI) needs to react to but that are not part of the state
/// itself.
class AnswerOutcome {
  final CardSchedState state;
  final bool becameLeech;

  const AnswerOutcome(this.state, {this.becameLeech = false});
}

/// The scheduling-relevant state of a single card as stored. `due` is a
/// day-number for review/interday queues, epoch-seconds for intraday
/// learning/relearning, and the position for new cards.
class CardSchedState {
  final CardQueue queue;
  final int due;
  final int ivl; // days
  final int ease; // * 1000
  final int reps;
  final int lapses;
  final int stepIndex;

  /// FSRS memory state (stability in days, difficulty 1-10), if any.
  final double? stability;
  final double? difficulty;

  const CardSchedState({
    required this.queue,
    required this.due,
    this.ivl = 0,
    required this.ease,
    this.reps = 0,
    this.lapses = 0,
    this.stepIndex = 0,
    this.stability,
    this.difficulty,
  });

  factory CardSchedState.newCard({required int due, required int startingEase}) {
    return CardSchedState(queue: CardQueue.newCard, due: due, ease: startingEase);
  }

  CardSchedState copyWith({
    CardQueue? queue,
    int? due,
    int? ivl,
    int? ease,
    int? reps,
    int? lapses,
    int? stepIndex,
  }) {
    return CardSchedState(
      queue: queue ?? this.queue,
      due: due ?? this.due,
      ivl: ivl ?? this.ivl,
      ease: ease ?? this.ease,
      reps: reps ?? this.reps,
      lapses: lapses ?? this.lapses,
      stepIndex: stepIndex ?? this.stepIndex,
      stability: stability,
      difficulty: difficulty,
    );
  }
}
