import 'f32.dart';
import 'fsrs.dart';
import 'scheduler.dart' show RevlogKind;

/// One review-log row, in Anki's terms.
class RevlogItem {
  const RevlogItem({
    required this.idMs,
    required this.rating,
    required this.kind,
    required this.interval,
    required this.easeFactor,
  });

  /// Anki's revlog id: the answer time in epoch milliseconds.
  final int idMs;

  /// Button chosen: 1-4, or 0 for manual/rescheduled entries.
  final int rating;
  final int kind;

  /// Positive days or negative seconds.
  final int interval;
  final int easeFactor;

  bool get hasRating => rating > 0;
  bool get isCramming => kind == RevlogKind.filtered && easeFactor == 0;
  bool get isReset => kind == RevlogKind.manual && easeFactor == 0;
  bool get hasRatingAndAffectsScheduling => hasRating && !isCramming;

  int daysElapsed(int nextDayAtSecs) {
    final secs = nextDayAtSecs - idMs ~/ 1000;
    return secs <= 0 ? 0 : secs ~/ 86400;
  }
}

class FsrsItemForMemoryState {
  const FsrsItemForMemoryState(this.reviews, this.startingState);
  final List<FsrsReview> reviews;
  final MemoryState? startingState;
}

/// Port of Anki's `reviews_for_fsrs` (rslib `scheduler/fsrs/params.rs`)
/// in its non-training form: turns a card's review log (oldest first) into
/// the history FSRS replays, plus whether that history is complete.
({List<FsrsReview> reviews, bool complete, List<RevlogItem> filtered})? reviewsForFsrs(
  List<RevlogItem> input,
  int nextDayAtSecs,
  int ignoreRevlogsBeforeMs,
) {
  var entries = [...input];
  int? firstOfLastLearn;
  int? firstUserGrade;
  var complete = false;

  for (var index = entries.length - 1; index >= 0; index--) {
    final entry = entries[index];
    if (entry.isCramming) continue;
    final withinCutoff = entry.idMs > ignoreRevlogsBeforeMs;
    final interday = entry.interval >= 1 || entry.interval <= -86400;
    if (entry.hasRating && withinCutoff && interday) firstUserGrade = index;

    if (entry.hasRating && entry.kind == RevlogKind.learning) {
      firstOfLastLearn = index;
      complete = true;
    } else if (entry.isReset) {
      if (firstOfLastLearn != null) {
        complete = true;
        break;
      } else if (firstUserGrade != null) {
        complete = false;
        break;
      } else {
        return null;
      }
    } else if (firstOfLastLearn != null) {
      break;
    }
  }

  // While reviewing, a first learning step before the cutoff is ignored in
  // favour of the SM-2 fallback below.
  if (firstOfLastLearn != null &&
      entries[firstOfLastLearn].idMs < ignoreRevlogsBeforeMs &&
      firstOfLastLearn < entries.length - 1) {
    complete = false;
    firstOfLastLearn = null;
  }

  if (firstOfLastLearn != null) {
    if (firstOfLastLearn > 0) entries = entries.sublist(firstOfLastLearn);
  } else {
    final idx = firstUserGrade;
    if (idx == null) return null;
    if (idx > 0) entries = entries.sublist(idx);
  }

  entries = entries.where((e) => e.hasRatingAndAffectsScheduling).toList();
  if (entries.isEmpty) return null;

  final reviews = <FsrsReview>[];
  for (var i = 0; i < entries.length; i++) {
    final deltaT = i == 0
        ? 0
        : entries[i - 1].daysElapsed(nextDayAtSecs) - entries[i].daysElapsed(nextDayAtSecs);
    reviews.add(FsrsReview(entries[i].rating, deltaT));
  }
  return (reviews: reviews, complete: complete, filtered: entries);
}

/// Port of Anki's `fsrs_item_for_memory_state`: the history to replay, and
/// for truncated histories a starting state derived from the first
/// remaining review's SM-2 values.
FsrsItemForMemoryState? fsrsItemForMemoryState(
  Fsrs fsrs,
  List<RevlogItem> entries,
  int nextDayAtSecs,
  double historicalRetention,
  int ignoreRevlogsBeforeMs,
) {
  final output = reviewsForFsrs(entries, nextDayAtSecs, ignoreRevlogsBeforeMs);
  if (output == null) return null;
  if (output.complete) return FsrsItemForMemoryState(output.reviews, null);
  final first = output.filtered.first;
  final interval = f32((first.interval < 1 ? 1 : first.interval).toDouble());
  final ease = f32((first.easeFactor == 0 ? 2500 : first.easeFactor) / 1000);
  var starting = fsrs.memoryStateFromSm2(ease, interval, historicalRetention);
  // An ease of 1.1 or less means the entry was written by FSRS, and stores
  // the (shifted) difficulty instead of an ease.
  if (ease <= 1.1) {
    starting = MemoryState(starting.stability, f32(f32(f32(ease - 0.1) * 9) + 1));
  }
  return FsrsItemForMemoryState(output.reviews.sublist(1), starting);
}

/// Port of `Card::set_memory_state`: the card's memory state from its
/// history, falling back to its current SM-2 interval and ease.
MemoryState? memoryStateForCard({
  required Fsrs fsrs,
  required FsrsItemForMemoryState? item,
  required bool isNew,
  required int interval,
  required int easeFactor,
  required double historicalRetention,
}) {
  if (item != null) return fsrs.memoryState(item.reviews, startingState: item.startingState);
  if (isNew || interval == 0) return null;
  return fsrs.memoryStateFromSm2(f32(easeFactor / 1000), f32(interval.toDouble()), historicalRetention);
}
