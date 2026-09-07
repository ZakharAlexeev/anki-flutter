/// Pure data types for the scheduler. No Flutter/Drift dependencies here so
/// the algorithm stays independently testable.
library;

enum CardQueue { newCard, learning, review, relearning, suspended }

enum Rating { again, hard, good, easy }

class SchedulingReview {
  const SchedulingReview({required this.reviewedAt, required this.rating});

  final int reviewedAt;
  final Rating rating;
}

/// Scheduling parameters for a deck (mirrors Anki's DeckConfig "new"/"rev"/
/// "lapse" groups).
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
  final int leechThreshold; // lapses count that triggers a leech, default 8
  final int maximumIntervalDays; // default 36500
  final int minEase; // ease floor * 1000, default 1300 (130%)
  final List<double> fsrsParameters;
  final double desiredRetention;

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
    this.leechThreshold = 8,
    this.maximumIntervalDays = 36500,
    this.minEase = 1300,
    this.fsrsParameters = const [
      0.2172,
      1.1771,
      3.2602,
      16.1507,
      7.0114,
      0.57,
      2.0966,
      0.0069,
      1.5261,
      0.112,
      1.0178,
      1.849,
      0.1133,
      0.3127,
      2.2934,
      0.2191,
      3.0004,
      0.7536,
      0.3332,
      0.1437,
      0.2,
    ],
    this.desiredRetention = 0.9,
  });
}

/// The scheduling-relevant state of a single card. `due` is overloaded like
/// in Anki: a day-number while [queue] is review/suspended-after-review, or
/// epoch-seconds while [queue] is learning/relearning.
class CardSchedState {
  final CardQueue queue;
  final int due;
  final int ivl; // days
  final int ease; // * 1000
  final int reps;
  final int lapses;
  final int stepIndex;
  final double? stability;
  final double? difficulty;
  final int? lastReviewedAt;

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
    this.lastReviewedAt,
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
    double? stability,
    double? difficulty,
    int? lastReviewedAt,
    bool clearMemoryState = false,
  }) {
    return CardSchedState(
      queue: queue ?? this.queue,
      due: due ?? this.due,
      ivl: ivl ?? this.ivl,
      ease: ease ?? this.ease,
      reps: reps ?? this.reps,
      lapses: lapses ?? this.lapses,
      stepIndex: stepIndex ?? this.stepIndex,
      stability: clearMemoryState ? null : (stability ?? this.stability),
      difficulty: clearMemoryState ? null : (difficulty ?? this.difficulty),
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    );
  }
}

/// Result of answering a card: the new persisted state plus flags the caller
/// (repository/UI) needs to react to but that are not part of the state
/// itself.
class AnswerOutcome {
  final CardSchedState state;
  final bool becameLeech;

  const AnswerOutcome(this.state, {this.becameLeech = false});
}
