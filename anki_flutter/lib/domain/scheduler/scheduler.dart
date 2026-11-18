import 'dart:math' as math;

import 'f32.dart';
import 'fsrs.dart';
import 'fuzz.dart';
import 'models.dart';

/// A line-by-line port of Anki 26.09's card state machine (rslib
/// `scheduler/states` and `scheduler/answering`): how a new, learning,
/// review or relearning card moves for each of the four buttons, under
/// either SM-2 or FSRS, including learning steps, short-term FSRS steps,
/// fuzz, the load balancer hook, leeches, and how the result is written
/// back to the card and the review log.

// --- learning steps (states/steps.rs) --------------------------------------

const _day = 86400;

class LearningSteps {
  LearningSteps(List<int> minutes) : _steps = [for (final m in minutes) f32(m.toDouble())];
  final List<double> _steps;

  static int _toSecs(double v) => truncToU32(f32(v * 60));

  int _index(int remaining) {
    final total = _steps.length;
    return math.min(math.max(total - (remaining % 1000), 0), math.max(total - 1, 0));
  }

  int? _secsAt(int index) => index >= 0 && index < _steps.length ? _toSecs(_steps[index]) : null;

  bool get isEmpty => _steps.isEmpty;
  int get length => _steps.length;

  int? againDelaySecsLearn() => _secsAt(0);

  int? hardDelaySecs(int remaining) {
    final idx = _index(remaining);
    final current = _secsAt(idx) ?? (_steps.isEmpty ? null : _toSecs(_steps.first));
    if (current == null) return null;
    if (idx != 0) return current;
    final next = _secsAt(1);
    if (next != null) return _maybeRoundInDays((current + next) ~/ 2);
    return _maybeRoundInDays(math.min(current * 3 ~/ 2, current + _day));
  }

  int? goodDelaySecs(int remaining) => _secsAt(_index(remaining) + 1);

  int currentDelaySecs(int remaining) => _secsAt(_index(remaining)) ?? 0;

  int remainingForGood(int remaining) => math.max(_steps.length - (_index(remaining) + 1), 0);

  int remainingForFailed() => _steps.length;

  static int _maybeRoundInDays(int secs) =>
      secs > _day ? roundToU32(f32(secs / _day.toDouble())) * _day : secs;
}

// --- states ----------------------------------------------------------------

sealed class CardState {
  const CardState();
}

class NewState extends CardState {
  const NewState(this.position);
  final int position;
}

class LearnState extends CardState {
  const LearnState({required this.remainingSteps, required this.scheduledSecs, this.elapsedSecs = 0, this.memory});
  final int remainingSteps;
  final int scheduledSecs;
  final int elapsedSecs;
  final MemoryState? memory;

  /// Like Rust's `LearnState { memory_state, ..self }`: [memory] always
  /// replaces the old value (null clears it, as with SM-2).
  LearnState withMemory(MemoryState? memory, {int? remainingSteps, int? scheduledSecs, int? elapsedSecs}) =>
      LearnState(
        remainingSteps: remainingSteps ?? this.remainingSteps,
        scheduledSecs: scheduledSecs ?? this.scheduledSecs,
        elapsedSecs: elapsedSecs ?? this.elapsedSecs,
        memory: memory,
      );
}

class ReviewState extends CardState {
  const ReviewState({
    this.scheduledDays = 0,
    this.elapsedDays = 0,
    this.easeFactor = 2.5,
    this.lapses = 0,
    this.leeched = false,
    this.memory,
  });
  final int scheduledDays;
  final int elapsedDays;
  final double easeFactor; // f32
  final int lapses;
  final bool leeched;
  final MemoryState? memory;

  int get daysLate => elapsedDays - scheduledDays;

  /// Like Rust's `ReviewState { memory_state, ..self }`: [memory] always
  /// replaces the old value (null clears it, as with SM-2).
  ReviewState withMemory(MemoryState? memory, {int? scheduledDays, int? elapsedDays, double? easeFactor}) =>
      ReviewState(
        scheduledDays: scheduledDays ?? this.scheduledDays,
        elapsedDays: elapsedDays ?? this.elapsedDays,
        easeFactor: easeFactor ?? this.easeFactor,
        lapses: lapses,
        leeched: leeched,
        memory: memory,
      );
}

