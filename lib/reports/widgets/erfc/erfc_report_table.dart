// lib/reports/widgets/erfc/erfc_report_table.dart
import 'package:data_table_2/data_table_2.dart';
import 'package:etender_reports/shared/utils/formatters.dart';
import 'package:flutter/material.dart';

import 'package:etender_reports/reports/models/erfc_metrics.dart';
import 'package:etender_reports/reports/models/erfc_status.dart';
import 'package:etender_reports/reports/models/report_export.dart';
import 'package:etender_reports/reports/models/report_sort_columns.dart';
import 'package:etender_reports/reports/models/report_sorting.dart';
import 'package:etender_reports/reports/widgets/shared/report_table_panel.dart';
import 'package:etender_reports/reports/widgets/shared/sortable_header.dart';
import 'package:etender_reports/reports/widgets/shared/status_chip.dart';

/// One row per RFC: RFC Number, Division/Dept, Unit, Mode of Procurement,
/// Value (RM), Submission Date, Verified 1, Verified 2, Endorsed Date,
/// Current Status, Aging (days).
///
/// Sorting is held here rather than in the bloc: tap a header to sort, tap
/// again to reverse. Nothing outside this widget needs wiring.
class ErfcReportTable extends StatefulWidget {
  const ErfcReportTable({
    super.key,
    required this.records,
    this.fillHeight = false,
    this.onExport,
    this.isExporting = false,
  });

  final List<Map<String, dynamic>> records;

  /// When true the rows scroll inside the height the parent gives.
  final bool fillHeight;

  /// Shows the Export menu in the panel header when provided.
  final ValueChanged<ExportFormat>? onExport;
  final bool isExporting;

  /// The eleven columns plus their ten 16px gaps and the table's own
  /// margins. Below this Division / Dept and the status chip ellipsise.
  static const double minTableWidth = 1975;

  @override
  State<ErfcReportTable> createState() => _ErfcReportTableState();
}

class _ErfcReportTableState extends State<ErfcReportTable> {
  int? _sortColumnIndex;
  bool _sortAscending = true;

  void _handleSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  List<Map<String, dynamic>> get _sortedRecords => sortRecords(
    rows: widget.records,
    columns: erfcSortColumns,
    columnIndex: _sortColumnIndex,
    ascending: _sortAscending,
  );

  /// All three rejections share red: which gate turned the RFC back matters
  /// less at a glance than the fact that it is out of the running.
  ///
  /// Switching on the enum means an added status is a compile error here
  /// rather than a silently grey chip.
  ChipColors _statusColors(String status) => switch (ErfcStatus.fromWire(
    status,
  )) {
    ErfcStatus.draft => ChipPalette.grey,
    ErfcStatus.submitted => ChipPalette.blue,
    ErfcStatus.firstVerified || ErfcStatus.secondVerified => ChipPalette.indigo,
    ErfcStatus.endorsed => ChipPalette.green,
    // Cleared endorsement but still working through the publishing steps.
    ErfcStatus.paperworkReceived ||
    ErfcStatus.erfcCompleted ||
    ErfcStatus.confirmedToPublish => ChipPalette.orange,
    ErfcStatus.rejectedByFirstVerifier ||
    ErfcStatus.rejectedBySecondVerifier ||
    ErfcStatus.rejectedByEndorser ||
    ErfcStatus.decline => ChipPalette.red,
    ErfcStatus.cancelled || ErfcStatus.closedBySystem => ChipPalette.blueGrey,
    null => ChipPalette.grey,
  };

