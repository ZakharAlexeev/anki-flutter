import 'dart:typed_data';

import 'package:anki_flutter/domain/scheduler/rust_rand.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('StdRng matches rand 0.9 value-stability vector (test_stdrng_construction)', () {
    final seed = Uint8List.fromList([
      1, 0, 0, 0, 23, 0, 0, 0, 200, 1, 0, 0, 210, 30, 0, 0, //
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    ]);
    final rng = StdRng.fromSeed(seed);
    expect(BigInt.from(rng.nextU64()).toUnsigned(64), BigInt.parse('10719222850664546238'));
  });

  test('the stream is deterministic and continues correctly across block refills', () {
    final a = StdRng.seedFromU64(42);
    final first = [for (var i = 0; i < 130; i++) a.nextU32()];
    final b = StdRng.seedFromU64(42);
    final again = [for (var i = 0; i < 130; i++) b.nextU32()];
    expect(again, first);
    expect(first.toSet().length, greaterThan(120));
  });

  test('float and integer ranges stay in bounds', () {
    final rng = StdRng.seedFromU64(1700000000123);
    for (var i = 0; i < 1000; i++) {
      final f = rng.randomF32Range(0, 1);
      expect(f, inInclusiveRange(0, 0.9999999));
      final n = rng.randomRangeU32(600, 750);
      expect(n, inInclusiveRange(600, 749));
    }
  });

  test('weighted index picks only positive-weight entries', () {
    final rng = StdRng.seedFromU64(7);
    for (var i = 0; i < 200; i++) {
      final idx = sampleWeightedIndex([0, 1, 0, 3], rng)!;
      expect(idx == 1 || idx == 3, isTrue);
    }
    expect(sampleWeightedIndex([0, 0], rng), isNull);
  });
}
