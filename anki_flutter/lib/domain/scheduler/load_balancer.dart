import 'dart:math' as math;

import 'f32.dart';
import 'fuzz.dart';
import 'rust_rand.dart';

/// Port of Anki's load balancer (rslib `scheduler/states/load_balancer.rs`,
/// on by default since Anki 24.11). Instead of picking a fuzzed review
/// interval uniformly, it picks a day inside the same fuzz range weighted
/// towards days with fewer reviews already due - smoothing out the daily
/// workload - and honours "easy days".
class LoadBalancer {
  LoadBalancer({required this.dueByDay, required this.easyDays, required this.nextDayAt});

  static const maxLoadBalanceInterval = 90;
  static const loadBalanceDays = 99; // (90 * 1.1) as usize

  /// For the card's preset: note ids of the cards due on each of the next
  /// [loadBalanceDays] days (index 0 = today), as Anki's
  /// `get_all_cards_due_in_range` reports them. Null when no card of the
  /// preset is due in that window (Anki then falls back to plain fuzz).
  final List<List<int>>? dueByDay;

  /// Easy-days percentages Mon..Sun (empty = all normal).
  final List<double> easyDays;

  /// Start of the next collection day (the "next day at" timestamp).
  final DateTime nextDayAt;

  int? findInterval(double interval, int minimum, int maximum, {required int? fuzzSeed, int? noteId}) {
    if (truncToU32(interval) > maxLoadBalanceInterval || minimum > maxLoadBalanceInterval) return null;
    final (before, after) = constrainedFuzzBounds(interval, minimum, maximum);
    final days = dueByDay;
    if (days == null) return null;

    final counts = <int>[];
    final weekdays = <int>[];
    for (var day = before; day <= after; day++) {
      counts.add(day < days.length ? days[day].length : 0);
      weekdays.add(_weekday(day));
    }
    final easy = _easyDaysModifiers(weekdays, counts);
    final sibling = _siblingModifiers(before, after, noteId);

    final weights = <double>[];
    for (var i = 0; i < counts.length; i++) {
      final target = before + i;
      if (counts[i] == 0) {
        weights.add(1.0);
      } else {
        final countWeight = f32Pow(f32(1 / counts[i]), f32(2.15));
        final inv = f32(1 / target);
        final intervalWeight = f32(f32(inv * inv) * inv); // powi(3)
        weights.add(f32(f32(f32(countWeight * intervalWeight) * sibling[i]) * easy[i]));
      }
    }
    if (fuzzSeed == null) return null;
    final index = sampleWeightedIndex(weights, StdRng.seedFromU64(fuzzSeed));
    return index == null ? null : before + index;
  }

  int _weekday(int interval) {
    final at = nextDayAt.add(Duration(days: interval - 1)).toLocal();
    return at.weekday - 1; // Monday = 0
  }

  static const _normal = 1.0, _reduced = 0.5, _minimum = 0.0001;

  double _loadModifier(double percentage) => switch (percentage) {
        1.0 => _normal,
        0.0 => _minimum,
        _ => _reduced,
      };

  List<double> _easyDaysModifiers(List<int> weekdays, List<int> counts) {
    final pct = easyDays.length == 7 ? easyDays : List.filled(7, 1.0);
    final totalCount = counts.fold<int>(0, (a, b) => a + b);
    var totalPercents = 0.0;
    for (final wd in weekdays) {
      totalPercents = f32(totalPercents + _loadModifier(pct[wd]));
    }
    return [
      for (var i = 0; i < weekdays.length; i++)
        () {
          final p = pct[weekdays[i]];
          if (p != 1.0 && p != 0.0) {
            const half = 0.5;
            final otherDaysReviewTotal = (totalCount - counts[i]).toDouble();
            final otherDaysPercentTotal = f32(totalPercents - half);
            final normalizedCount = f32(counts[i] / half);
            final threshold = f32(otherDaysReviewTotal / otherDaysPercentTotal);
            return normalizedCount > threshold ? _minimum : _normal;
          }
          return _loadModifier(p);
        }(),
    ];
  }

  static const _siblingSteps = [-5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5];
  static const _siblingRange = [1.0, 0.8, 0.6, 0.4, 0.2, 0.000001, 0.2, 0.4, 0.6, 0.8, 1.0];

  /// Only used when "bury reviews" is on in Anki (it passes the note id then).
  List<double> _siblingModifiers(int before, int after, int? noteId) {
    final modifiers = List<double>.filled(after - before + 1, 1.0);
    final days = dueByDay;
    if (noteId == null || days == null) return modifiers;
    for (var siblingDay = 0; siblingDay < days.length; siblingDay++) {
      if (!days[siblingDay].contains(noteId)) continue;
      for (var k = 0; k < _siblingSteps.length; k++) {
        final target = siblingDay + _siblingSteps[k] - before;
        if (target >= 0 && target < modifiers.length) {
          modifiers[target] = f32(modifiers[target] * f32(_siblingRange[k]));
        }
      }
    }
    return modifiers;
  }
}

/// Groups due values into the load balancer's day buckets for one preset.
List<List<int>>? bucketDueByDay(Iterable<(int due, int noteId)> cards, int today) {
  final days = List.generate(LoadBalancer.loadBalanceDays, (_) => <int>[]);
  var any = false;
  for (final (due, noteId) in cards) {
    final offset = due - today;
    if (offset >= 0 && offset < LoadBalancer.loadBalanceDays) {
      days[offset].add(noteId);
      any = true;
    }
  }
  return any ? days : null;
}

int clampInt(int v, int lo, int hi) => math.min(math.max(v, lo), hi);
