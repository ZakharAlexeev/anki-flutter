import 'dart:typed_data';

import 'f32.dart';

/// A bit-exact port of the random number generation Anki's scheduler uses
/// (Rust crate `rand` 0.9.4 / `rand_chacha` 0.9.0 / `rand_core` 0.9.3),
/// so fuzz and load balancing pick exactly the same intervals as desktop
/// Anki for the same card.
///
/// - `StdRng` is ChaCha with 12 rounds, a 64-bit block counter and a zero
///   stream id, buffering 4 blocks (64 words) at a time.
/// - `StdRng::seed_from_u64` expands the seed with PCG32 (rand_core).
/// - Floats in a range use the 23 high bits of one `u32` (UniformFloat).
/// - Integer ranges use the widening-multiply method of UniformInt.
///
/// Dart's native ints are 64-bit two's complement, so u64 arithmetic is done
/// with wrapping operations and unsigned shifts (`>>>`).
class StdRng {
  StdRng.fromSeed(Uint8List seed) : assert(seed.length == 32) {
    final b = ByteData.sublistView(seed);
    for (var i = 0; i < 8; i++) {
      _key[i] = b.getUint32(i * 4, Endian.little);
    }
  }

  /// `rand_core::SeedableRng::seed_from_u64`: 8 rounds of PCG32 fill the
  /// 32-byte ChaCha key.
  factory StdRng.seedFromU64(int seed) {
    var state = seed;
    final bytes = Uint8List(32);
    final view = ByteData.sublistView(bytes);
    for (var i = 0; i < 8; i++) {
      state = state * 6364136223846793005 + -6812163851682824893; // INC = 11634580027462260723
      final xorshifted = (((state >>> 18) ^ state) >>> 27) & 0xFFFFFFFF;
      final rot = (state >>> 59) & 31;
      final x = ((xorshifted >>> rot) | (xorshifted << ((32 - rot) & 31))) & 0xFFFFFFFF;
      view.setUint32(i * 4, x, Endian.little);
    }
    return StdRng.fromSeed(bytes);
  }

  static const _rounds = 12;
  final _key = Uint32List(8);
  int _counter = 0; // 64-bit block counter
  final _buffer = Uint32List(64);
  int _index = 64;

  int nextU32() {
    if (_index >= 64) _refill();
    return _buffer[_index++];
  }

  int nextU64() {
    // rand_core's BlockRng: two consecutive words, low first.
    final lo = nextU32();
    final hi = nextU32();
    return (hi << 32) | lo;
  }

  /// `rng.random_range(0.0f32..1.0)` - and `UniformFloat::sample_single`
  /// in general for [low, high).
  double randomF32Range(double low, double high) {
    final scale = f32(high - low);
    final value0to1 = (nextU32() >>> 9) / 8388608.0; // exact: (1.m - 1) in f32
    return f32(f32(value0to1 * scale) + low);
  }

  /// `rng.random_range(low..high)` for u32 (UniformInt::sample_single,
  /// rand's default "Canon-lite" method).
  int randomRangeU32(int low, int highExclusive) {
    assert(low < highExclusive);
    final range = (highExclusive - 1 - low + 1) & 0xFFFFFFFF;
    if (range == 0) return nextU32();
    var product = nextU32() * range; // < 2^64, exact in a 64-bit int
    var result = product >>> 32;
    final loOrder = product & 0xFFFFFFFF;
    if (loOrder > ((-range) & 0xFFFFFFFF)) {
      final newHiOrder = (nextU32() * range) >>> 32;
      if (loOrder + newHiOrder > 0xFFFFFFFF) result += 1;
    }
    return (low + result) & 0xFFFFFFFF;
  }

  void _refill() {
    for (var block = 0; block < 4; block++) {
      _chachaBlock(_counter + block, _buffer, block * 16);
    }
    _counter += 4;
    _index = 0;
  }

  void _chachaBlock(int counter, Uint32List out, int offset) {
    final s = Uint32List(16)
      ..[0] = 0x61707865
      ..[1] = 0x3320646e
      ..[2] = 0x79622d32
      ..[3] = 0x6b206574;
    for (var i = 0; i < 8; i++) {
      s[4 + i] = _key[i];
    }
    s[12] = counter & 0xFFFFFFFF;
    s[13] = (counter >>> 32) & 0xFFFFFFFF;
    s[14] = 0; // stream id
    s[15] = 0;
    final x = Uint32List.fromList(s);
    for (var i = 0; i < _rounds ~/ 2; i++) {
      _quarter(x, 0, 4, 8, 12);
      _quarter(x, 1, 5, 9, 13);
      _quarter(x, 2, 6, 10, 14);
      _quarter(x, 3, 7, 11, 15);
      _quarter(x, 0, 5, 10, 15);
      _quarter(x, 1, 6, 11, 12);
      _quarter(x, 2, 7, 8, 13);
      _quarter(x, 3, 4, 9, 14);
    }
    for (var i = 0; i < 16; i++) {
      out[offset + i] = x[i] + s[i]; // Uint32List wraps mod 2^32
    }
  }

  static int _rotl(int v, int n) => ((v << n) | (v >>> (32 - n))) & 0xFFFFFFFF;

  static void _quarter(Uint32List x, int a, int b, int c, int d) {
    x[a] = x[a] + x[b];
    x[d] = _rotl(x[d] ^ x[a], 16);
    x[c] = x[c] + x[d];
    x[b] = _rotl(x[b] ^ x[c], 12);
    x[a] = x[a] + x[b];
    x[d] = _rotl(x[d] ^ x[a], 8);
    x[c] = x[c] + x[d];
    x[b] = _rotl(x[b] ^ x[c], 7);
  }
}

/// `rand::distr::weighted::WeightedIndex<f32>` built from [weights] and
/// sampled once: returns the chosen index, or null when the weights are
/// invalid (empty, negative or all zero), like `WeightedIndex::new(..).ok()`.
int? sampleWeightedIndex(List<double> weights, StdRng rng) {
  if (weights.isEmpty) return null;
  var total = f32(weights.first);
  if (!(total >= 0)) return null;
  final cumulative = <double>[];
  for (final w in weights.skip(1)) {
    if (!(w >= 0)) return null;
    cumulative.add(total);
    total = f32(total + f32(w));
  }
  if (total == 0) return null;

  // UniformFloat::<f32>::new(0, total), including new_bounded's adjustment
  // that keeps the largest possible sample strictly below `total`.
  const maxRand = 1.0 - 1.1920928955078125e-7; // 1 - f32::EPSILON
  var scale = total;
  while (f32(f32(scale * maxRand) + 0.0) > total) {
    scale = f32PrevDown(scale);
  }
  final value0to1 = (rng.nextU32() >>> 9) / 8388608.0;
  final chosen = f32(f32(value0to1 * scale) + 0.0);

  // partition_point(|w| w <= chosen)
  var lo = 0, hi = cumulative.length;
  while (lo < hi) {
    final mid = (lo + hi) >> 1;
    if (cumulative[mid] <= chosen) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  return lo;
}
