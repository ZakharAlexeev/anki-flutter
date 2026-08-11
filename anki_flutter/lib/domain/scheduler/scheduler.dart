import 'dart:math';

import 'fuzz.dart';
import 'models.dart';

/// Pure implementation of Anki's classic (SM-2 derived) scheduler: new cards
/// walk through [DeckSchedConfig.learningStepsMin], graduate into the review
/// queue, and from then on each answer scales [CardSchedState.ivl] by the
/// card's ease factor (with Hard/Easy adjustments and a lapse penalty on
/// Again). See `scheduler_draft.md` in the project notes for the formulas
/// this was transcribed from.
class Scheduler {
  const Scheduler();

  /// Applies [rating] to [card] and returns its new state. [now] drives
  /// learning/relearning due-times (seconds precision), [today] is the
  /// collection day-number (see `day_calendar.dart`) used for review due
  /// dates. Pass a [random] to fuzz the resulting review interval; omit it
  /// (e.g. for previews) to get the deterministic, unfuzzed value.
  AnswerOutcome answerCard({
    required CardSchedState card,
    required DeckSchedConfig config,
    required Rating rating,
    required DateTime now,
    required int today,
    Random? random,
  }) {
    switch (card.queue) {
      case CardQueue.suspended:
        throw StateError('Cannot answer a suspended card.');
      case CardQueue.newCard:
        return _answerLearning(
          card: card.copyWith(queue: CardQueue.learning),
          steps: config.learningStepsMin,
          config: config,
          rating: rating,
          now: now,
          today: today,
          isRelearning: false,
        );
      case CardQueue.learning:
        return _answerLearning(
          card: card,
          steps: config.learningStepsMin,
          config: config,
          rating: rating,
          now: now,
          today: today,
          isRelearning: false,
        );
      case CardQueue.relearning:
        return _answerLearning(
          card: card,
          steps: config.relearningStepsMin,
          config: config,
          rating: rating,
          now: now,
          today: today,
          isRelearning: true,
        );
      case CardQueue.review:
        return _answerReview(
          card: card,
          config: config,
          rating: rating,
          now: now,
          today: today,
          random: random,
        );
    }
  }

  /// Convenience for the study UI: the interval label each of the four
  /// buttons would produce if pressed right now, without mutating anything.
  Map<Rating, CardSchedState> previewOutcomes({
    required CardSchedState card,
    required DeckSchedConfig config,
    required DateTime now,
    required int today,
  }) {
    return {
      for (final rating in Rating.values)
        rating: answerCard(
          card: card,
          config: config,
          rating: rating,
          now: now,
          today: today,
        ).state,
    };
  }

  AnswerOutcome _answerLearning({
    required CardSchedState card,
    required List<int> steps,
    required DeckSchedConfig config,
    required Rating rating,
    required DateTime now,
    required int today,
    required bool isRelearning,
  }) {
    final queue = isRelearning ? CardQueue.relearning : CardQueue.learning;

    if (steps.isEmpty) {
      // A deck configured with no learning steps graduates on first answer.
      return AnswerOutcome(_graduate(
        card: card,
        config: config,
        rating: rating,
        today: today,
        isRelearning: isRelearning,
      ));
    }

    switch (rating) {
      case Rating.again:
        return AnswerOutcome(card.copyWith(
          queue: queue,
          stepIndex: 0,
          due: _secondsFrom(now, steps.first),
          reps: card.reps + 1,
        ));
      case Rating.hard:
        final delayMin = _hardStepDelayMin(steps, card.stepIndex);
        return AnswerOutcome(card.copyWith(
          queue: queue,
          due: _secondsFrom(now, delayMin),
          reps: card.reps + 1,
        ));
      case Rating.good:
        final nextStep = card.stepIndex + 1;
        if (nextStep < steps.length) {
          return AnswerOutcome(card.copyWith(
            queue: queue,
            stepIndex: nextStep,
            due: _secondsFrom(now, steps[nextStep]),
            reps: card.reps + 1,
          ));
        }
        return AnswerOutcome(_graduate(
          card: card.copyWith(reps: card.reps + 1),
          config: config,
          rating: rating,
          today: today,
          isRelearning: isRelearning,
        ));
      case Rating.easy:
        return AnswerOutcome(_graduate(
          card: card.copyWith(reps: card.reps + 1),
          config: config,
          rating: rating,
          today: today,
          isRelearning: isRelearning,
        ));
    }
  }