class RelearnState extends CardState {
  const RelearnState(this.learning, this.review);
  final LearnState learning;
  final ReviewState review;
}

class SchedulingStates {
  const SchedulingStates(this.current, this.again, this.hard, this.good, this.easy);
  final CardState current;
  final CardState again;
  final CardState hard;
  final CardState good;
  final CardState easy;

  CardState forRating(Rating r) => switch (r) {
        Rating.again => again,
        Rating.hard => hard,
        Rating.good => good,
        Rating.easy => easy,
      };
}

/// Load balancer hook: picks a review interval in the fuzz range, or null
/// to fall back to plain fuzz (see `load_balancer.dart`).
typedef FindInterval = int? Function(double interval, int minimum, int maximum);

class StateContext {
  StateContext({
    required this.config,
    required this.fuzzFactor,
    this.fsrsNextStates,
    this.fsrsAllowShortTerm = false,
    this.fsrsShortTermWithSteps = false,
    this.loadBalancer,
  })  : steps = LearningSteps(config.learningStepsMin),
        relearnSteps = LearningSteps(config.relearningStepsMin);

  final DeckSchedConfig config;
  final double? fuzzFactor;
  final NextStates? fsrsNextStates;
  final bool fsrsAllowShortTerm;
  final bool fsrsShortTermWithSteps;
  final FindInterval? loadBalancer;
  final LearningSteps steps;
  final LearningSteps relearnSteps;

  double get initialEase => f32(config.startingEase / 1000);
  double get minimumEase => f32(config.minEase / 1000);
  double get hardMultiplier => f32(config.hardIntervalMultiplier);
  double get easyMultiplier => f32(config.easyBonus);
  double get intervalMultiplier => f32(config.intervalModifier);
  double get lapseMultiplier => f32(config.newIntervalMultiplier);
  int get maximumReviewInterval => config.maximumIntervalDays;

  (int, int) minAndMaxReviewIntervals(int minimum) {
    final maximum = math.max(maximumReviewInterval, 1);
    return (minimum.clamp(1, maximum), maximum);
  }

  int withReviewFuzz(double interval, int minimum, int maximum) =>
      loadBalancer?.call(interval, minimum, maximum) ?? withReviewFuzzPlain(fuzzFactor, interval, minimum, maximum);
}

/// [withReviewFuzz] from fuzz.dart, re-exported under a distinct name to
/// avoid clashing with [StateContext.withReviewFuzz].
int withReviewFuzzPlain(double? factor, double interval, int minimum, int maximum) =>
    withReviewFuzz(factor, interval, minimum, maximum);

class Scheduler {
  const Scheduler();

  SchedulingStates nextStates(CardState current, StateContext ctx) => switch (current) {
        NewState() => () {
            final s = _learnNext(LearnState(remainingSteps: ctx.steps.remainingForFailed(), scheduledSecs: 0), ctx);
            return SchedulingStates(current, s.again, s.hard, s.good, s.easy);
          }(),
        LearnState() => _learnNext(current, ctx),
        ReviewState() => _reviewNext(current, ctx),
        RelearnState() => _relearnNext(current, ctx),
      };

  // --- learning (states/learning.rs) ---------------------------------------

