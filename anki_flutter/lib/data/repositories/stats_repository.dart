import '../../domain/scheduler/day_calendar.dart';
import '../db/database.dart';

class TodayStats {
  final int reviewCount;
  final int minutesStudied;
  final int againCount;
  const TodayStats({required this.reviewCount, required this.minutesStudied, required this.againCount});

  double get accuracyPct => reviewCount == 0 ? 0 : (1 - againCount / reviewCount) * 100;
}

/// One bucket in a day-indexed chart: [dayOffset] is days from today (0 =
/// today; negative = past, positive = future).
class DayCount {
  final int dayOffset;
  final int count;
  const DayCount(this.dayOffset, this.count);
}

class BucketCount {
  final String label;
  final int count;
  const BucketCount(this.label, this.count);
}

class CardCounts {
  final int newCount;
  final int learningCount;
  final int reviewCount;
  final int suspendedCount;
  const CardCounts({
    required this.newCount,
    required this.learningCount,
    required this.reviewCount,
    required this.suspendedCount,
  });

  int get total => newCount + learningCount + reviewCount + suspendedCount;
}

class DeckStats {
  final TodayStats today;
  final List<DayCount> forecast;
  final List<DayCount> reviewHistory;
  final CardCounts cardCounts;
  final List<BucketCount> intervalHistogram;
  final List<BucketCount> easeHistogram;
  final int totalNotes;
  final int totalReviews;
  final int matureCount; // review cards with ivl >= 21 days, Anki's own threshold
  const DeckStats({
    required this.today,
    required this.forecast,
    required this.reviewHistory,
    required this.cardCounts,
    required this.intervalHistogram,
    required this.easeHistogram,
    required this.totalNotes,
    required this.totalReviews,
    required this.matureCount,
  });
}

/// Computes Anki-style review statistics (today's summary, due forecast,
/// review history, card/interval/ease distributions) for one deck or the
/// whole collection. Card/revlog volumes in a personal collection are small
/// enough (thousands, not millions of rows) that bucketing in Dart after a
/// single unfiltered `SELECT` is simpler and plenty fast, rather than
/// pushing histogram logic into SQL.
class StatsRepository {
  StatsRepository(this._db);

  final AppDatabase _db;

  static const int _forecastDays = 30;
  static const int _historyDays = 30;
  static const int _matureThresholdDays = 21;

  Future<DeckStats> load({int? deckId, DateTime? now}) async {
    final n = now ?? DateTime.now();
    final meta = await _db.select(_db.collectionMeta).getSingle();
    final createdAt = DateTime.fromMillisecondsSinceEpoch(meta.createdAt);
    final today = dayNumber(n, createdAt, rolloverHour: meta.rolloverHour);

    final cardsQuery = _db.select(_db.cards);
    if (deckId != null) cardsQuery.where((c) => c.deckId.equals(deckId));
    final cards = await cardsQuery.get();
    final cardIds = cards.map((c) => c.id).toSet();

    final revlogQuery = _db.select(_db.revLog);
    final allRevlog = await revlogQuery.get();
    final revlog = deckId == null ? allRevlog : allRevlog.where((r) => cardIds.contains(r.cardId)).toList();

    return DeckStats(
      today: _todayStats(revlog, n, createdAt, meta.rolloverHour),
      forecast: _forecast(cards, today),
      reviewHistory: _reviewHistory(revlog, createdAt, meta.rolloverHour, today),
      cardCounts: _cardCounts(cards),
      intervalHistogram: _intervalHistogram(cards),
      easeHistogram: _easeHistogram(cards),
      totalNotes: cards.map((c) => c.noteId).toSet().length,
      totalReviews: revlog.length,
      matureCount: cards.where((c) => c.queue == CardQueue.review && c.ivl >= _matureThresholdDays).length,
    );
  }

