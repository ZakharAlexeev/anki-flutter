import 'f32.dart';
import 'rust_rand.dart';

/// Anki's review-interval fuzz (rslib `scheduler/states/fuzz.rs`).
///
/// Intervals are spread a little so cards learned together don't all come
/// due on the same day: none below 2.5 days, then 15% of the part between
/// 2.5 and 7 days, 10% of 7-20 days and 5% beyond, plus one day.

/// Anki's fuzz seed for a card: its id plus its review count (wrapping u64).
int fuzzSeed(int cardId, int reps) => cardId + reps;

/// `get_fuzz_factor`: `StdRng::seed_from_u64(seed).random_range(0.0..1.0)`,
/// reproduced bit for bit, so a card imported from desktop Anki gets the
/// same fuzz as it would there.
double fuzzFactor(int cardId, int reps) => StdRng.seedFromU64(fuzzSeed(cardId, reps)).randomF32Range(0, 1);

/// `with_review_fuzz` without the load balancer. A null [factor] means no
/// fuzz: the interval is just rounded and clamped.
int withReviewFuzz(double? factor, double interval, int minimum, int maximum) {
  if (factor == null) return roundToU32(interval).clamp(minimum, maximum);
  final (lower, upper) = constrainedFuzzBounds(interval, minimum, maximum);
  return truncToU32(f32(lower + f32(factor * (1 + upper - lower))));
}

/// `minimum_review_fuzz_interval` (FSRS): keeps fuzz from undercutting the
/// previous interval.
int minimumReviewFuzzInterval(double interval, int previousInterval, int maximumInterval) {
  final rounded = roundToU32(interval);
  final (_, upper) = constrainedFuzzBounds(interval, 1, maximumInterval);
  if (rounded > previousInterval) return previousInterval + 1;
  if (previousInterval <= upper) return previousInterval;
  return 0;
}

(int, int) constrainedFuzzBounds(double interval, int minimum, int maximum) {
  final min = minimum < maximum ? minimum : maximum;
  final ivl = f32(interval).clamp(min.toDouble(), maximum.toDouble());
  final (l, u) = fuzzBounds(ivl);
  var lower = l.clamp(min, maximum);
  var upper = u.clamp(min, maximum);
  if (upper == lower && upper > 2 && upper < maximum) upper = lower + 1;
  return (lower, upper);
}

(int, int) fuzzBounds(double interval) {
  final delta = _fuzzDelta(interval);
  return (roundToU32(f32(interval - delta)), roundToU32(f32(interval + delta)));
}

const _fuzzRanges = [(2.5, 7.0, 0.15), (7.0, 20.0, 0.1), (20.0, 3.4028234663852886e38, 0.05)];

double _fuzzDelta(double interval) {
  if (interval < 2.5) return 0;
  var delta = 1.0;
  for (final (start, end, factor) in _fuzzRanges) {
    final span = f32((interval < end ? interval : end) - start);
    delta = f32(delta + f32(f32(factor) * (span > 0 ? span : 0.0)));
  }
  return delta;
}

/// Anki's learning-step fuzz (`learning_ivl_with_fuzz`): a learning or
/// relearning delay is stretched by up to 25%, at most 5 minutes, using
/// the card's fuzz seed.
int learningIvlWithFuzz(int? seed, int secs) {
  if (seed == null) return secs;
  // secs + ((secs as f32) * 0.25).min(300.0).floor() as u32
  final quarter = f32(f32(secs.toDouble()) * 0.25);
  final upperExclusive = secs + truncToU32(quarter < 300 ? quarter : 300.0);
  if (secs >= upperExclusive) return secs;
  return StdRng.seedFromU64(seed).randomRangeU32(secs, upperExclusive);
}
