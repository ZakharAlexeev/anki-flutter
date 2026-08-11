import 'dart:math';

/// Applies Anki-style fuzz to a review interval.
///
/// [random] is optional and injected on purpose: passing `null` (the
/// default in previews) returns the unfuzzed, clamped value so previews and
/// tests stay deterministic; passing a real [Random] (the default when an
/// answer is actually committed) adds the same randomised spread Anki uses
/// so two cards graduating on the same day don't all come due together.
int fuzzedInterval(int ivl, {required int minIvl, required int maxIvl, Random? random}) {
  final clampedMin = max(1, minIvl);
  var result = ivl;

  if (result >= 2) {
    final spread = _fuzzSpread(result);
    if (spread > 0 && random != null) {
      result = result - spread + random.nextInt(spread * 2 + 1);
    }
  }

  if (result < clampedMin) result = clampedMin;
  if (result > maxIvl) result = maxIvl;
  return result;
}

/// Mirrors Anki's `_fuzzedIntervalRange` buckets: the spread grows with the
/// interval so short intervals barely move and long ones can drift by ~5%.
int _fuzzSpread(int ivl) {
  if (ivl < 2) return 0;
  if (ivl < 7) return 1;
  if (ivl < 30) return max(1, (ivl * 0.15).round());
  return max(1, (ivl * 0.05).round());
}
