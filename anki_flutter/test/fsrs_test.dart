import 'package:anki_flutter/domain/scheduler/f32.dart';
import 'package:anki_flutter/domain/scheduler/fsrs.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reference values copied from fsrs-rs 6.6.2's own tests and docs
/// (src/inference.rs). Rust compares these with `assert_eq!` on f32, and so
/// do these tests: every value must be the identical f32, bit for bit.
/// (The two tests Rust itself runs with a tolerance keep that tolerance.)
void main() {
  // The FSRS-5 (19-parameter) set used throughout fsrs-rs's tests.
  const parameters19 = <double>[
    0.6845422, 1.6790825, 4.7349424, 10.042885, 7.4410233, 0.64219797, 1.071918, 0.0025195254, //
    1.432437, 0.1544, 0.8692766, 2.0696752, 0.0953, 0.2975, 2.4691248, 0.19542035, 3.201072,
    0.18046261, 0.121442534,
  ];

  Matcher f32Close(double expected) => equals(f32(expected));

  void expectState(MemoryState actual, double s, double d) {
    expect(actual.stability, f32Close(s), reason: 'stability');
    expect(actual.difficulty, f32Close(d), reason: 'difficulty');
  }

  test('next_states for a new card with default parameters (doc example)', () {
    final next = Fsrs.defaults().nextStates(null, 0.9, 0);
    expectState(next.again.memory, 0.212, 6.4133);
    expectState(next.hard.memory, 1.2931, 5.1121707);
    expectState(next.good.memory, 2.3065, 2.118104);
    expectState(next.easy.memory, 8.2956, 1.0);
    expect(next.good.interval, f32Close(2.3065));
  });

  test('test_memo_state', () {
    final fsrs = Fsrs(parameters19);
    const item = [FsrsReview(1, 0), FsrsReview(3, 1), FsrsReview(3, 3), FsrsReview(3, 8), FsrsReview(3, 21)];
    expectState(fsrs.memoryState(item), 31.722992, 7.382128);
    final good = fsrs.nextStates(const MemoryState(20.925528, 7.005062), 0.9, 21).good.memory;
    expectState(good, 40.87456, 6.9913807);
  });

  test('test_next_states', () {
    final fsrs = Fsrs(parameters19);
    const item = [FsrsReview(1, 0), FsrsReview(3, 1), FsrsReview(3, 3), FsrsReview(3, 8)];
    final next = fsrs.nextStates(fsrs.memoryState(item), 0.9, 21);
    expectState(next.again.memory, 2.9691455, 8.000659);
    expectState(next.hard.memory, 17.091452, 7.6913934);
    expectState(next.good.memory, 31.722992, 7.382128);
    expectState(next.easy.memory, 71.7502, 7.0728626);
    expect(fsrs.nextIntervalForStability(121.01552, 0.9), f32Close(121.01551));
  });

  test('test_memory_state (default parameters, with and without short-term)', () {
    void run(List<double> w, double s, double d) {
      final fsrs = Fsrs(w);
      MemoryState? state;
      const ratings = [1, 3, 3, 3, 3, 3];
      const intervals = [0, 0, 1, 3, 8, 21];
      for (var i = 0; i < ratings.length; i++) {
        final next = fsrs.nextStates(state, 0.9, intervals[i]);
        state = [next.again, next.hard, next.good, next.easy][ratings[i] - 1].memory;
      }
      expect(state!.stability, closeTo(s, 1e-4));
      expect(state.difficulty, closeTo(d, 1e-4));
    }

    run(Fsrs.defaultParameters, 53.62691, 6.3574867);
    final frozen = [...Fsrs.defaultParameters]
      ..[17] = 0
      ..[18] = 0
      ..[19] = 0;
    run(frozen, 53.335106, 6.3574867);
  });

  test('test_next_interval', () {
    final fsrs = Fsrs.defaults();
    final intervals = [
      for (var i = 1; i <= 10; i++) roundToU32(fsrs.nextIntervalForStability(1.0, f32(i / 10))).clamp(1, 1 << 31),
    ];
    expect(intervals, [3116766, 34793, 2508, 387, 90, 27, 9, 3, 1, 1]);
  });

  test('test_current_retrievability', () {
    const state = MemoryState(1.0, 5.0);
    expect(Fsrs.currentRetrievability(state, 0, 0.2), 1.0);
    expect(Fsrs.currentRetrievability(state, 1, 0.2), f32Close(0.9));
    expect(Fsrs.currentRetrievability(state, 2, 0.2), f32Close(0.84028935));
    expect(Fsrs.currentRetrievability(state, 3, 0.2), f32Close(0.7985001));
  });

  test('test_memory_from_sm2', () {
    final fsrs = Fsrs.defaults();
    void check(double ease, double ivl, double r, double s, double d) {
      final m = fsrs.memoryStateFromSm2(ease, ivl, r);
      expect(m.stability, closeTo(s, 1e-3));
      expect(m.difficulty, closeTo(d, 1e-3));
    }

    check(2.5, 10, 0.9, 10.0, 6.9140563);
    check(2.5, 10, 0.8, 3.01572, 9.393428);
    check(2.5, 10, 0.95, 24.841097, 1.2974405);
    check(1.3, 20, 0.9, 20.0, 10.0);
    // SM-2 ease 2.0 at 15 days maps to an FSRS growth factor of ~2.0.
    final good = fsrs.nextStates(fsrs.memoryStateFromSm2(2.0, 15, 0.9), 0.9, 15).good.memory.stability;
    expect((good / 15 - 2.0).abs(), lessThan(0.01));
  });

  test('older parameter sets are upgraded like fsrs-rs', () {
    expect(Fsrs(parameters19).w, hasLength(21));
    expect(Fsrs(parameters19).w[20], 0.5);
    expect(() => Fsrs(const [1, 2, 3]), throwsFormatException);
    expect(Fsrs.decayFromParams(const []), f32(0.1542));
    expect(Fsrs.decayFromParams(parameters19), 0.5);
  });
}