  /// Grey once the RFC is finished, amber while it is still in flight, red
  /// with a warning icon once it is past the overdue threshold.
  Widget _buildAgingCell(Map<String, dynamic> record) {
    final aging = erfcAgingDays(record);
    if (aging == null) return const Text('—');

    final overdue = erfcIsOverdue(record);
    final terminal = erfcIsTerminal(record);
    final color = overdue
        ? Colors.red.shade700
        : terminal
        ? const Color(0xFF6B7280)
        : Colors.orange.shade800;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (overdue) ...[
          Icon(Icons.warning_amber_rounded, size: 15, color: color),
          const SizedBox(width: 4),
        ],
        Text(
          '$aging',
          style: TextStyle(
            color: color,
            fontWeight: overdue ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  DataRow _buildRecordRow(Map<String, dynamic> record) {
    final status = record['status'] as String? ?? 'Unknown';
    final division = record['division'] as String? ?? '';
    final department = record['department'] as String? ?? '';

    DataCell cell(dynamic value) => DataCell(
      Text(value?.toString() ?? '', overflow: TextOverflow.ellipsis),
    );

    return DataRow(
      cells: [
        DataCell(
          Text(
            record['rfcNumber'] ?? '',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.blue.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        cell(department.isEmpty ? division : '$division / $department'),
        cell(record['unit']),
        cell(record['modeOfProcurement']),
        DataCell(Text(formatValue(record['value']))),
        cell(formatDateOnly(record['submissionDate'])),
        cell(formatDateOnly(record['verified1Date'])),
        cell(formatDateOnly(record['verified2Date'])),
        cell(formatDateOnly(record['endorsedDate'])),
        DataCell(StatusChip(label: status, colors: _statusColors(status))),
        DataCell(_buildAgingCell(record)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ReportTablePanel(
      title: 'eRFC Lifecycle Records',
      minWidth: ErfcReportTable.minTableWidth,
      countLabel: '${widget.records.length} RFCs',
      fillHeight: widget.fillHeight,
      onExport: widget.onExport,
      isExporting: widget.isExporting,
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _sortAscending,
      emptyMessage: 'No RFCs match your filter criteria.',
      // Only value and date columns are sortable; the rest are
      // plain labels so nothing looks tappable when it is not.
      columns: [
        DataColumn2(label: const Text('RFC Number'), fixedWidth: 175),
        // The three text columns are flexible, so spare window width is
        // shared between them rather than left dead past the last column.
        // Splitting it three ways keeps any one of them from ballooning the
        // way a single flexible column does. Proportional sizing keeps
        // each still clears its longest value: 296 for Division / Dept (43
        // characters), 247 for Mode of Procurement (36), 247 for Unit (21).
        DataColumn2(label: const Text('Division / Dept'), fixedWidth: 260),
        DataColumn2(label: const Text('Unit'), fixedWidth: 165),
        DataColumn2(label: const Text('Mode of Procurement'), fixedWidth: 250),
        DataColumn2(
          label: SortableHeader(
            'Estimated Value (RM)',
            columnIndex: 4,
            activeIndex: _sortColumnIndex,
          ),
          fixedWidth: 160,
          numeric: true,
          onSort: _handleSort,
        ),
        DataColumn2(
          label: SortableHeader(
            'Submitted',
            columnIndex: 5,
            activeIndex: _sortColumnIndex,
          ),
          fixedWidth: 105,
          onSort: _handleSort,
        ),
        DataColumn2(
          label: SortableHeader(
            'Verified 1',
            columnIndex: 6,
            activeIndex: _sortColumnIndex,
          ),
          fixedWidth: 105,
          onSort: _handleSort,
        ),
        DataColumn2(
          label: SortableHeader(
            'Verified 2',
            columnIndex: 7,
            activeIndex: _sortColumnIndex,
          ),
          fixedWidth: 105,
          onSort: _handleSort,
        ),
        DataColumn2(
          label: SortableHeader(
            'Endorsed',
            columnIndex: 8,
            activeIndex: _sortColumnIndex,
          ),
          fixedWidth: 105,
          onSort: _handleSort,
        ),
        // 'System Cancelled' is the longest status; at 122 the chip was
        // ellipsised on every cancelled row.
        DataColumn2(label: const Text('Current Status'), fixedWidth: 190),
        // Room for the overdue warning icon beside a three-digit count.
        DataColumn2(label: const Text('Aging'), fixedWidth: 171),
      ],
      rows: _sortedRecords.map(_buildRecordRow).toList(),
    );
  }
}
