/// Date helpers built on `DateTime(y, m, d + n)`, which rolls over months and
/// years and can't land on the wrong day around daylight-saving changes.
extension DateX on DateTime {
  DateTime get startOfDay => DateTime(year, month, day);
  DateTime addDays(int n) => DateTime(year, month, day + n, hour, minute);

  /// The Monday of this date's week.
  DateTime get startOfWeek => DateTime(year, month, day - (weekday - 1));
  DateTime get startOfMonth => DateTime(year, month);
  int get daysInMonth => DateTime(year, month + 1, 0).day;
  bool isSameDay(DateTime o) =>
      year == o.year && month == o.month && day == o.day;

  /// Minutes since midnight.
  int get minuteOfDay => hour * 60 + minute;
}
