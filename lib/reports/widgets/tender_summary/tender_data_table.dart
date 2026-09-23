// lib/reports/widgets/tender_summary/tender_data_table.dart
import 'package:data_table_2/data_table_2.dart';
import 'package:etender_reports/shared/utils/formatters.dart';
import 'package:flutter/material.dart';

import 'package:etender_reports/reports/models/report_export.dart';
import 'package:etender_reports/reports/models/report_sort_columns.dart';
import 'package:etender_reports/reports/models/tender_status.dart';
import 'package:etender_reports/reports/models/report_sorting.dart';
import 'package:etender_reports/reports/widgets/shared/report_table_panel.dart';
import 'package:etender_reports/reports/widgets/shared/sortable_header.dart';
import 'package:etender_reports/reports/widgets/shared/status_chip.dart';

/// One row per tender/quotation. Columns follow report spec 6.1.
///
/// Sorting is held here rather than in the bloc: tap a header to sort, tap
/// again to reverse.
class TenderDataTable extends StatefulWidget {
  const TenderDataTable({
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

  /// The fourteen fixed columns (2164) + Title's 340 floor + the fourteen
  /// 16px gaps. Past this width Title grows and the table stays full.
  static const double minTableWidth = 2590;

  @override
  State<TenderDataTable> createState() => _TenderDataTableState();
}

class _TenderDataTableState extends State<TenderDataTable> {
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
    columns: tenderSortColumns,
    columnIndex: _sortColumnIndex,
    ascending: _sortAscending,
  );

  /// Green while open, orange once the closing date has been pushed out,
  /// grey once bidding has ended.
  ///
  /// Switching on the enum means an added status is a compile error here
  /// rather than a silently grey chip.
  ChipColors _statusColors(String status) =>
      switch (TenderStatus.fromWire(status)) {
        TenderStatus.published => ChipPalette.green,
        TenderStatus.extended => ChipPalette.orange,
        TenderStatus.closed => ChipPalette.blueGrey,
        null => ChipPalette.grey,
      };

  DataRow _buildRecordRow(Map<String, dynamic> record) {
    final status = record['status'] as String? ?? 'Unknown';

    DataCell cell(dynamic value) => DataCell(
      Text(value?.toString() ?? '', overflow: TextOverflow.ellipsis),
    );

    return DataRow(
      cells: [
        DataCell(
          Text(
            record['referenceNo'] ?? '',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.blue.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        cell(record['tenderNo']),
        cell(record['title']),
        cell(record['tenderCategory']),
        cell(record['division']),
        cell(record['department']),
        cell(record['unit']),
        DataCell(Text(formatValue(record['value']))),
        cell(record['modeOfProcurement']),
        cell(record['envelopeType']),
        cell(record['itemType']),
        cell(formatDateOnly(record['endorsedDate'])),
        cell(formatDateOnly(record['floatingDate'])),
        cell(formatDateOnly(record['closingDate'])),
        DataCell(StatusChip(label: status, colors: _statusColors(status))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ReportTablePanel(
      title: 'Tender / Quotation Records',
      minWidth: TenderDataTable.minTableWidth,
      countLabel: '${widget.records.length} Records',
      fillHeight: widget.fillHeight,
      onExport: widget.onExport,
      isExporting: widget.isExporting,
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _sortAscending,
      emptyMessage: 'No records match your filter criteria.',
      // Division, department, unit, tender value, mode of procurement, the
      // envelope and item split, then the RFC endorsed, floating and closing
      // dates. Audit fields stay in the data for search and export.
      // Only value and date columns are sortable; the rest are
      // plain labels so nothing looks tappable when it is not.
      columns: [
        DataColumn2(label: const Text('Ref No'), fixedWidth: 100),
        DataColumn2(label: const Text('Tender/Quotation No'), fixedWidth: 155),
        // 'Distribution Transformer Supply (Lahad Datu)' is the longest.
        DataColumn2(label: const Text('Title'), fixedWidth: 300),
        DataColumn2(label: const Text('Category'), fixedWidth: 130),
        DataColumn2(label: const Text('Division'), fixedWidth: 135),
        DataColumn2(label: const Text('Department'), fixedWidth: 162),
        DataColumn2(label: const Text('Unit'), fixedWidth: 155),
        DataColumn2(
          label: SortableHeader(
            'Estimated Value (RM)',
            columnIndex: 7,
            activeIndex: _sortColumnIndex,
          ),
          fixedWidth: 178,
          numeric: true,
          onSort: _handleSort,
        ),
        DataColumn2(label: const Text('Mode of Procurement'), fixedWidth: 250),
        DataColumn2(label: const Text('Envelope'), fixedWidth: 90),
        DataColumn2(label: const Text('Item Type'), fixedWidth: 112),
        DataColumn2(
          label: SortableHeader(
            'RFC Endorsed Date',
            columnIndex: 11,
            activeIndex: _sortColumnIndex,
          ),
          fixedWidth: 156,
          onSort: _handleSort,
        ),
        DataColumn2(
          label: SortableHeader(
            'Floating',
            columnIndex: 12,
            activeIndex: _sortColumnIndex,
          ),
          fixedWidth: 95,
          onSort: _handleSort,
        ),
        DataColumn2(
          label: SortableHeader(
            'Tender Closing Date',
            columnIndex: 13,
            activeIndex: _sortColumnIndex,
          ),
          fixedWidth: 170,
          onSort: _handleSort,
        ),
        DataColumn2(label: const Text('Tender Status'), fixedWidth: 140),
      ],
      rows: _sortedRecords.map(_buildRecordRow).toList(),
    );
  }
}