  SchedulingStates _learnNext(LearnState s, StateContext ctx) {
    final fsrs = ctx.fsrsNextStates;

    CardState graduateOrShortTerm(ItemState? item, MemoryState? memory, LearnState Function(int secs) shortTerm) {
      final (minimum, maximum) = ctx.minAndMaxReviewIntervals(1);
      final interval = item?.interval ?? ctx.config.graduatingIntervalDays.toDouble();
      final short = item != null &&
          ctx.fsrsAllowShortTerm &&
          (ctx.fsrsShortTermWithSteps || ctx.steps.isEmpty) &&
          item.interval < 0.5;
      if (short) return shortTerm(truncToU32(f32(interval * 86400)));
      return ReviewState(
        scheduledDays: ctx.withReviewFuzz(math.max(f32(interval).roundToDouble(), 1), minimum, maximum),
        easeFactor: ctx.initialEase,
        memory: memory,
      );
    }

    final againMemory = fsrs?.again.memory;
    final CardState again;
    final againDelay = ctx.steps.againDelaySecsLearn();
    if (againDelay != null) {
      again = LearnState(remainingSteps: ctx.steps.remainingForFailed(), scheduledSecs: againDelay, memory: againMemory);
    } else {
      again = graduateOrShortTerm(fsrs?.again, againMemory,
          (secs) => LearnState(remainingSteps: ctx.steps.remainingForFailed(), scheduledSecs: secs, memory: againMemory));
    }

    final hardMemory = fsrs?.hard.memory;
    final CardState hard;
    final hardDelay = ctx.steps.hardDelaySecs(s.remainingSteps);
    if (hardDelay != null) {
      hard = LearnState(remainingSteps: s.remainingSteps, scheduledSecs: hardDelay, memory: hardMemory);
    } else {
      hard = graduateOrShortTerm(fsrs?.hard, hardMemory,
          (secs) => LearnState(remainingSteps: s.remainingSteps, scheduledSecs: secs, memory: hardMemory));
    }

    final goodMemory = fsrs?.good.memory;
    final CardState good;
    final goodDelay = ctx.steps.goodDelaySecs(s.remainingSteps);
    if (goodDelay != null) {
      good = LearnState(
        remainingSteps: ctx.steps.remainingForGood(s.remainingSteps),
        scheduledSecs: goodDelay,
        memory: goodMemory,
      );
    } else {
      good = graduateOrShortTerm(fsrs?.good, goodMemory,
          (secs) => LearnState(remainingSteps: s.remainingSteps, scheduledSecs: secs, memory: goodMemory));
    }

    var (minimum, maximum) = ctx.minAndMaxReviewIntervals(1);
    final int easyInterval;
    if (fsrs != null) {
      final goodIvl = ctx.withReviewFuzz(fsrs.good.interval, minimum, maximum);
      minimum = goodIvl + 1;
      easyInterval = roundToU32(math.max(f32(fsrs.easy.interval).roundToDouble(), 1));
    } else {
      easyInterval = ctx.config.easyIntervalDays;
    }
    final easy = ReviewState(
      scheduledDays: ctx.withReviewFuzz(easyInterval.toDouble(), minimum, maximum),
      easeFactor: ctx.initialEase,
      memory: fsrs?.easy.memory,
    );

    return SchedulingStates(s, again, hard, good, easy);
  }

  // --- review (states/review.rs) -------------------------------------------

  /// (scheduled days as f32, memory) for a failed review.
  (double, MemoryState?) _failingReviewInterval(ReviewState s, StateContext ctx) {
    final fsrs = ctx.fsrsNextStates;
    if (fsrs != null) return (fsrs.again.interval, fsrs.again.memory);
    final (minimum, maximum) = ctx.minAndMaxReviewIntervals(ctx.config.minimumLapseInterval);
    final interval = ctx.withReviewFuzz(
      f32(math.max(f32(s.scheduledDays.toDouble()), 1.0) * ctx.lapseMultiplier),
      minimum,
      maximum,
    );
    return (interval.toDouble(), null);
  }

