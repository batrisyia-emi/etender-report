// lib/reports/widgets/shared/report_timeline_filter.dart
//
// The same timeline control the dashboards use, on the reports.
//
// It does not introduce a second way to filter by date. The buttons are
// presets over the date range the report already filters on: pressing
// "This Week" sets that range, and the panel's own date field shows the
// dates it set. Two controls, one piece of state, so they cannot disagree.
//
// Reports differ from the dashboards in one way: a dashboard opens on the
// current month, a report opens on everything. A report that quietly hid
// last month's rows would be wrong in a way nobody would notice, so "All"
// leads and is the default.
import 'package:etender_reports/reports/widgets/dashboard/dashboard_period.dart';
import 'package:etender_reports/shared/app_colors.dart';
import 'package:flutter/material.dart';

/// The window a period covers, as a filter range.
///
/// Delegates to [DashPeriod] so a report and a dashboard asking for "This
/// Week" are asking the same question.
DateTimeRange periodRange(DashPeriod period, {DateTime? asOf}) =>
    period.range(asOf: asOf);

/// Which preset [range] corresponds to, or null when it is a custom range
/// or none at all.
///
/// Derived rather than remembered: the range is the single source of truth,
/// so clearing the filters or picking dates by hand leaves the buttons
/// honest without anything having to be kept in step.
DashPeriod? periodOf(DateTimeRange? range, {DateTime? asOf}) {
  if (range == null) return null;
  for (final period in DashPeriod.values) {
    final candidate = period.range(asOf: asOf);
    if (_sameDay(candidate.start, range.start) &&
        _sameDay(candidate.end, range.end)) {
      return period;
    }
  }
  return null;
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class ReportTimelineFilter extends StatelessWidget {
  const ReportTimelineFilter({
    super.key,
    required this.label,
    required this.selectedRange,
    required this.onChanged,
    this.asOf,
  });

  /// Which date the periods apply to, e.g. 'Closing date'. Named because
  /// every report filters on a different one.
  final String label;

  final DateTimeRange? selectedRange;

  /// Null clears the date filter back to everything.
  final ValueChanged<DateTimeRange?> onChanged;

  /// Injectable so a test is not at the mercy of the clock.
  final DateTime? asOf;

  @override
  Widget build(BuildContext context) {
    final selected = periodOf(selectedRange, asOf: asOf);
    final custom = selectedRange != null && selected == null;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppColors.muted,
          ),
        ),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DashPeriodButton(
                label: 'All',
                selected: selectedRange == null,
                onTap: () => onChanged(null),
              ),
              for (final period in DashPeriod.values)
                DashPeriodButton(
                  label: period.label,
                  selected: selected == period,
                  onTap: () => onChanged(period.range(asOf: asOf)),
                ),
            ],
          ),
        ),
        // Says why no button is lit, rather than leaving the row looking
        // broken when someone picks dates by hand.
        if (custom)
          const Text(
            'Custom range set in the filters',
            style: TextStyle(fontSize: 11, color: AppColors.muted),
          ),
      ],
    );
  }
}
