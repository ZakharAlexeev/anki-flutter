import 'dart:math';

import 'package:anki_flutter/domain/scheduler/day_calendar.dart';
import 'package:anki_flutter/domain/scheduler/fuzz.dart';
import 'package:anki_flutter/domain/scheduler/models.dart';
import 'package:anki_flutter/domain/scheduler/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const scheduler = Scheduler();
  const config = DeckSchedConfig(); // defaults: steps [1,10]/[10], grad 1d, easy 4d, ease 2500
  final now = DateTime(2026, 1, 10, 12, 0, 0);
  const today = 500;

  group('new card -> learning steps', () {
    test('Again resets to first step', () {
      final card = CardSchedState.newCard(due: 0, startingEase: config.startingEase);
      final out = scheduler.answerCard(
        card: card,
        config: config,
        rating: Rating.again,
        now: now,
        today: today,
      );
      expect(out.state.queue, CardQueue.learning);
      expect(out.state.stepIndex, 0);
      expect(out.state.due, now.add(const Duration(minutes: 1)).millisecondsSinceEpoch ~/ 1000);
    });

    test('Good advances to next step without graduating', () {
      final card = CardSchedState.newCard(due: 0, startingEase: config.startingEase);
      final out = scheduler.answerCard(
        card: card,
        config: config,
        rating: Rating.good,
        now: now,
        today: today,
      );
      expect(out.state.queue, CardQueue.learning);
      expect(out.state.stepIndex, 1);
      expect(out.state.due, now.add(const Duration(minutes: 10)).millisecondsSinceEpoch ~/ 1000);
    });

    test('Good on the last step graduates into review with graduating interval', () {
      final card = CardSchedState.newCard(due: 0, startingEase: config.startingEase).copyWith(
        queue: CardQueue.learning,
        stepIndex: 1, // already past the [1,10] steps
      );
      final out = scheduler.answerCard(
        card: card,
        config: config,
        rating: Rating.good,
        now: now,
        today: today,
      );
      expect(out.state.queue, CardQueue.review);
      expect(out.state.ivl, config.graduatingIntervalDays);
      expect(out.state.due, today + config.graduatingIntervalDays);
    });

    test('Easy graduates immediately regardless of step, using the easy interval', () {
      final card = CardSchedState.newCard(due: 0, startingEase: config.startingEase);
      final out = scheduler.answerCard(
        card: card,
        config: config,
        rating: Rating.easy,
        now: now,
        today: today,
      );
      expect(out.state.queue, CardQueue.review);
      expect(out.state.ivl, config.easyIntervalDays);
      expect(out.state.due, today + config.easyIntervalDays);
      expect(out.state.ease, config.startingEase);
    });

    test('Hard delay is the average of the current and next step', () {
      final card = CardSchedState.newCard(due: 0, startingEase: config.startingEase).copyWith(
        queue: CardQueue.learning,
        stepIndex: 0,
      );
      final out = scheduler.answerCard(
        card: card,
        config: config,
        rating: Rating.hard,
        now: now,
        today: today,
      );
      // steps [1, 10] -> (1 + 10) / 2 = 5.5 -> rounds to 6 minutes.
      expect(out.state.due, now.add(const Duration(minutes: 6)).millisecondsSinceEpoch ~/ 1000);
    });

    test('Hard delay on the last step is 1.5x the current step', () {
      final card = CardSchedState.newCard(due: 0, startingEase: config.startingEase).copyWith(
        queue: CardQueue.learning,
        stepIndex: 1, // last of [1, 10]
      );
      final out = scheduler.answerCard(
        card: card,
        config: config,
        rating: Rating.hard,
        now: now,
        today: today,
      );
      // (10 + 15) / 2 = 12.5 -> rounds to 13 minutes.
      expect(out.state.due, now.add(const Duration(minutes: 13)).millisecondsSinceEpoch ~/ 1000);
    });
  });

  group('review card SM-2 formulas (deterministic, no fuzz)', () {
    test('Good: ivl *= ease, ease unchanged', () {
      final card = CardSchedState(queue: CardQueue.review, due: today, ivl: 10, ease: 2500);
      final out = scheduler.answerCard(
        card: card,
        config: config,
        rating: Rating.good,
        now: now,
        today: today,
      );
      expect(out.state.ivl, 25); // 10 * 2.5
      expect(out.state.ease, 2500);
      expect(out.state.due, today + 25);
    });

    test('Hard: ivl *= hardIntervalMultiplier, ease -= 150', () {
      final card = CardSchedState(queue: CardQueue.review, due: today, ivl: 10, ease: 2500);
      final out = scheduler.answerCard(
        card: card,
        config: config,
        rating: Rating.hard,
        now: now,
        today: today,
      );
      expect(out.state.ivl, 12); // 10 * 1.2
      expect(out.state.ease, 2350);
    });

    test('Easy: ivl *= ease * easyBonus, ease += 150', () {
      final card = CardSchedState(queue: CardQueue.review, due: today, ivl: 10, ease: 2500);
      final out = scheduler.answerCard(
        card: card,
        config: config,
        rating: Rating.easy,
        now: now,
        today: today,
      );
      expect(out.state.ivl, 33); // round(10 * 2.5 * 1.3) = round(32.5) = 33
      expect(out.state.ease, 2650);
    });

    test('Good/Easy intervals always grow by at least one day over the previous interval', () {
      // A low ease (near the floor) combined with a short interval could
      // otherwise fail to grow at all.
      final card = CardSchedState(queue: CardQueue.review, due: today, ivl: 1, ease: 1300);
      final out = scheduler.answerCard(
        card: card,
        config: config,
        rating: Rating.good,
        now: now,
        today: today,
      );
      expect(out.state.ivl, greaterThanOrEqualTo(2));
    });

    test('Again: lapse penalty, ease -= 200 (floored), enters relearning with lapse interval', () {
      final card = CardSchedState(queue: CardQueue.review, due: today, ivl: 30, ease: 1300, lapses: 0);
      final out = scheduler.answerCard(
        card: card,
        config: config,
        rating: Rating.again,
        now: now,
        today: today,
      );
      expect(out.state.queue, CardQueue.relearning);
      expect(out.state.ease, 1300); // already at floor, can't go lower
      expect(out.state.lapses, 1);
      expect(out.state.ivl, 1); // round(30 * newIntervalMultiplier(0.0)) floored to 1
      expect(out.state.due, now.add(const Duration(minutes: 10)).millisecondsSinceEpoch ~/ 1000);
    });

    test('Relearning graduates back to review using the precomputed lapse interval', () {
      final lapsed = CardSchedState(
        queue: CardQueue.relearning,
        due: 0,
        ivl: 1,
        ease: 1300,
        lapses: 1,
        stepIndex: 0,
      );
      final out = scheduler.answerCard(
        card: lapsed,
        config: config,
        rating: Rating.good,
        now: now,
        today: today,
      );
      expect(out.state.queue, CardQueue.review);
      expect(out.state.ivl, 1);
      expect(out.state.due, today + 1);
    });

    test('Reaching the leech threshold suspends the card', () {
      final card = CardSchedState(queue: CardQueue.review, due: today, ivl: 5, ease: 1300, lapses: 7);
      final out = scheduler.answerCard(
        card: card,
        config: config,
        rating: Rating.again,
        now: now,
        today: today,
      );
      expect(out.state.lapses, 8);
      expect(out.becameLeech, isTrue);
      expect(out.state.queue, CardQueue.suspended);
    });

    test('Answering a suspended card throws', () {
      final card = CardSchedState(queue: CardQueue.suspended, due: today, ivl: 5, ease: 1300);
      expect(
        () => scheduler.answerCard(card: card, config: config, rating: Rating.good, now: now, today: today),
        throwsStateError,
      );
    });
  });

  group('fuzz', () {
    test('no randomness => deterministic clamped value', () {
      expect(fuzzedInterval(1, minIvl: 1, maxIvl: 36500), 1);
      expect(fuzzedInterval(25, minIvl: 11, maxIvl: 36500), 25);
      expect(fuzzedInterval(0, minIvl: 5, maxIvl: 36500), 5); // clamps up to minIvl
      expect(fuzzedInterval(999999, minIvl: 1, maxIvl: 36500), 36500); // clamps down to max
    });

    test('with randomness, result stays within the documented spread and bounds', () {
      final random = Random(42);
      for (var i = 0; i < 200; i++) {
        final result = fuzzedInterval(25, minIvl: 11, maxIvl: 36500, random: random);
        expect(result, inInclusiveRange(11, 36500));
      }
    });
  });

  group('day rollover', () {
    // Collection created at noon so the creation instant itself isn't on a
    // rollover boundary - keeps the two cases below unambiguous.
    final created = DateTime(2026, 1, 1, 12, 0);

    test('stays on the same collection day right up to the rollover hour', () {
      final justBeforeRollover = DateTime(2026, 1, 2, 3, 59);
      expect(dayNumber(justBeforeRollover, created, rolloverHour: 4), 0);
    });

    test('advances to the next collection day at the rollover hour', () {
      final atRollover = DateTime(2026, 1, 2, 4, 0);
      expect(dayNumber(atRollover, created, rolloverHour: 4), 1);
    });
  });
}
