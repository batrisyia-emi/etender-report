// lib/reports/widgets/report_table_panel.dart
import 'package:data_table_2/data_table_2.dart';
import 'package:etender_reports/shared/app_colors.dart';
import 'package:etender_reports/shared/widgets/export_menu.dart';
import 'package:flutter/material.dart';

import 'package:etender_reports/reports/models/report_export.dart';
import 'package:etender_reports/reports/widgets/shared/report_panel.dart';

/// Everything the three report tables had in common: the panel frame, the
/// count pill, the DataTable2 configuration, the table and scrollbar themes,
/// the two scroll controllers, and the bounded-height rules.
///
/// A table using this supplies only its columns, its rows and its minimum
/// width.
class ReportTablePanel extends StatefulWidget {
  const ReportTablePanel({
    super.key,
    required this.title,
    required this.countLabel,
    required this.minWidth,
    required this.columns,
    required this.rows,
    required this.emptyMessage,
    this.fillHeight = false,
    this.onExport,
    this.isExporting = false,
    this.sortColumnIndex,
    this.sortAscending = true,
  });

  final String title;
  final String countLabel;

  /// Width below which the table scrolls horizontally instead of compressing.
  final double minWidth;

  final List<DataColumn> columns;
  final List<DataRow> rows;
  final String emptyMessage;

  /// When true the rows scroll inside the height the parent gives; the parent
  /// must supply a bounded height (e.g. via Expanded).
  final bool fillHeight;

  /// Shows an Export menu in the header when provided.
  final ValueChanged<ExportFormat>? onExport;

  /// Disables the menu and shows a spinner while a file is being written.
  final bool isExporting;

  /// Which column carries the sort arrow, and which way it points. The rows
  /// arrive already sorted; these only drive the header indicator.
  final int? sortColumnIndex;
  final bool sortAscending;

  static const double headingHeight = 36;
  static const double rowHeight = 40;

  /// Cap for the unpinned layout, so a long list does not push the page down
  /// forever.
  static const double maxUnpinnedHeight = 560;

  @override
  State<ReportTablePanel> createState() => _ReportTablePanelState();
}

class _ReportTablePanelState extends State<ReportTablePanel> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themedTable = Theme(
      data: Theme.of(context).copyWith(
        dividerColor: AppColors.divider,
        dataTableTheme: const DataTableThemeData(
          headingRowColor: WidgetStatePropertyAll(
            AppColors.tableHeadingBackground,
          ),
          headingTextStyle: TextStyle(
            color: AppColors.tableHeadingText,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          dataTextStyle: TextStyle(
            color: AppColors.tableBodyText,
            fontSize: 12,
          ),
        ),
        scrollbarTheme: ScrollbarThemeData(
          thickness: const WidgetStatePropertyAll(8),
          radius: const Radius.circular(4),
          // crossAxisMargin insets each bar from the edge it sits on.
          // mainAxisMargin stops the two bars meeting in the corner, which
          // is where they were overlapping.
          crossAxisMargin: 0,
          mainAxisMargin: 10,
          thumbColor: WidgetStatePropertyAll(
            AppColors.accent.withValues(alpha: 0.45),
          ),
          trackColor: const WidgetStatePropertyAll(
            AppColors.tableHeadingBackground,
          ),
          trackBorderColor: const WidgetStatePropertyAll(AppColors.divider),
        ),
      ),
      // The scrollbar's own crossAxisMargin plus the table's right
      // horizontalMargin are enough of a gutter; extra padding here just
      // left dead space beside the last column.
      child: DataTable2(
        // Freezes the heading row while the rows scroll under it.
        fixedTopRows: 1,
        minWidth: widget.minWidth,
        sortColumnIndex: widget.sortColumnIndex,
        sortAscending: widget.sortAscending,
        // Keeps the arrow beside the label instead of centring the header.
        sortArrowIcon: Icons.arrow_drop_up,
        headingRowHeight: ReportTablePanel.headingHeight,
        dataRowHeight: ReportTablePanel.rowHeight,
        // The wider right margin is the gutter the vertical thumb sits in,
        // so it no longer overlaps the last column.
        horizontalMargin: 12,
        columnSpacing: 16,
        bottomMargin: 18,
        scrollController: _verticalController,
        horizontalScrollController: _horizontalController,
        isVerticalScrollBarVisible: true,
        isHorizontalScrollBarVisible: true,
        border: const TableBorder(
          horizontalInside: BorderSide(color: AppColors.divider, width: 1),
        ),
        empty: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(child: Text(widget.emptyMessage)),
        ),
        columns: widget.columns,
        rows: widget.rows,
      ),
    );

    // DataTable2 scrolls internally, so it always needs a bounded height:
    // Expanded when the page is pinned, a capped box when the page scrolls.
    final unpinnedHeight =
        (ReportTablePanel.headingHeight +
                ReportTablePanel.rowHeight * widget.rows.length +
                24)
            .clamp(180.0, ReportTablePanel.maxUnpinnedHeight);

    return ReportPanel(
      title: widget.title,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.onExport != null) ...[
            ExportMenu(
              onExport: widget.onExport!,
              isExporting: widget.isExporting,
            ),
            const SizedBox(width: 8),
          ],
          ReportCountPill(label: widget.countLabel),
        ],
      ),
      fillHeight: widget.fillHeight,
      child: widget.fillHeight
          ? themedTable
          : SizedBox(height: unpinnedHeight, child: themedTable),
    );
  }
}
