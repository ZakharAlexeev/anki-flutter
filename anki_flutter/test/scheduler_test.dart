import 'package:anki_flutter/domain/scheduler/day_calendar.dart';
import 'package:anki_flutter/domain/scheduler/f32.dart';
import 'package:anki_flutter/domain/scheduler/fsrs.dart';
import 'package:anki_flutter/domain/scheduler/fuzz.dart';
import 'package:anki_flutter/domain/scheduler/load_balancer.dart';
import 'package:anki_flutter/domain/scheduler/memory_state.dart';
import 'package:anki_flutter/domain/scheduler/models.dart';
import 'package:anki_flutter/domain/scheduler/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

/// The card state machine, checked against Anki 26.09's rules
/// (rslib scheduler/states). Fuzz is off (factor null) unless a test is
/// about fuzz, as in Anki's own tests.
void main() {
  const scheduler = Scheduler();
  const config = DeckSchedConfig(); // Anki defaults: steps 1m 10m / 10m, 1d / 4d, 250%
  const today = 500;

  StateContext ctx({DeckSchedConfig cfg = config, NextStates? fsrs, bool shortTerm = false, double? fuzz}) =>
      StateContext(config: cfg, fuzzFactor: fuzz, fsrsNextStates: fsrs, fsrsAllowShortTerm: shortTerm);

  ReviewState review({int ivl = 10, double ease = 2.5, int daysLate = 0, int lapses = 0, MemoryState? memory}) =>
      ReviewState(scheduledDays: ivl, elapsedDays: ivl + daysLate, easeFactor: f32(ease), lapses: lapses, memory: memory);

  int days(CardState s) => (s as ReviewState).scheduledDays;
  int secs(CardState s) => switch (s) {
        LearnState(:final scheduledSecs) => scheduledSecs,
        RelearnState(:final learning) => learning.scheduledSecs,
        _ => throw StateError('not a learning state: $s'),
      };

  group('SM-2: new card and learning steps', () {
    final s = scheduler.nextStates(const NewState(0), ctx());

    test('Again -> first step (1 min), Good -> second step (10 min)', () {
      expect(secs(s.again), 60);
      expect((s.again as LearnState).remainingSteps, 2);
      expect(secs(s.good), 600);
      expect((s.good as LearnState).remainingSteps, 1);
    });

    test('Hard on the first step: halfway to the second (5.5 min)', () {
      expect(secs(s.hard), 330);
    });

    test('Easy graduates with the easy interval (4 days)', () {
      expect(days(s.easy), 4);
      expect((s.easy as ReviewState).easeFactor, f32(2.5));
    });

    test('Good on the last step graduates with the graduating interval (1 day)', () {
      final last = scheduler.nextStates(const LearnState(remainingSteps: 1, scheduledSecs: 600), ctx());
      expect(days(last.good), 1);
      expect(secs(last.hard), 600, reason: 'Hard on a later step repeats it');
    });

    test('one step: Hard is 1.5x it, at most a day longer, rounded to days past a day', () {
      expect(LearningSteps([10]).hardDelaySecs(1), 900);
      expect(LearningSteps([2880]).hardDelaySecs(1), 3 * 86400); // 2d step -> 3d
      expect(LearningSteps([1440, 2880]).hardDelaySecs(2), 2 * 86400); // (1d+2d)/2 = 1.5d -> 2d
    });
  });

  group('SM-2: reviews (Anki v3 formulas)', () {
    test('on time: Hard = ivl * 1.2, Good = ivl * ease, Easy = ivl * ease * 1.3', () {
      final s = scheduler.nextStates(review(), ctx());
      expect([days(s.hard), days(s.good), days(s.easy)], [12, 25, 33]);
    });

    test('ease: Hard -15%, Good unchanged, Easy +15%, Again -20% (floor 130%)', () {
      final s = scheduler.nextStates(review(), ctx());
      expect((s.hard as ReviewState).easeFactor, f32(2.35));
      expect((s.good as ReviewState).easeFactor, f32(2.5));
      expect((s.easy as ReviewState).easeFactor, f32(2.65));
      expect((s.again as RelearnState).review.easeFactor, f32(2.3));
      final low = scheduler.nextStates(review(ease: 1.3), ctx());
      expect((low.again as RelearnState).review.easeFactor, f32(1.3));
    });

    test('a late review is credited: Good half the days late, Easy all', () {
      final s = scheduler.nextStates(review(daysLate: 10), ctx());
      expect([days(s.hard), days(s.good), days(s.easy)], [12, 38, 65]);
    });

    test('each button beats the previous one; Hard always grows by a day', () {
      for (final ivl in [1, 2, 3, 5, 8]) {
        final s = scheduler.nextStates(review(ivl: ivl, ease: 1.3), ctx());
        expect(days(s.hard), greaterThanOrEqualTo(ivl + 1));
        expect(days(s.good), greaterThan(days(s.hard)));
        expect(days(s.easy), greaterThan(days(s.good)));
      }
    });

    test('Again: relearning step (10 min) with lapse interval 1 day and one more lapse', () {
      final s = scheduler.nextStates(review(ivl: 30), ctx());
      final again = s.again as RelearnState;
      expect(again.learning.scheduledSecs, 600);
      expect(again.review.scheduledDays, 1);
      expect(again.review.lapses, 1);
    });

    test('relearning: Good graduates to the lapse interval, Easy to one day more', () {
      final relearn = RelearnState(
        const LearnState(remainingSteps: 1, scheduledSecs: 600),
        review(ivl: 3, ease: 2.3, lapses: 1),
      );
      final s = scheduler.nextStates(relearn, ctx());
      expect(days(s.good), 3);
      expect(days(s.easy), 4);
    });

    test('minimum lapse interval and interval modifier apply', () {
      const cfg = DeckSchedConfig(minimumLapseInterval: 3, intervalModifier: 0.8);
      final s = scheduler.nextStates(review(), ctx(cfg: cfg));
      expect((s.again as RelearnState).review.scheduledDays, 3);
      expect(days(s.good), 20); // 25 * 0.8
    });
  });

  group('leeches', () {
    test('at the threshold, then every half-threshold', () {
      expect([for (var l = 1; l <= 20; l++) if (Scheduler.leechThresholdMet(l, 8)) l], [8, 12, 16, 20]);
    });

    test('the 8th lapse marks a leech', () {
      final s = scheduler.nextStates(review(lapses: 7), ctx());
      expect((s.again as RelearnState).review.leeched, isTrue);
    });
  });

  group('FSRS', () {
    final fsrs = Fsrs.defaults();

    test('new card with learning steps: steps as usual, memory from FSRS', () {
      final s = scheduler.nextStates(const NewState(0), ctx(fsrs: fsrs.nextStates(null, 0.9, 0), shortTerm: true));
      expect(secs(s.again), 60);
      expect((s.again as LearnState).memory, MemoryState(f32(0.212), f32(6.4133)));
      expect(secs(s.good), 600);
      expect((s.good as LearnState).memory!.stability, f32(2.3065));
      // Easy: FSRS easy interval (8.2956 -> 8 days).
      expect(days(s.easy), 8);
    });

    test('new card without steps: Again stays the same day (short-term), Good graduates', () {
      const cfg = DeckSchedConfig(learningStepsMin: []);
      final s = scheduler.nextStates(const NewState(0), ctx(cfg: cfg, fsrs: fsrs.nextStates(null, 0.9, 0), shortTerm: true));
      expect(secs(s.again), truncToU32(f32(f32(0.212) * 86400)));
      expect(days(s.good), 2); // 2.3065
      expect(days(s.hard), 1); // 1.2931
    });

    test('review: intervals from stability at the desired retention, each button > the last', () {
      final w = Fsrs(const [
        0.6845422, 1.6790825, 4.7349424, 10.042885, 7.4410233, 0.64219797, 1.071918, 0.0025195254, //
        1.432437, 0.1544, 0.8692766, 2.0696752, 0.0953, 0.2975, 2.4691248, 0.19542035, 3.201072,
        0.18046261, 0.121442534,
      ]);
      final memory = w.memoryState(const [FsrsReview(1, 0), FsrsReview(3, 1), FsrsReview(3, 3), FsrsReview(3, 8)]);
      final next = w.nextStates(memory, 0.9, 21);
      final s = scheduler.nextStates(review(ivl: 21, memory: memory), ctx(fsrs: next));
      // Unlike SM-2, FSRS lets Hard shorten the interval: 17.09 days, and
      // the old 21 is outside its fuzz range (max 20), so no minimum applies.
      expect([days(s.hard), days(s.good), days(s.easy)], [17, 32, 72]);
      expect((s.good as ReviewState).memory!.stability, f32(31.722992));
    });

    test('the revlog stores the shifted difficulty in place of the ease', () {
      final next = fsrs.nextStates(const MemoryState(10, 5), 0.9, 10);
      final s = scheduler.nextStates(review(memory: const MemoryState(10, 5)), ctx(fsrs: next));
      final applied = applyAnswer(
        card: const CardSchedState(queue: CardQueue.review, due: today, ivl: 10, ease: 2500, stability: 10, difficulty: 5),
        current: s.current,
        next: s.good,
        config: config,
        today: today,
        nowSecs: 1700000000,
        secsUntilRollover: 3600,
        fuzzSeed: null,
      );
      final d = next.good.memory.difficulty;
      expect(applied.revlogEaseFactor, roundToU32(f32(f32(f32(f32(d - 1) / 9) + f32(0.1)) * 1000)));
      expect(applied.revlogKind, RevlogKind.review);
      expect(applied.card.stability, next.good.memory.stability);
    });
  });

  group('memory state from history (Anki memory_state.rs tests)', () {
    final now = DateTime.now().millisecondsSinceEpoch;
    RevlogItem revlog(int kind, int daysAgo, {int interval = 1, int ease = 0}) => RevlogItem(
          idMs: now - daysAgo * 86400 * 1000,
          rating: kind == RevlogKind.manual || kind == RevlogKind.rescheduled ? 0 : 3,
          kind: kind,
          interval: interval,
          easeFactor: ease,
        );
    final nextDayAt = now ~/ 1000;

    test('bypassed learning: starts from the SM-2 state of the first review', () {
      final fsrs = Fsrs.defaults();
      final item = fsrsItemForMemoryState(
        fsrs,
        [revlog(RevlogKind.review, 99, interval: 100, ease: 2500), revlog(RevlogKind.review, 0)],
        nextDayAt,
        0.9,
        0,
      )!;
      expect(item.startingState!.stability.round(), 100);
      expect(item.startingState!.difficulty.round(), 5); // 5.003576
      final m = memoryStateForCard(
          fsrs: fsrs, item: item, isNew: false, interval: 0, easeFactor: 0, historicalRetention: 0.9)!;
      expect(m.stability.round(), 249); // 248.9251
      expect(m.difficulty.round(), 5); // 4.9938006
    });

    test('a single review-type entry still gives a memory state', () {
      final fsrs = Fsrs.defaults();
      final item = fsrsItemForMemoryState(
          fsrs, [revlog(RevlogKind.review, 100, interval: 100, ease: 2500)], nextDayAt, 0.9, 0)!;
      expect(item.reviews, isEmpty);
      final m = memoryStateForCard(
          fsrs: fsrs, item: item, isNew: false, interval: 0, easeFactor: 0, historicalRetention: 0.9)!;
      expect(m.stability.round(), 100);
      expect(m.difficulty.round(), 5);
    });

    test('no history: inferred from the current interval and ease', () {
      final m = memoryStateForCard(
        fsrs: Fsrs.defaults(),
        item: null,
        isNew: false,
        interval: 100,
        easeFactor: 1300,
        historicalRetention: 0.9,
      )!;
      expect(m.stability.round(), 100); // 99.999954
      expect(m.difficulty.round(), 10); // 9.979899
    });
  });

  group('fuzz', () {
    test('ranges match Anki', () {
      expect(constrainedFuzzBounds(2, 1, 36500), (2, 2)); // < 2.5 days: none
      expect(constrainedFuzzBounds(4, 1, 36500), (3, 5));
      expect(constrainedFuzzBounds(25, 1, 36500), (22, 28));
      expect(constrainedFuzzBounds(100, 1, 36500), (93, 107));
    });

    test('the fuzz factor is a stable value in [0, 1) per card and review', () {
      expect(fuzzFactor(1700000000000, 3), fuzzFactor(1700000000000, 3));
      expect(fuzzFactor(1700000000000, 3), isNot(fuzzFactor(1700000000000, 4)));
      final values = [for (var i = 0; i < 500; i++) fuzzFactor(1700000000000 + i * 7919, 0)];
      expect(values.every((v) => v >= 0 && v < 1), isTrue);
      expect(values.where((v) => v < 0.5).length, inInclusiveRange(200, 300));
    });

    test('learning steps get up to 25% (max 5 min) of fuzz', () {
      for (var seed = 0; seed < 50; seed++) {
        expect(learningIvlWithFuzz(seed, 600), inInclusiveRange(600, 749));
        expect(learningIvlWithFuzz(seed, 3600), inInclusiveRange(3600, 3899));
      }
      expect(learningIvlWithFuzz(null, 600), 600);
    });
  });

  group('load balancer', () {
    test('prefers the emptier day within the fuzz range', () {
      final dueByDay = List.generate(LoadBalancer.loadBalanceDays, (_) => <int>[]);
      for (final d in [9, 10, 11, 12]) {
        dueByDay[d] = List.filled(50, 1); // busy
      }
      dueByDay[8] = [1]; // nearly empty
      final lb = LoadBalancer(dueByDay: dueByDay, easyDays: const [], nextDayAt: DateTime(2026, 1, 1, 4));
      final picks = [for (var seed = 0; seed < 200; seed++) lb.findInterval(10, 1, 36500, fuzzSeed: seed)!];
      expect(picks.every((p) => p >= 8 && p <= 12), isTrue);
      expect(picks.where((p) => p == 8).length, greaterThan(150));
    });

    test('leaves long intervals to plain fuzz', () {
      final lb = LoadBalancer(dueByDay: null, easyDays: const [], nextDayAt: DateTime(2026, 1, 1, 4));
      expect(lb.findInterval(120, 1, 36500, fuzzSeed: 1), isNull);
    });
  });

  group('day rollover', () {
    final created = DateTime(2026, 1, 1, 12, 0);
    test('same day until the rollover hour, next day from it', () {
      expect(dayNumber(DateTime(2026, 1, 2, 3, 59), created, rolloverHour: 4), 0);
      expect(dayNumber(DateTime(2026, 1, 2, 4, 0), created, rolloverHour: 4), 1);
    });
  });
}