  TodayStats _todayStats(List<RevLogData> revlog, DateTime now, DateTime createdAt, int rolloverHour) {
    final today = dayNumber(now, createdAt, rolloverHour: rolloverHour);
    final startSec = dayStart(today, createdAt, rolloverHour: rolloverHour).millisecondsSinceEpoch ~/ 1000;
    final endSec = dayStart(today + 1, createdAt, rolloverHour: rolloverHour).millisecondsSinceEpoch ~/ 1000;
    final todays = revlog.where((r) => r.reviewedAt >= startSec && r.reviewedAt < endSec);
    final again = todays.where((r) => r.rating == 1).length;
    final ms = todays.fold<int>(0, (sum, r) => sum + r.timeTakenMs);
    return TodayStats(reviewCount: todays.length, minutesStudied: (ms / 60000).round(), againCount: again);
  }

  List<DayCount> _forecast(List<CardEntry> cards, int today) {
    final buckets = List.filled(_forecastDays, 0);
    for (final c in cards) {
      if (c.queue != CardQueue.review) continue;
      final offset = c.due - today;
      if (offset >= 0 && offset < _forecastDays) buckets[offset]++;
    }
    return [for (var i = 0; i < _forecastDays; i++) DayCount(i, buckets[i])];
  }

  List<DayCount> _reviewHistory(List<RevLogData> revlog, DateTime createdAt, int rolloverHour, int today) {
    final buckets = <int, int>{};
    for (final r in revlog) {
      final reviewedAt = DateTime.fromMillisecondsSinceEpoch(r.reviewedAt * 1000);
      final day = dayNumber(reviewedAt, createdAt, rolloverHour: rolloverHour);
      final offset = day - today;
      if (offset < -(_historyDays - 1) || offset > 0) continue;
      buckets[offset] = (buckets[offset] ?? 0) + 1;
    }
    return [for (var i = -(_historyDays - 1); i <= 0; i++) DayCount(i, buckets[i] ?? 0)];
  }

  CardCounts _cardCounts(List<CardEntry> cards) {
    var newC = 0, learning = 0, review = 0, suspended = 0;
    for (final c in cards) {
      switch (c.queue) {
        case CardQueue.newCard:
          newC++;
          break;
        case CardQueue.learning:
        case CardQueue.relearning:
          learning++;
          break;
        case CardQueue.review:
          review++;
          break;
        case CardQueue.suspended:
          suspended++;
          break;
      }
    }
    return CardCounts(newCount: newC, learningCount: learning, reviewCount: review, suspendedCount: suspended);
  }

  static const _intervalBucketEdges = [1, 3, 7, 14, 30, 90, 180, 365];
  static const _intervalBucketLabels = [
    '0-1д',
    '2-3д',
    '4-7д',
    '1-2нед',
    '2-4нед',
    '1-3мес',
    '3-6мес',
    '6-12мес',
    '1г+',
  ];

  List<BucketCount> _intervalHistogram(List<CardEntry> cards) {
    final buckets = List.filled(_intervalBucketLabels.length, 0);
    for (final c in cards) {
      if (c.queue != CardQueue.review) continue;
      var i = 0;
      while (i < _intervalBucketEdges.length && c.ivl > _intervalBucketEdges[i]) {
        i++;
      }
      buckets[i]++;
    }
    return [for (var i = 0; i < buckets.length; i++) BucketCount(_intervalBucketLabels[i], buckets[i])];
  }

  List<BucketCount> _easeHistogram(List<CardEntry> cards) {
    // Buckets of 10 percentage points, from the ease floor (130%) up.
    final buckets = <int, int>{};
    for (final c in cards) {
      if (c.queue != CardQueue.review) continue;
      final pct = (c.ease / 100).round(); // e.g. 2500 -> 25 (250%)
      final bucket = (pct / 10).floor() * 10;
      buckets[bucket] = (buckets[bucket] ?? 0) + 1;
    }
    final sortedKeys = buckets.keys.toList()..sort();
    return [for (final k in sortedKeys) BucketCount('$k%', buckets[k]!)];
  }
}
