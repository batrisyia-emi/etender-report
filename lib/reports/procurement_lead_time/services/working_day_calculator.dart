// lib/reports/procurement_lead_time/services/working_day_calculator.dart

/// Counts working days between two dates, inclusive of both ends.
///
/// Saturdays, Sundays and [holidays] are not working days. Only the
/// calendar date counts; the time of day is ignored.
class WorkingDayCalculator {
  /// [holidays] come from the repository so they can be maintained as data.
  /// Any time of day on them is ignored.
  WorkingDayCalculator({Set<DateTime> holidays = const {}})
    : _holidays = {for (final day in holidays) _dateOnly(day)};

  final Set<DateTime> _holidays;

  /// UTC midnight, so a daylight-saving change cannot make a day 23 or 25
  /// hours long and throw the stepping out.
  static DateTime _dateOnly(DateTime value) =>
      DateTime.utc(value.year, value.month, value.day);

  bool isWorkingDay(DateTime date) {
    final day = _dateOnly(date);
    return day.weekday != DateTime.saturday &&
        day.weekday != DateTime.sunday &&
        !_holidays.contains(day);
  }

  /// Working days from [start] to [end], both counted.
  ///
  /// Same working day = 1. When [start] is not a working day, Day 1 is the
  /// next one. Returns 0 when [end] comes before that Day 1.
  int count(DateTime start, DateTime end) {
    final last = _dateOnly(end);
    var day = _dateOnly(start);
    var total = 0;
    while (!day.isAfter(last)) {
      if (isWorkingDay(day)) total++;
      day = day.add(const Duration(days: 1));
    }
    return total;
  }
}
