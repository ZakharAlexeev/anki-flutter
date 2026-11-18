import 'dart:math' as math;

import 'f32.dart';

/// A port of the FSRS-6 model from `fsrs-rs` 6.6.2 - the crate Anki 26.09
/// uses - covering everything Anki needs while studying: next states for
/// the four buttons, intervals for a desired retention, memory state from a
/// review history, and the SM-2 fallback. Every operation is rounded to f32
/// in the same order as the Rust source, so results match Anki's.
///
/// Parameter *optimisation* (training on your review history) is not part
/// of this port; optimised parameters can be copied from desktop Anki.
class Fsrs {
  Fsrs._(this.w);

  /// `FSRS::new`: accepts 0 (defaults), 17 (FSRS-4.5), 19 (FSRS-5) or 21
  /// (FSRS-6) parameters, upgrades older sets the way fsrs-rs does, then
  /// clips them to their valid ranges. Throws [FormatException] otherwise.
  factory Fsrs(List<double> parameters) {
    final filled = checkAndFillParameters(parameters);
    return Fsrs._(List.unmodifiable(_clip(filled)));
  }

  factory Fsrs.defaults() => Fsrs(const []);

  /// The 21 parameters actually in use (after filling and clipping).
  final List<double> w;

  static const fsrs5DefaultDecay = 0.5;
  static const fsrs6DefaultDecay = 0.1542;

  static const defaultParameters = <double>[
    0.212, 1.2931, 2.3065, 8.2956, 6.4133, 0.8334, 3.0194, 0.001, 1.8722, 0.1666, //
    0.796, 1.4835, 0.0614, 0.2629, 1.6483, 0.6014, 1.8729, 0.5425, 0.0912, 0.0658,
    fsrs6DefaultDecay,
  ];

  static final sMin = f32(0.001);
  static const sMax = 36500.0;
  static const dMin = 1.0;
  static const dMax = 10.0;
  static const _initSMax = 100.0;

  /// Anki's `get_decay_from_params`: the decay a parameter set implies.
  static double decayFromParams(List<double> params) {
    if (params.isEmpty) return f32(fsrs6DefaultDecay);
    if (params.length < 21) return fsrs5DefaultDecay;
    return f32(params[20]);
  }

  static List<double> checkAndFillParameters(List<double> parameters) {
    List<double> p;
    switch (parameters.length) {
      case 0:
        p = [for (final v in defaultParameters) f32(v)];
      case 17:
        p = [for (final v in parameters) f32(v)];
        p[4] = f32(p[5] * 2 + p[4]); // mul_add: one rounding
        p[5] = f32(f32Ln(f32(p[5] * 3 + 1)) / 3);
        p[6] = f32(p[6] + 0.5);
        p.addAll([0, 0, 0, fsrs5DefaultDecay]);
      case 19:
        p = [for (final v in parameters) f32(v), 0, fsrs5DefaultDecay];
      case 21:
        p = [for (final v in parameters) f32(v)];
      default:
        throw const FormatException('FSRS needs 17, 19 or 21 parameters');
    }
    if (p.any((v) => !v.isFinite)) throw const FormatException('FSRS parameters must be finite');
    return p;
  }

  // clip_parameters with ModelConfig::default(): one relearning step, short
  // term not forced on.
  static List<double> _clip(List<double> p) {
    const w17w18Ceiling = 2.0;
    const w19Floor = 0.0;
    final clamps = <(double, double)>[
      (sMin, _initSMax), (sMin, _initSMax), (sMin, _initSMax), (sMin, _initSMax),
      (dMin, dMax),
      (0.001, 4.0), (0.001, 4.0), (0.001, 0.75), (0.0, 4.5), (0.0, 0.8),
      (0.001, 3.5), (0.001, 5.0), (0.001, 0.25), (0.001, 0.9), (0.0, 4.0),
      (0.0, 1.0), (1.0, 6.0), (0.0, w17w18Ceiling), (0.0, w17w18Ceiling), (w19Floor, 0.8),
      (0.1, 0.8),
    ];
    return [for (var i = 0; i < 21; i++) f32(p[i].clamp(f32(clamps[i].$1), f32(clamps[i].$2)))];
  }

