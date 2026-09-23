// lib/reports/widgets/shared/sortable_header.dart
import 'package:etender_reports/shared/app_colors.dart';
import 'package:flutter/material.dart';

/// Column header that advertises it can be sorted.
///
/// DataTable2 draws an arrow only on the column currently sorted, which
/// leaves every other header looking inert. This adds a faint double chevron
/// to the inactive ones and steps aside on the active one so the real arrow
/// is not doubled up.
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
          if (!_isActive) ...[
            const SizedBox(width: 3),
            Icon(
              Icons.unfold_more,
              size: 13,
              color: AppColors.tableHeadingText.withValues(alpha: 0.45),
            ),
          ],
        ],
      ),
    );
  }
}
