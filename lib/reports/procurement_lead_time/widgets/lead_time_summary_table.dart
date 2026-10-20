// lib/reports/procurement_lead_time/widgets/lead_time_summary_table.dart
import 'package:data_table_2/data_table_2.dart';
import 'package:etender_reports/reports/procurement_lead_time/lead_time_rules.dart';
import 'package:etender_reports/reports/procurement_lead_time/models/lead_time_summary.dart';
import 'package:etender_reports/reports/widgets/shared/report_table_panel.dart';
import 'package:flutter/material.dart';

/// Activities × bands: 'Published (Number)' and 'Published (%)' for one
/// document type.
/// Each band's count opens that band in the drill-down.
class LeadTimeSummaryTable extends StatelessWidget {
  const LeadTimeSummaryTable({
    super.key,
    required this.summary,
    required this.selectedBucket,
    required this.onBucketSelected,
  });

  final LeadTimeSummary summary;

  /// The band the drill-down is showing, when it is showing this summary.
  final LeadTimeBucket? selectedBucket;

  final ValueChanged<LeadTimeBucket> onBucketSelected;

  static const double _activityWidth = 150;
  static const double _bucketWidth = 170;
  static const double _totalWidth = 100;

  /// The five column widths, their four 16px gaps and the 12px side margins.
  static const double _minWidth =
      _activityWidth + 3 * _bucketWidth + _totalWidth + 4 * 16 + 2 * 12;

  @override
  Widget build(BuildContext context) {
    return ReportTablePanel(
      // No header of its own: LeadTimeSummarySection frames it with the
      // document type and count.
      title: null,
      countLabel: '${summary.total} tenders',
      minWidth: _minWidth,
      emptyMessage: 'Nothing published.',
      shrinkToRows: true,
      columns: [
        const DataColumn2(
          label: Text('Activities'),
          fixedWidth: _activityWidth,
        ),
        for (final bucket in LeadTimeRules.buckets)
          // Not fixed: the three bands share whatever width the panel
          // has beyond the two fixed columns, so the table fills it.
          // [_bucketWidth] is only their floor, via [_minWidth].
          DataColumn2(
            label: Text(bucket.label),
            size: ColumnSize.M,
            numeric: true,
          ),
        const DataColumn2(
          label: Text('Total'),
          fixedWidth: _totalWidth,
          numeric: true,
        ),
      ],
      rows: [
        DataRow(
          cells: [
            const DataCell(Text('Published (Number)')),
            for (final bucket in LeadTimeRules.buckets)
              DataCell(
                _CountButton(
                  count: summary.countIn(bucket),
                  selected: selectedBucket?.key == bucket.key,
                  onPressed: () => onBucketSelected(bucket),
                  tooltip:
                      'Show ${summary.documentType.label} '
                      'published in ${bucket.label}',
                ),
              ),
            DataCell(Text('${summary.total}')),
          ],
        ),
        DataRow(
          cells: [
            const DataCell(Text('Published (%)')),
            for (final bucket in LeadTimeRules.buckets)
              DataCell(Text(summary.percentIn(bucket).toStringAsFixed(2))),
            DataCell(Text(summary.totalPercent.toStringAsFixed(2))),
          ],
        ),
      ],
    );
  }
}

/// A count that reads as a link, and stays highlighted while its band is
/// the one drilled into.
class _CountButton extends StatelessWidget {
  const _CountButton({
    required this.count,
    required this.selected,
    required this.onPressed,
    required this.tooltip,
  });

  final int count;
  final bool selected;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.compact,
          minimumSize: const Size(40, 28),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: selected ? scheme.primaryContainer : null,
          foregroundColor: selected
              ? scheme.onPrimaryContainer
              : scheme.primary,
        ),
        child: Text(
          '$count',
          style: TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}
