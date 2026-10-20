// lib/reports/procurement_lead_time/services/period_resolver.dart
import 'package:etender_reports/reports/procurement_lead_time/lead_time_rules.dart';
import 'package:etender_reports/reports/procurement_lead_time/models/period_preset.dart';
import 'package:flutter/material.dart' show DateTimeRange;

/// Turns a [PeriodPreset] into the published dates it covers.
class PeriodResolver {
  const PeriodResolver._();

  /// The date range [preset] covers as of [today], both ends inclusive and
  /// at midnight. Null for [PeriodPreset.custom], whose dates are the
  /// user's own.
  ///
  /// Pure: [today] is passed in rather than read from the clock. Month ends,
  /// leap years and year boundaries all come from `DateTime`'s own
  /// normalisation: day 0 of a month is the last day of the one before, and
  /// month 0 or below rolls back into the previous year.
  static DateTimeRange? resolve(
    PeriodPreset preset, {
    required DateTime today,
    int fyStartMonth = LeadTimeRules.fyStartMonth,
  }) {
    if (fyStartMonth < 1 || fyStartMonth > 12) {
      throw ArgumentError.value(fyStartMonth, 'fyStartMonth', 'must be 1–12');
    }

    final day = DateTime(today.year, today.month, today.day);
    final year = day.year;
    final month = day.month;

    // How far the current month is into the financial year (0–11), and into
    // its financial quarter (0–2).
    final monthsIntoYear = (month - fyStartMonth) % 12;
    final monthsIntoQuarter = monthsIntoYear % 3;
    final quarterStart = DateTime(year, month - monthsIntoQuarter);

    DateTimeRange range(DateTime start, DateTime end) =>
        DateTimeRange(start: start, end: end);

    return switch (preset) {
      PeriodPreset.lastMonth => range(
        DateTime(year, month - 1),
        DateTime(year, month, 0),
      ),
      PeriodPreset.thisMonth => range(DateTime(year, month), day),
      PeriodPreset.lastQuarter => range(
        DateTime(quarterStart.year, quarterStart.month - 3),
        DateTime(quarterStart.year, quarterStart.month, 0),
      ),
      PeriodPreset.thisQuarter => range(quarterStart, day),
      PeriodPreset.yearToDate => range(
        DateTime(year, month - monthsIntoYear),
        day,
      ),
      // Twelve whole months, leaving out the one in progress.
      PeriodPreset.last12Months => range(
        DateTime(year, month - 12),
        DateTime(year, month, 0),
      ),
      PeriodPreset.custom => null,
    };
  }
}