  SchedulingStates _reviewNext(ReviewState s, StateContext ctx) {
    final (hardIvl, goodIvl, easyIvl) = passingReviewIntervals(s, ctx);
    final fsrs = ctx.fsrsNextStates;

    // Again
    final lapses = s.lapses + 1;
    final leeched = leechThresholdMet(lapses, ctx.config.leechThreshold);
    final (scheduledDays, memory) = _failingReviewInterval(s, ctx);
    final againReview = ReviewState(
      scheduledDays: roundToU32(math.max(f32(scheduledDays).roundToDouble(), 1)),
      elapsedDays: 0,
      easeFactor: math.max(f32(s.easeFactor - 0.2), ctx.minimumEase),
      lapses: lapses,
      leeched: leeched,
      memory: memory,
    );
    final CardState again;
    final againDelay = ctx.relearnSteps.againDelaySecsLearn();
    if (againDelay != null) {
      again = RelearnState(
        LearnState(remainingSteps: ctx.relearnSteps.remainingForFailed(), scheduledSecs: againDelay, memory: memory),
        againReview,
      );
    } else if (ctx.fsrsAllowShortTerm &&
        (ctx.fsrsShortTermWithSteps || ctx.relearnSteps.isEmpty) &&
        scheduledDays < 0.5) {
      again = RelearnState(
        LearnState(
          remainingSteps: ctx.relearnSteps.remainingForFailed(),
          scheduledSecs: truncToU32(f32(scheduledDays * 86400)),
          memory: memory,
        ),
        againReview,
      );
    } else {
      again = againReview;
    }

    final hard = s.withMemory(
      fsrs?.hard.memory,
      scheduledDays: hardIvl,
      elapsedDays: 0,
      easeFactor: math.max(f32(s.easeFactor - 0.15), ctx.minimumEase),
    );
    final good = s.withMemory(fsrs?.good.memory, scheduledDays: goodIvl, elapsedDays: 0);
    final easy = s.withMemory(
      fsrs?.easy.memory,
      scheduledDays: easyIvl,
      elapsedDays: 0,
      easeFactor: f32(s.easeFactor + 0.15),
    );
    return SchedulingStates(s, again, hard, good, easy);
  }

  static (int, int, int) passingReviewIntervals(ReviewState s, StateContext ctx) {
    final fsrs = ctx.fsrsNextStates;
    if (fsrs != null) return _passingFsrs(s, ctx, fsrs);
    if (s.daysLate < 0) return _passingEarly(s, ctx);
    return _passingNonEarly(s, ctx);
  }

  static int _constrainPassing(StateContext ctx, double interval, int minimum, bool fuzz) {
    final ivl = ctx.fsrsNextStates != null ? interval : f32(interval * ctx.intervalMultiplier);
    final (min, max) = ctx.minAndMaxReviewIntervals(minimum);
    return fuzz ? ctx.withReviewFuzz(ivl, min, max) : roundToU32(ivl).clamp(min, max);
  }

  static (int, int, int) _passingFsrs(ReviewState s, StateContext ctx, NextStates states) {
    final max = ctx.maximumReviewInterval;
    final hard = _constrainPassing(
        ctx, states.hard.interval, math.max(minimumReviewFuzzInterval(states.hard.interval, s.scheduledDays, max), 1), true);
    final good = _constrainPassing(ctx, states.good.interval,
        math.max(minimumReviewFuzzInterval(states.good.interval, s.scheduledDays, max), hard + 1), true);
    final easy = _constrainPassing(ctx, states.easy.interval,
        math.max(minimumReviewFuzzInterval(states.easy.interval, s.scheduledDays, max), good + 1), true);
    return (hard, good, easy);
  }

  static (int, int, int) _passingNonEarly(ReviewState s, StateContext ctx) {
    final current = math.max(f32(s.scheduledDays.toDouble()), 1.0);
    final daysLate = math.max(s.daysLate, 0).toDouble();
    final hardFactor = ctx.hardMultiplier;
    final hardMinimum = hardFactor <= 1 ? 0 : s.scheduledDays + 1;
    final hard = _constrainPassing(ctx, f32(current * hardFactor), hardMinimum, true);
    final goodMinimum = hardFactor <= 1 ? s.scheduledDays + 1 : hard + 1;
    final good = _constrainPassing(ctx, f32(f32(current + f32(daysLate / 2)) * s.easeFactor), goodMinimum, true);
    final easy = _constrainPassing(
        ctx, f32(f32(f32(current + daysLate) * s.easeFactor) * ctx.easyMultiplier), good + 1, true);
    return (hard, good, easy);
  }

  /// Reviewing ahead of schedule (only reachable through filtered decks in
  /// Anki; kept for completeness).
  static (int, int, int) _passingEarly(ReviewState s, StateContext ctx) {
    final scheduled = math.max(f32(s.scheduledDays.toDouble()), 1.0);
    final elapsed = s.elapsedDays.toDouble();
    final factor = ctx.hardMultiplier;
    final halfUsual = f32(factor / 2);
    final hard = _constrainPassing(ctx, math.max(f32(elapsed * factor), f32(scheduled * halfUsual)), 0, false);
    final goodBase = math.max(f32(elapsed * s.easeFactor), scheduled);
    final good = _constrainPassing(ctx, goodBase, 0, false);
    final reducedBonus = f32(ctx.easyMultiplier - f32(f32(ctx.easyMultiplier - 1) / 2));
    final easy = _constrainPassing(ctx, f32(goodBase * reducedBonus), 0, false);
    return (hard, good, easy);
  }