  // --- formulas (model.rs) -------------------------------------------------

  double powerForgettingCurve(double t, double s) {
    final decay = f32(-w[20]);
    final factor = f32(f32Exp(f32(f32Ln(f32(0.9)) / decay)) - 1);
    return f32Pow(f32(f32(f32(t / s) * factor) + 1), decay);
  }

  double nextIntervalForStability(double stability, double desiredRetention) {
    final decay = f32(-w[20]);
    final factor = f32(f32Exp(f32(f32Ln(f32(0.9)) / decay)) - 1);
    return f32(f32(f32(stability) / factor) * f32(f32Pow(f32(desiredRetention), f32(1 / decay)) - 1));
  }

  double initStability(int rating) => w[math.min(math.max(rating - 1, 0), 3)];

  double initDifficulty(int rating) =>
      f32(f32(w[4] - f32Exp(f32(w[5] * math.max(rating - 1, 0).toDouble()))) + 1);

  double _meanReversion(double newD) => f32(f32(w[7] * f32(initDifficulty(4) - newD)) + newD);

  double _linearDamping(double deltaD, double oldD) => f32(f32(f32(10 - oldD) * deltaD) / 9);

  double _nextDifficulty(double d, double rating) {
    final deltaD = f32(-w[6] * f32(rating - 3));
    return f32(d + _linearDamping(deltaD, d));
  }

  double _stabilityAfterSuccess(double s, double d, double r, double rating) {
    final hardPenalty = rating == 2 ? w[15] : 1.0;
    final easyBonus = rating == 4 ? w[16] : 1.0;
    var x = f32Exp(w[8]);
    x = f32(x * f32(11 - d));
    x = f32(x * f32Pow(s, f32(-w[9])));
    x = f32(x * f32(f32Exp(f32(f32(1 - r) * w[10])) - 1));
    x = f32(x * hardPenalty);
    x = f32(x * easyBonus);
    return f32(s * f32(x + 1));
  }

  double _stabilityAfterFailure(double s, double d, double r) {
    var newS = f32(w[11] * f32Pow(d, f32(-w[12])));
    newS = f32(newS * f32(f32Pow(f32(s + 1), w[13]) - 1));
    newS = f32(newS * f32Exp(f32(f32(1 - r) * w[14])));
    final newSMin = f32(s / f32Exp(f32(w[17] * w[18])));
    return math.min(newS, newSMin);
  }

  double _stabilityShortTerm(double s, double rating) {
    final sinc = f32(f32Exp(f32(w[17] * f32(f32(rating - 3) + w[18]))) * f32Pow(s, f32(-w[19])));
    return f32(s * (rating >= 2 ? math.max(sinc, 1.0) : sinc));
  }

  MemoryState step(double deltaT, int rating, MemoryState state, int nth) {
    final r = rating.toDouble();
    final lastS = state.stability.clamp(sMin, sMax);
    final lastD = state.difficulty.clamp(dMin, dMax);

    final retrievability = powerForgettingCurve(deltaT, lastS);
    final success = _stabilityAfterSuccess(lastS, lastD, retrievability, r);
    final failure = _stabilityAfterFailure(lastS, lastD, retrievability);
    final shortTerm = _stabilityShortTerm(lastS, r);

    var newS = r == 1 ? failure : success;
    if (deltaT == 0) newS = shortTerm;

    var newD = _nextDifficulty(lastD, r);
    newD = _meanReversion(newD).clamp(dMin, dMax);

    if (nth == 0 && state.stability == 0) {
      final initRating = rating.clamp(1, 4);
      newS = initStability(initRating);
      newD = initDifficulty(initRating).clamp(dMin, dMax);
    }
    if (rating == 0) {
      newS = lastS;
      newD = lastD;
    }
    return MemoryState(newS.clamp(sMin, sMax), newD);
  }

