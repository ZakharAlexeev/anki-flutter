import 'package:anki_flutter/domain/scheduler/day_calendar.dart';
import 'package:anki_flutter/domain/scheduler/models.dart';
import 'package:anki_flutter/domain/scheduler/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const scheduler = Scheduler();
  const config = DeckSchedConfig();
  final now = DateTime.utc(2026, 1, 10, 12);
  const today = 500;

  CardSchedState established({int lapses = 0}) => CardSchedState(
        queue: CardQueue.review,
        due: today,
        ivl: 10,
        ease: 2500,
        reps: 5,
        lapses: lapses,
        stability: 10,
        difficulty: 5,
        lastReviewedAt: now.subtract(const Duration(days: 10)).millisecondsSinceEpoch ~/ 1000,
      );

  group('FSRS-6 learning', () {
    test('Again starts the first learning step and creates memory state', () {
      final out = scheduler.answerCard(
        card: CardSchedState.newCard(due: 0, startingEase: config.startingEase),
        config: config,
        rating: Rating.again,
        now: now,
        today: today,
      );
      expect(out.state.queue, CardQueue.learning);
      expect(out.state.stepIndex, 0);
      expect(out.state.due, now.add(const Duration(minutes: 1)).millisecondsSinceEpoch ~/ 1000);
      expect(out.state.stability, isNotNull);
      expect(out.state.difficulty, isNotNull);
    });

    test('Good advances through the configured learning steps', () {
      final first = scheduler.answerCard(
        card: CardSchedState.newCard(due: 0, startingEase: config.startingEase),
        config: config,
        rating: Rating.good,
        now: now,
        today: today,
      ).state;
      expect(first.queue, CardQueue.learning);
      expect(first.stepIndex, 1);
      expect(first.due, now.add(const Duration(minutes: 10)).millisecondsSinceEpoch ~/ 1000);

      final graduated = scheduler.answerCard(
        card: first,
        config: config,
        rating: Rating.good,
        now: now.add(const Duration(minutes: 10)),
        today: today,
      ).state;
      expect(graduated.queue, CardQueue.review);
      expect(graduated.ivl, greaterThanOrEqualTo(1));
      expect(graduated.due, today + graduated.ivl);
    });

    test('Easy graduates immediately', () {
      final out = scheduler.answerCard(
        card: CardSchedState.newCard(due: 0, startingEase: config.startingEase),
        config: config,
        rating: Rating.easy,
        now: now,
        today: today,
      );
      expect(out.state.queue, CardQueue.review);
      expect(out.state.ivl, greaterThanOrEqualTo(1));
      expect(out.state.stability, isNotNull);
      expect(out.state.difficulty, isNotNull);
    });

    test('Hard uses Anki learning-step midpoint', () {
      final out = scheduler.answerCard(
        card: CardSchedState.newCard(due: 0, startingEase: config.startingEase),
        config: config,
        rating: Rating.hard,
        now: now,
        today: today,
      );
      final delay = out.state.due - now.millisecondsSinceEpoch ~/ 1000;
      // FSRS keeps Anki's midpoint semantics while rounding the step to its
      // scheduler granularity (the default 1/10 minute steps yield 5–6 min).
      expect(delay, inInclusiveRange(5 * 60, 6 * 60));
    });
  });

  group('FSRS-6 review scheduling', () {
    test('all passing ratings update memory state and produce a review interval', () {
      final outcomes = scheduler.previewOutcomes(card: established(), config: config, now: now, today: today);
      for (final rating in [Rating.hard, Rating.good, Rating.easy]) {
        final state = outcomes[rating]!;
        expect(state.queue, CardQueue.review);
        expect(state.ivl, inInclusiveRange(1, config.maximumIntervalDays));
        expect(state.due, today + state.ivl);
        expect(state.stability, isNotNull);
        expect(state.difficulty, inInclusiveRange(1, 10));
      }
      expect(outcomes[Rating.easy]!.ivl, greaterThanOrEqualTo(outcomes[Rating.hard]!.ivl));
    });

    test('higher desired retention never schedules later', () {
      const highRetention = DeckSchedConfig(desiredRetention: 0.95);
      const lowRetention = DeckSchedConfig(desiredRetention: 0.80);
      final high = scheduler.previewOutcomes(
        card: established(),
        config: highRetention,
        now: now,
        today: today,
      )[Rating.good]!;
      final low = scheduler.previewOutcomes(
        card: established(),
        config: lowRetention,
        now: now,
        today: today,
      )[Rating.good]!;
      expect(high.ivl, lessThanOrEqualTo(low.ivl));
    });

    test('Again enters relearning and increments lapses', () {
      final out = scheduler.answerCard(
        card: established(),
        config: config,
        rating: Rating.again,
        now: now,
        today: today,
      );
      expect(out.state.queue, CardQueue.relearning);
      expect(out.state.lapses, 1);
      expect(out.state.due, now.add(const Duration(minutes: 10)).millisecondsSinceEpoch ~/ 1000);
    });

    test('reaching the leech threshold suspends the card', () {
      final out = scheduler.answerCard(
        card: established(lapses: 7),
        config: config,
        rating: Rating.again,
        now: now,
        today: today,
      );
      expect(out.state.lapses, 8);
      expect(out.becameLeech, isTrue);
      expect(out.state.queue, CardQueue.suspended);
    });

    test('answering a suspended card throws', () {
      final card = CardSchedState(queue: CardQueue.suspended, due: today, ivl: 5, ease: 2500);
      expect(
        () => scheduler.answerCard(card: card, config: config, rating: Rating.good, now: now, today: today),
        throwsStateError,
      );
    });
  });

  group('day rollover', () {
    final created = DateTime(2026, 1, 1, 12);

    test('stays on the same collection day right up to rollover', () {
      expect(dayNumber(DateTime(2026, 1, 2, 3, 59), created, rolloverHour: 4), 0);
    });

    test('advances at the rollover hour', () {
      expect(dayNumber(DateTime(2026, 1, 2, 4), created, rolloverHour: 4), 1);
    });
  });
}