  /// Anki's leech rule: at the threshold, then every half-threshold after
  /// (8, 12, 16... for the default 8).
  static bool leechThresholdMet(int lapses, int threshold) {
    if (threshold <= 0) return false;
    final half = math.max(1, (threshold / 2).ceil());
    return lapses >= threshold && (lapses - threshold) % half == 0;
  }

  // --- relearning (states/relearning.rs) -----------------------------------

  SchedulingStates _relearnNext(RelearnState s, StateContext ctx) {
    final fsrs = ctx.fsrsNextStates;
    final steps = ctx.relearnSteps;

    bool shortTerm(double interval) =>
        ctx.fsrsAllowShortTerm && (ctx.fsrsShortTermWithSteps || steps.isEmpty) && interval < 0.5;

    // Again
    final (againDays, againMemory) = _failingReviewInterval(s.review, ctx);
    final CardState again;
    final againDelay = steps.againDelaySecsLearn();
    if (againDelay != null) {
      again = RelearnState(
        LearnState(remainingSteps: steps.remainingForFailed(), scheduledSecs: againDelay, memory: againMemory),
        s.review.withMemory(
          againMemory,
          scheduledDays: roundToU32(math.max(f32(againDays).roundToDouble(), 1)),
          elapsedDays: 0,
        ),
      );
    } else if (fsrs != null) {
      final (minimum, maximum) = ctx.minAndMaxReviewIntervals(1);
      final interval = fsrs.again.interval;
      final review = s.review.withMemory(
        againMemory,
        scheduledDays: ctx.withReviewFuzz(math.max(f32(interval).roundToDouble(), 1), minimum, maximum),
      );
      again = shortTerm(interval)
          ? RelearnState(
              LearnState(
                remainingSteps: steps.remainingForFailed(),
                scheduledSecs: truncToU32(f32(interval * 86400)),
                memory: againMemory,
              ),
              review)
          : review;
    } else {
      again = s.review;
    }

    CardState passing(ItemState? item, int? delay, LearnState Function(int secs) learn, ReviewState Function() sm2) {
      final memory = item?.memory;
      if (delay != null) {
        return RelearnState(learn(delay), s.review.withMemory(memory, elapsedDays: 0));
      }
      if (fsrs != null) {
        final (minimum, maximum) = ctx.minAndMaxReviewIntervals(1);
        final interval = item!.interval;
        final review = s.review.withMemory(
          memory,
          scheduledDays: ctx.withReviewFuzz(math.max(f32(interval).roundToDouble(), 1), minimum, maximum),
        );
        return shortTerm(interval)
            ? RelearnState(learn(truncToU32(f32(interval * 86400))), review)
            : review;
      }
      return sm2();
    }

    final hard = passing(
      fsrs?.hard,
      steps.hardDelaySecs(s.learning.remainingSteps),
      (secs) => s.learning.withMemory(fsrs?.hard.memory, scheduledSecs: secs),
      () => s.review,
    );
    final good = passing(
      fsrs?.good,
      steps.goodDelaySecs(s.learning.remainingSteps),
      (secs) => LearnState(
        remainingSteps: steps.remainingForGood(s.learning.remainingSteps),
        scheduledSecs: secs,
        elapsedSecs: 0,
        memory: fsrs?.good.memory,
      ),
      () => s.review,
    );

    final int easyDays;
    if (fsrs != null) {
      var (minimum, maximum) = ctx.minAndMaxReviewIntervals(1);
      final goodIvl = ctx.withReviewFuzz(fsrs.good.interval, minimum, maximum);
      minimum = goodIvl + 1;
      easyDays = ctx.withReviewFuzz(math.max(f32(fsrs.easy.interval).roundToDouble(), 1), minimum, maximum);
    } else {
      easyDays = s.review.scheduledDays + 1;
    }
    final easy = s.review.withMemory(fsrs?.easy.memory, scheduledDays: easyDays, elapsedDays: 0);

    return SchedulingStates(s, again, hard, good, easy);
  }
}

