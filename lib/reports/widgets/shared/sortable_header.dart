// lib/reports/widgets/shared/sortable_header.dart
import 'package:etender_reports/shared/app_colors.dart';
import 'package:flutter/material.dart';

/// Column header that advertises it can be sorted.
///
/// The label only. The sort indicator is drawn by `ReportTablePanel`'s
/// `sortArrowBuilder`, in the 16px slot every sortable heading cell reserves
/// whether or not it is the active column.
///
/// This used to draw its own chevron beside that slot, which meant a
/// sortable column spent 34px on arrow furniture and ellipsised its title to
/// pay for it — "Declarations" came out as "Declaration…".
class SortableHeader extends StatelessWidget {
  const SortableHeader(
    this.label, {
    super.key,
    required this.columnIndex,
    required this.activeIndex,
  });

  final String label;

  /// This column's position, matching its entry in the sort column list.
  final int columnIndex;

  /// The column currently sorted, or null when nothing is.
  final int? activeIndex;

  bool get _isActive => activeIndex == columnIndex;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Sort by $label',
      waitDuration: const Duration(milliseconds: 600),
      // Ellipsis is a safety net only: the widths in each table are sized so
      // every title fits. See the note on ReportTablePanel.sortArrowBuilder.
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: _isActive ? const TextStyle(color: AppColors.accent) : null,
      ),
    );
  }
}
