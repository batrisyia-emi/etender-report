// lib/reports/widgets/supplier/supplier_report_table.dart
import 'package:data_table_2/data_table_2.dart';
import 'package:etender_reports/shared/utils/formatters.dart';
import 'package:flutter/material.dart';

import 'package:etender_reports/reports/models/report_export.dart';
import 'package:etender_reports/reports/models/report_sort_columns.dart';
import 'package:etender_reports/reports/models/report_sorting.dart';
import 'package:etender_reports/reports/models/supplier_metrics.dart';
import 'package:etender_reports/reports/models/supplier_status.dart';
import 'package:etender_reports/reports/widgets/shared/report_table_panel.dart';
import 'package:etender_reports/reports/widgets/shared/sortable_header.dart';
import 'package:etender_reports/reports/widgets/shared/status_chip.dart';

/// One row per supplier per tender: Tender/Quotation No, Title, Category,
/// Supplier, Published, Requested, Decision, Document Fee, Closing, Bid
/// Amount, Current Status, Days to Close.
///
/// Sorting is held here rather than in the bloc: tap a header to sort, tap
/// again to reverse. Nothing outside this widget needs wiring.
class SupplierReportTable extends StatefulWidget {
  const SupplierReportTable({
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
  /// margins. Below this the status chips and the date columns ellipsise.
  static const double minTableWidth = 1811;

  @override
  State<SupplierReportTable> createState() => _SupplierReportTableState();
}

class _SupplierReportTableState extends State<SupplierReportTable> {
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
    columns: supplierSortColumns,
    columnIndex: _sortColumnIndex,
    ascending: _sortAscending,
  );

  /// All three rejections share red: which gate turned the request back
  /// matters less at a glance than the fact that it is out of the running.
  ///
  /// Switching on the enum means an added status is a compile error here
  /// rather than a silently grey chip.
  ChipColors _statusColors(String status) =>
      switch (SupplierStatus.fromWire(status)) {
        SupplierStatus.published => ChipPalette.blue,
        SupplierStatus.participationRequested ||
        SupplierStatus.submitted => ChipPalette.indigo,
        SupplierStatus.draft => ChipPalette.grey,
        SupplierStatus.requestApproved ||
        SupplierStatus.paid ||
        SupplierStatus.participated => ChipPalette.green,
        // The one status that asks the supplier to act.
        SupplierStatus.pendingPayment => ChipPalette.orange,
        SupplierStatus.requestRejected => ChipPalette.red,
        SupplierStatus.noParticipate => ChipPalette.blueGrey,
        null => ChipPalette.grey,
      };

  /// Amber as the deadline nears, grey once the supplier is out of the
  /// running or the date has passed.
  Widget _buildDaysToCloseCell(Map<String, dynamic> record) {
    final days = supplierDaysToClosing(record);
    if (days == null) return const Text('—');

    final urgent = days <= kSupplierClosingSoonDays;
    final color = urgent ? Colors.orange.shade800 : const Color(0xFF6B7280);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (urgent) ...[
          Icon(Icons.schedule, size: 15, color: color),
          const SizedBox(width: 4),
        ],
        Text(
          '$days',
          style: TextStyle(
            color: color,
            fontWeight: urgent ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  DataRow _buildRecordRow(Map<String, dynamic> record) {
    final status = record['status'] as String? ?? 'Unknown';

    DataCell cell(dynamic value) => DataCell(
      Text(value?.toString() ?? '', overflow: TextOverflow.ellipsis),
    );

    return DataRow(
      cells: [
        DataCell(
          Text(
            record['tenderNo'] ?? '',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.blue.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        cell(record['title']),
        cell(record['tenderCategory']),
        cell(formatDateOnly(record['publishedDate'])),
        cell(formatDateOnly(record['requestDate'])),
        cell(formatDateOnly(record['decisionDate'])),
        DataCell(Text(formatValue(record['documentFee']))),
        cell(formatDateOnly(record['closingDate'])),
        // A bid amount of zero means no bid yet, not a free one.
        DataCell(
          Text(
            (double.tryParse(record['bidAmount']?.toString() ?? '') ?? 0) == 0
                ? '—'
                : formatValue(record['bidAmount']),
          ),
        ),
        DataCell(StatusChip(label: status, colors: _statusColors(status))),
        DataCell(_buildDaysToCloseCell(record)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ReportTablePanel(
      title: 'My Participation Records',
      minWidth: SupplierReportTable.minTableWidth,
      countLabel: '${widget.records.length} records',
      fillHeight: widget.fillHeight,
      onExport: widget.onExport,
      isExporting: widget.isExporting,
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _sortAscending,
      emptyMessage: 'No records match your filter criteria.',
      // Only value and date columns are sortable; the rest are plain labels
      // so nothing looks tappable when it is not.
      columns: [
        DataColumn2(label: const Text('Tender/Quotation No'), fixedWidth: 155),
        // The three text columns are flexible, so spare window width is
        // shared between them rather than left dead past the last column.
        DataColumn2(label: const Text('Title'), fixedWidth: 300),
        DataColumn2(label: const Text('Category'), fixedWidth: 130),
        DataColumn2(
          label: SortableHeader(
            'Published',
            columnIndex: 3,
            activeIndex: _sortColumnIndex,
          ),
          fixedWidth: 105,
          onSort: _handleSort,
        ),
        DataColumn2(
          label: SortableHeader(
            'Requested',
            columnIndex: 4,
            activeIndex: _sortColumnIndex,
          ),
          fixedWidth: 105,
          onSort: _handleSort,
        ),
        DataColumn2(
          label: SortableHeader(
            'Decision',
            columnIndex: 5,
            activeIndex: _sortColumnIndex,
          ),
          fixedWidth: 105,
          onSort: _handleSort,
        ),
        DataColumn2(
          label: SortableHeader(
            'Doc Fee (RM)',
            columnIndex: 6,
            activeIndex: _sortColumnIndex,
          ),
          fixedWidth: 130,
          numeric: true,
          onSort: _handleSort,
        ),
        DataColumn2(
          label: SortableHeader(
            'Closing',
            columnIndex: 7,
            activeIndex: _sortColumnIndex,
          ),
          fixedWidth: 105,
          onSort: _handleSort,
        ),
        DataColumn2(
          label: SortableHeader(
            'Bid Amount (RM)',
            columnIndex: 8,
            activeIndex: _sortColumnIndex,
          ),
          fixedWidth: 150,
          numeric: true,
          onSort: _handleSort,
        ),
        // 'Participation Requested' is the longest status; below this the
        // chip was ellipsised on every requested row.
        DataColumn2(label: const Text('Current Status'), fixedWidth: 190),
        // Room for the schedule icon beside a three-digit count.
        DataColumn2(label: const Text('Days to Close'), fixedWidth: 152),
      ],
      rows: _sortedRecords.map(_buildRecordRow).toList(),
    );
  }
}