// --- reading the current state of a stored card (answering/current.rs) -----

/// Builds Anki's notion of the card's current state from its stored row.
/// [today] is the collection day number, [nowSecs] the current time.
CardState currentCardState({
  required CardSchedState card,
  required DeckSchedConfig config,
  required int today,
  required int nowSecs,
  required int? fuzzSeedForPreviousAnswer,
}) {
  final memory = card.stability != null && card.difficulty != null
      ? MemoryState(f32(card.stability!), f32(card.difficulty!))
      : null;
  final ease = f32(card.ease / 1000);

  int remaining(LearningSteps steps) => math.max(steps.length - card.stepIndex, 0);

  int elapsedSecs(int lastIvl) {
    switch (card.queue) {
      case CardQueue.learning:
      case CardQueue.relearning:
        final lastWithFuzz = learningIvlWithFuzz(fuzzSeedForPreviousAnswer, lastIvl);
        return math.max(nowSecs - (card.due - lastWithFuzz), 0);
      case CardQueue.interdayLearning:
      case CardQueue.interdayRelearning:
        final lastIvlAsDays = math.max(lastIvl ~/ _day, 1);
        return math.max((today - card.due + lastIvlAsDays) * _day, 0);
      default:
        return 0;
    }
  }

  switch (card.queue) {
    case CardQueue.newCard:
      return NewState(math.max(card.due, 0));
    case CardQueue.learning:
    case CardQueue.interdayLearning:
      final steps = LearningSteps(config.learningStepsMin);
      final rem = remaining(steps);
      final last = steps.currentDelaySecs(rem);
      return LearnState(remainingSteps: rem, scheduledSecs: last, elapsedSecs: elapsedSecs(last), memory: memory);
    case CardQueue.relearning:
    case CardQueue.interdayRelearning:
      final steps = LearningSteps(config.relearningStepsMin);
      final rem = remaining(steps);
      final last = steps.currentDelaySecs(rem);
      return RelearnState(
        LearnState(remainingSteps: rem, scheduledSecs: last, elapsedSecs: elapsedSecs(last), memory: memory),
        ReviewState(scheduledDays: card.ivl, elapsedDays: card.ivl, easeFactor: ease, lapses: card.lapses, memory: memory),
      );
    case CardQueue.review:
    case CardQueue.suspended:
      return ReviewState(
        scheduledDays: card.ivl,
        elapsedDays: math.max(card.ivl - (card.due - today), 0),
        easeFactor: ease,
        lapses: card.lapses,
        memory: memory,
      );
  }
}

// --- writing the answer back (answering/{learning,review,relearning,revlog}.rs)

/// An interval as Anki tracks it: seconds for intraday steps, days
/// otherwise (`IntervalKind`).
sealed class IntervalKind {
  const IntervalKind();

  /// `maybe_as_days`: a learning delay reaching past the next day boundary
  /// becomes a day count.
  IntervalKind maybeAsDays(int secsUntilRollover) => switch (this) {
        InSecs(:final secs) when secs >= secsUntilRollover => InDays((secs - secsUntilRollover) ~/ _day + 1),
        final other => other,
      };

  /// Revlog convention: positive days, negative seconds.
  int get asRevlogInterval => switch (this) {
        InDays(:final days) => days,
        InSecs(:final secs) => -secs,
      };
}

class InSecs extends IntervalKind {
  const InSecs(this.secs);
  final int secs;
}

class InDays extends IntervalKind {
  const InDays(this.days);
  final int days;
}

IntervalKind intervalKindOf(CardState s) => switch (s) {
      NewState() => const InSecs(0),
      LearnState(:final scheduledSecs) => InSecs(scheduledSecs),
      ReviewState(:final scheduledDays) => InDays(scheduledDays),
      RelearnState(:final learning) => InSecs(learning.scheduledSecs),
    };

/// Anki's `RevlogReviewKind`.
abstract final class RevlogKind {
  static const learning = 0;
  static const review = 1;
  static const relearning = 2;
  static const filtered = 3;
  static const manual = 4;
  static const rescheduled = 5;
}