  // --- API (inference.rs) --------------------------------------------------

  /// The memory state and interval each button would lead to.
  NextStates nextStates(MemoryState? current, double desiredRetention, int daysElapsed) {
    final state = current ?? const MemoryState(0, 0);
    final nth = current == null ? 0 : 1;
    ItemState next(int rating) {
      final memory = _validate(step(daysElapsed.toDouble(), rating, state, nth));
      return ItemState(memory, nextIntervalForStability(memory.stability, desiredRetention));
    }

    return NextStates(next(1), next(2), next(3), next(4));
  }

  /// Memory state after a whole review history (`FSRS::memory_state`).
  MemoryState memoryState(List<FsrsReview> reviews, {MemoryState? startingState}) {
    MemoryState state;
    int start;
    if (startingState != null) {
      state = startingState;
      start = 0;
    } else if (reviews.isEmpty) {
      state = const MemoryState(0, 0);
      start = 0;
    } else {
      final first = reviews.first;
      state = first.rating == 0
          ? MemoryState(sMin, dMin)
          : MemoryState(
              initStability(first.rating.clamp(1, 4)).clamp(sMin, sMax),
              initDifficulty(first.rating.clamp(1, 4)).clamp(dMin, dMax),
            );
      start = 1;
    }
    for (var i = start; i < reviews.length; i++) {
      state = step(reviews[i].deltaT.toDouble(), reviews[i].rating, state, i);
    }
    return _validate(state);
  }

  /// Approximates a memory state from SM-2 ease and interval, for cards
  /// whose review history is incomplete.
  MemoryState memoryStateFromSm2(double easeFactor, double interval, double sm2Retention) {
    final decay = f32(-w[20]);
    final factor = f32(f32Pow(f32(0.9), f32(1 / decay)) - 1);
    final stability = f32(f32(math.max(f32(interval), sMin) * factor) /
        f32(f32Pow(f32(sm2Retention), f32(1 / decay)) - 1));
    final denom = f32(f32(f32Exp(w[8]) * f32Pow(stability, f32(-w[9]))) *
        f32ExpM1(f32(f32(1 - f32(sm2Retention)) * w[10])));
    final difficulty = f32(11 - f32(f32(f32(easeFactor) - 1) / denom));
    if (!stability.isFinite || !difficulty.isFinite) {
      throw const FormatException('cannot derive a memory state from these SM-2 values');
    }
    return MemoryState(stability, difficulty.clamp(dMin, dMax));
  }

  /// `current_retrievability`: probability of recall after [daysElapsed].
  static double currentRetrievability(MemoryState state, double daysElapsed, double decay) {
    final factor = f32(f32Pow(f32(0.9), f32(1 / f32(-decay))) - 1);
    return f32Pow(f32(f32(f32(daysElapsed / state.stability) * factor) + 1), f32(-decay));
  }

  static MemoryState _validate(MemoryState s) {
    if (!s.stability.isFinite || !s.difficulty.isFinite) {
      throw const FormatException('FSRS produced an invalid memory state');
    }
    return s;
  }
}

class MemoryState {
  const MemoryState(this.stability, this.difficulty);
  final double stability;
  final double difficulty;

  @override
  bool operator ==(Object other) =>
      other is MemoryState && other.stability == stability && other.difficulty == difficulty;

  @override
  int get hashCode => Object.hash(stability, difficulty);

  @override
  String toString() => 'MemoryState(s: $stability, d: $difficulty)';
}

class ItemState {
  const ItemState(this.memory, this.interval);
  final MemoryState memory;
  final double interval;
}

class NextStates {
  const NextStates(this.again, this.hard, this.good, this.easy);
  final ItemState again;
  final ItemState hard;
  final ItemState good;
  final ItemState easy;
}

class FsrsReview {
  const FsrsReview(this.rating, this.deltaT);
  final int rating;
  final int deltaT;
}
