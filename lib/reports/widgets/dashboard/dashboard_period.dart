// lib/reports/widgets/dashboard/dashboard_period.dart
//
// The period strip both dashboards sit under, and the windows it selects.
//
// These lived in se_toc_opening_dashboard.dart, which made the supplier
// dashboard import an SE report's file to draw its own header. They are not
// SE's: every dashboard tab on both sides uses them, so they belong beside
// DashTabs and DashCard rather than inside one tab's widget.
import 'package:etender_reports/reports/widgets/dashboard/dashboard_scroll.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_theme.dart';
import 'package:flutter/material.dart';

/// How far back a screen is looking.
///
/// Carries its own window rather than a month count, because the short
/// periods are not months: "today" is one day and "this week" runs from
/// Monday. Every screen asking the same enum is what keeps a figure on one
/// tab comparable with the same figure on another.
enum DashPeriod {
  today(label: 'Today'),
  thisWeek(label: 'This Week'),
  thisMonth(label: 'This Month'),
  threeMonths(label: '3 Months', months: 3),
  sixMonths(label: '6 Months', months: 6),
  nineMonths(label: '9 Months', months: 9),
  twelveMonths(label: '12 Months', months: 12);

  const DashPeriod({required this.label, this.months});

  final String label;

  /// Whole months ending with the current one, for the longer periods.
  /// Null for the three short ones, which are not month-shaped.
  final int? months;

  /// The window, inclusive at both ends and normalised to whole days.
  ///
  /// Whole days on purpose: a record closing at 17:00 today belongs to
  /// today, and comparing raw timestamps would drop it.
  DateTimeRange range({DateTime? asOf}) {
    final now = asOf ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return switch (this) {
      DashPeriod.today => DateTimeRange(start: today, end: today),
      // Monday to Sunday around today. weekday is 1 on Monday, so this
      // lands on Monday whatever day it is run.
      DashPeriod.thisWeek => DateTimeRange(
        start: today.subtract(Duration(days: now.weekday - 1)),
        end: today.add(Duration(days: DateTime.daysPerWeek - now.weekday)),
      ),
      DashPeriod.thisMonth => DateTimeRange(
        start: DateTime(now.year, now.month),
        end: _lastDayOfMonth(now),
      ),
      _ => DateTimeRange(
        start: DateTime(now.year, now.month - months! + 1),
        end: _lastDayOfMonth(now),
      ),
    };
  }

  /// Whether [date] falls inside this period. Null never does.
  ///
  /// Every screen used to re-derive this from a month count, six times over.
  bool contains(DateTime? date, {DateTime? asOf}) {
    if (date == null) return false;
    final window = range(asOf: asOf);
    final day = DateTime(date.year, date.month, date.day);
    return !day.isBefore(window.start) && !day.isAfter(window.end);
  }

  /// What the strip says on the right, e.g. "Showing October 2026".
  String describe({DateTime? asOf}) {
    final window = range(asOf: asOf);
    return switch (this) {
      DashPeriod.today => dashDayLabel(window.start),
      DashPeriod.thisWeek =>
        '${dashDayLabel(window.start)} – ${dashDayLabel(window.end)}',
      _ => dashPeriodLabel(
        window.start,
        window.end.add(const Duration(days: 1)),
      ),
    };
  }
}

DateTime _lastDayOfMonth(DateTime now) =>
    DateTime(now.year, now.month + 1).subtract(const Duration(days: 1));

class DashPeriodSelector extends StatelessWidget {
  const DashPeriodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.asOf,
  });

  final DashPeriod selected;
  final ValueChanged<DashPeriod> onChanged;

  /// Injectable so a test is not at the mercy of the clock.
  final DateTime? asOf;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    runSpacing: 10,
    children: [
      Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: DashTheme.card,
          border: Border.all(color: DashTheme.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DashHorizontalScroll(
          barSpace: 8,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final period in DashPeriod.values)
                DashPeriodButton(
                  label: period.label,
                  selected: period == selected,
                  onTap: () => onChanged(period),
                ),
            ],
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: DashTheme.muted,
            ),
            const SizedBox(width: 8),
            Text(
              'Showing ${selected.describe(asOf: asOf)}',
              style: const TextStyle(color: DashTheme.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    ],
  );
}

class DashPeriodButton extends StatelessWidget {
  const DashPeriodButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? DashTheme.accent : Colors.transparent,
    borderRadius: BorderRadius.circular(6),
    child: InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : DashTheme.text,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    ),
  );
}

String dashMonthName(int month) => const [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
][month - 1];

/// "07 Oct 2026".
String dashDayLabel(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')} '
    '${dashMonthName(date.month).substring(0, 3)} ${date.year}';

/// "Sep 2026" for a single month, "Jul 2026-Sep 2026" for a longer window.
///
/// [exclusiveEnd] is the first instant *after* the window, which is how the
/// dashboards build their ranges — so the label counts back a day to name
/// the month a reader would call the last one.
String dashPeriodLabel(DateTime start, DateTime exclusiveEnd) {
  final lastMonth = exclusiveEnd.subtract(const Duration(days: 1));
  final first = '${dashMonthName(start.month).substring(0, 3)} ${start.year}';
  final last =
      '${dashMonthName(lastMonth.month).substring(0, 3)} '
      '${lastMonth.year}';
  return start.year == lastMonth.year && start.month == lastMonth.month
      ? last
      : '$first-$last';
}