int revlogKindOf(CardState current) => switch (current) {
      NewState() || LearnState() => RevlogKind.learning,
      ReviewState(:final daysLate) => daysLate < 0 ? RevlogKind.filtered : RevlogKind.review,
      RelearnState() => RevlogKind.relearning,
    };

/// The stored result of an answer: new card fields and the revlog entry.
class AppliedAnswer {
  const AppliedAnswer({
    required this.card,
    required this.revlogKind,
    required this.revlogInterval,
    required this.revlogLastInterval,
    required this.revlogEaseFactor,
    required this.leeched,
  });
  final CardSchedState card;
  final int revlogKind;
  final int revlogInterval;
  final int revlogLastInterval;
  final int revlogEaseFactor;
  final bool leeched;
}

AppliedAnswer applyAnswer({
  required CardSchedState card,
  required CardState current,
  required CardState next,
  required DeckSchedConfig config,
  required int today,
  required int nowSecs,
  required int secsUntilRollover,
  required int? fuzzSeed,
}) {
  double difficultyShifted(MemoryState m) => f32(f32(f32(m.difficulty - 1) / 9) + f32(0.1));
  int easeForRevlog(double v) => roundToU32(f32(v * 1000));

  int stepIndexFor(LearningSteps steps, int remaining) => math.max(steps.length - remaining, 0);

  late CardSchedState out;
  late double revlogEase;
  var leeched = false;

  switch (next) {
    case LearnState():
      final kind = InSecs(next.scheduledSecs).maybeAsDays(secsUntilRollover);
      final (queue, due) = switch (kind) {
        InSecs(:final secs) => (CardQueue.learning, nowSecs + learningIvlWithFuzz(fuzzSeed, secs)),
        InDays(:final days) => (CardQueue.interdayLearning, today + days),
      };
      out = CardSchedState(
        queue: queue,
        due: due,
        ivl: card.ivl,
        ease: card.ease,
        reps: card.reps + 1,
        lapses: card.lapses,
        stepIndex: stepIndexFor(LearningSteps(config.learningStepsMin), next.remainingSteps),
        stability: next.memory?.stability,
        difficulty: next.memory?.difficulty,
      );
      revlogEase = next.memory == null ? 0 : difficultyShifted(next.memory!);
    case RelearnState(:final learning, :final review):
      final kind = InSecs(learning.scheduledSecs).maybeAsDays(secsUntilRollover);
      final (queue, due) = switch (kind) {
        InSecs(:final secs) => (CardQueue.relearning, nowSecs + learningIvlWithFuzz(fuzzSeed, secs)),
        InDays(:final days) => (CardQueue.interdayRelearning, today + days),
      };
      out = CardSchedState(
        queue: queue,
        due: due,
        ivl: review.scheduledDays,
        ease: roundToU32(f32(review.easeFactor * 1000)),
        reps: card.reps + 1,
        lapses: review.lapses,
        stepIndex: stepIndexFor(LearningSteps(config.relearningStepsMin), learning.remainingSteps),
        stability: learning.memory?.stability,
        difficulty: learning.memory?.difficulty,
      );
      revlogEase = learning.memory == null ? review.easeFactor : difficultyShifted(learning.memory!);
      leeched = review.leeched;
    case ReviewState():
      out = CardSchedState(
        queue: CardQueue.review,
        due: today + next.scheduledDays,
        ivl: next.scheduledDays,
        ease: roundToU32(f32(next.easeFactor * 1000)),
        reps: card.reps + 1,
        lapses: next.lapses,
        stepIndex: 0,
        stability: next.memory?.stability,
        difficulty: next.memory?.difficulty,
      );
      revlogEase = next.memory == null ? next.easeFactor : difficultyShifted(next.memory!);
      leeched = next.leeched;
    case NewState():
      throw StateError('an answer never makes a card new');
  }

  return AppliedAnswer(
    card: out,
    revlogKind: revlogKindOf(current),
    revlogInterval: intervalKindOf(next).maybeAsDays(secsUntilRollover).asRevlogInterval,
    revlogLastInterval: intervalKindOf(current).maybeAsDays(secsUntilRollover).asRevlogInterval,
    revlogEaseFactor: easeForRevlog(revlogEase),
    leeched: leeched,
  );
}