  /// Delay (in minutes) before the card resurfaces after a Hard answer
  /// during learning/relearning: the average of the current and next step,
  /// or 1.5x the current step if it's the last one (matches Anki).
  int _hardStepDelayMin(List<int> steps, int stepIndex) {
    final current = steps[min(stepIndex, steps.length - 1)];
    final hasNext = stepIndex + 1 < steps.length;
    final next = hasNext ? steps[stepIndex + 1] : (current * 1.5).round();
    return ((current + next) / 2).round();
  }

  CardSchedState _graduate({
    required CardSchedState card,
    required DeckSchedConfig config,
    required Rating rating,
    required int today,
    required bool isRelearning,
  }) {
    if (isRelearning) {
      // Relearning graduates back to the interval that was already computed
      // when the card lapsed (see _answerReview) - Easy does not re-grant a
      // bonus here, it just skips the remaining steps.
      return card.copyWith(queue: CardQueue.review, due: today + card.ivl);
    }

    final ivl = rating == Rating.easy ? config.easyIntervalDays : config.graduatingIntervalDays;
    return card.copyWith(queue: CardQueue.review, ivl: ivl, due: today + ivl);
  }

  AnswerOutcome _answerReview({
    required CardSchedState card,
    required DeckSchedConfig config,
    required Rating rating,
    required DateTime now,
    required int today,
    Random? random,
  }) {
    final prevIvl = max(1, card.ivl);

    if (rating == Rating.again) {
      final lapses = card.lapses + 1;
      final newEase = max(config.minEase, card.ease - 200);
      final becameLeech = config.leechThreshold > 0 && lapses % config.leechThreshold == 0;
      final lapseIvl = max(1, (prevIvl * config.newIntervalMultiplier).round());

      CardSchedState next;
      if (config.relearningStepsMin.isNotEmpty) {
        next = card.copyWith(
          queue: CardQueue.relearning,
          ivl: lapseIvl,
          ease: newEase,
          lapses: lapses,
          stepIndex: 0,
          due: _secondsFrom(now, config.relearningStepsMin.first),
          reps: card.reps + 1,
        );
      } else {
        next = card.copyWith(
          queue: CardQueue.review,
          ivl: lapseIvl,
          ease: newEase,
          lapses: lapses,
          due: today + lapseIvl,
          reps: card.reps + 1,
        );
      }
      if (becameLeech) {
        next = next.copyWith(queue: CardQueue.suspended);
      }
      return AnswerOutcome(next, becameLeech: becameLeech);
    }

    late final int rawIvl;
    late final int newEase;
    late final bool enforceGrowth;
    switch (rating) {
      case Rating.hard:
        newEase = max(config.minEase, card.ease - 150);
        rawIvl = (prevIvl * config.hardIntervalMultiplier).round();
        enforceGrowth = false;
        break;
      case Rating.good:
        newEase = card.ease;
        rawIvl = (prevIvl * (card.ease / 1000)).round();
        enforceGrowth = true;
        break;
      case Rating.easy:
        newEase = card.ease + 150;
        rawIvl = (prevIvl * (card.ease / 1000) * config.easyBonus).round();
        enforceGrowth = true;
        break;
      case Rating.again:
        throw StateError('unreachable');
    }

    final modified = (rawIvl * config.intervalModifier).round();
    final minAllowed = enforceGrowth ? prevIvl + 1 : 1;
    final fuzzed = fuzzedInterval(
      max(minAllowed, modified),
      minIvl: minAllowed,
      maxIvl: config.maximumIntervalDays,
      random: random,
    );

    final next = card.copyWith(
      queue: CardQueue.review,
      ivl: fuzzed,
      ease: newEase,
      due: today + fuzzed,
      reps: card.reps + 1,
    );
    return AnswerOutcome(next);
  }

  int _secondsFrom(DateTime now, int minutes) =>
      now.add(Duration(minutes: minutes)).millisecondsSinceEpoch ~/ 1000;
}
