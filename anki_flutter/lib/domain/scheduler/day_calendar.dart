/// Converts wall-clock time into Anki-style "collection day numbers", so a
/// review due "today" stays due until the configurable rollover hour (04:00
/// by default) rather than at midnight.
int dayNumber(DateTime now, DateTime collectionCreatedAt, {int rolloverHour = 4}) {
  final rolledNow = _rolledDate(now, rolloverHour);
  final rolledCreated = _rolledDate(collectionCreatedAt, rolloverHour);
  return rolledNow.difference(rolledCreated).inDays;
}

DateTime _rolledDate(DateTime t, int rolloverHour) {
  final shifted = t.subtract(Duration(hours: rolloverHour));
  return DateTime(shifted.year, shifted.month, shifted.day);
}
