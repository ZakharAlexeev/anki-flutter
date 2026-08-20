/// Converts wall-clock time into Anki-style "collection day numbers", so a
/// review due "today" stays due until the configurable rollover hour (04:00
/// by default) rather than at midnight.
int dayNumber(DateTime now, DateTime collectionCreatedAt, {int rolloverHour = 4}) {
  final rolledNow = _rolledDateAsUtc(now, rolloverHour);
  final rolledCreated = _rolledDateAsUtc(collectionCreatedAt, rolloverHour);
  return rolledNow.difference(rolledCreated).inDays;
}

/// The local calendar date (after subtracting [rolloverHour]) reinterpreted
/// as a UTC instant, purely so day-count arithmetic below isn't thrown off
/// by DST transitions - UTC has none, so `.difference(...).inDays` between
/// two of these is always an exact whole-day count, unlike subtracting two
/// local `DateTime`s (which follows real elapsed time and can read as 23h or
/// 25h across a spring-forward/fall-back day, flooring to the wrong day).
/// Never used as an actual timestamp.
DateTime _rolledDateAsUtc(DateTime t, int rolloverHour) {
  final shifted = t.subtract(Duration(hours: rolloverHour));
  return DateTime.utc(shifted.year, shifted.month, shifted.day);
}

/// Inverse of [dayNumber]: the wall-clock instant a given collection day
/// starts at (i.e. the rollover-hour boundary).
DateTime dayStart(int dayNumber, DateTime collectionCreatedAt, {int rolloverHour = 4}) {
  final rolledCreated = _rolledDateAsUtc(collectionCreatedAt, rolloverHour);
  final target = rolledCreated.add(Duration(days: dayNumber));
  return DateTime(target.year, target.month, target.day, rolloverHour);
}
