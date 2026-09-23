// lib/reports/widgets/vendor_participation/vendor_participation_table.dart
import 'package:data_table_2/data_table_2.dart';
import 'package:etender_reports/shared/utils/formatters.dart';
import 'package:flutter/material.dart';

import 'package:etender_reports/reports/models/open_to.dart';
import 'package:etender_reports/reports/models/report_export.dart';
import 'package:etender_reports/reports/models/report_sort_columns.dart';
import 'package:etender_reports/reports/models/report_sorting.dart';
import 'package:etender_reports/reports/widgets/shared/report_table_panel.dart';
import 'package:etender_reports/reports/widgets/shared/sortable_header.dart';
import 'package:etender_reports/reports/widgets/shared/status_chip.dart';

/// One row per vendor per tender/quotation: Tender/Quotation ID, Vendor
/// Name, Invitation Status, Document Purchased, Participation, Submission
/// Status, Submission Date & Time, Open To, Vendor Certification Type.
///
/// Sorting is held here rather than in the bloc: tap a header to sort, tap
/// again to reverse.
class VendorParticipationTable extends StatefulWidget {
  const VendorParticipationTable({
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

  /// The nine columns plus their eight 16px gaps and the table's own
  /// margins. Below this the certification type ellipsises.
  static const double minTableWidth = 1826;

  @override
  State<VendorParticipationTable> createState() =>
      _VendorParticipationTableState();
}

class _VendorParticipationTableState extends State<VendorParticipationTable> {
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
    columns: vendorSortColumns,
    columnIndex: _sortColumnIndex,
    ascending: _sortAscending,
  );

  ChipColors _invitationColors(String value) =>
      value == 'Sent' ? ChipPalette.green : ChipPalette.grey;

  ChipColors _participationColors(String value) =>
      value == 'Participated' ? ChipPalette.green : ChipPalette.red;

  ChipColors _submissionColors(String value) => switch (value) {
    'Submitted' => ChipPalette.green,
    'Late' => ChipPalette.orange,
    _ => ChipPalette.grey,
  };

  ChipColors _openToColors(String value) => switch (value) {
    'Bumiputera Only' => ChipPalette.green,
    'Registered Suppliers' => ChipPalette.blue,
    _ => ChipPalette.grey,
  };

  DataRow _buildRecordRow(Map<String, dynamic> record) {
    final invitationStatus = record['invitationStatus'] as String? ?? 'Unknown';
    final participationStatus =
        record['participationStatus'] as String? ?? 'Unknown';
    final submissionStatus = record['submissionStatus'] as String? ?? 'Unknown';
    final openTo = record['openTo'] as String? ?? 'Unknown';
    final openToLabel = OpenTo.labelFor(openTo);
    final purchased = record['documentPurchased'] == true;
    final submissionDateTime = formatLastUpdate(record['submissionDateTime']);

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
        DataCell(
          Text(
            record['vendorName'] ?? '',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        DataCell(
          StatusChip(
            label: invitationStatus,
            colors: _invitationColors(invitationStatus),
          ),
        ),
        DataCell(
          StatusChip(
            label: purchased ? 'Yes' : 'No',
            colors: purchased ? ChipPalette.blue : ChipPalette.grey,
          ),
        ),
        DataCell(
          StatusChip(
            label: participationStatus,
            colors: _participationColors(participationStatus),
          ),
        ),
        DataCell(
          StatusChip(
            label: submissionStatus,
            colors: _submissionColors(submissionStatus),
          ),
        ),
        DataCell(Text(submissionDateTime.isEmpty ? '—' : submissionDateTime)),
        DataCell(
          // The blueprint wording is ~95 characters; the chip shows the
          // short form and the full sentence on hover.
          Tooltip(
            message: OpenTo.fullLabelFor(openTo),
            waitDuration: const Duration(milliseconds: 400),
            child: StatusChip(
              label: openToLabel,
              colors: _openToColors(openTo),
            ),
          ),
        ),
        DataCell(
          Text(
            record['certificationType'] ?? '',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ReportTablePanel(
      title: 'Vendor Participation Details',
      minWidth: VendorParticipationTable.minTableWidth,
      countLabel: '${widget.records.length} Vendor Records',
      fillHeight: widget.fillHeight,
      onExport: widget.onExport,
      isExporting: widget.isExporting,
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _sortAscending,
      emptyMessage: 'No vendor records match your filter criteria.',
      // Only value and date columns are sortable; the rest are
      // plain labels so nothing looks tappable when it is not.
      columns: [
        // These three are flexible so spare window width is shared between
        // them instead of sitting dead past the last column. Certification
        // stays pinned -- it is already the widest and should not grow.
        DataColumn2(label: const Text('Tender/Quotation ID'), fixedWidth: 165),
        DataColumn2(label: const Text('Vendor Name'), fixedWidth: 210),
        DataColumn2(label: const Text('Invitation Status'), fixedWidth: 150),
        DataColumn2(label: const Text('Document Purchased'), fixedWidth: 170),
        DataColumn2(label: const Text('Participation'), fixedWidth: 150),
        DataColumn2(label: const Text('Submission Status'), fixedWidth: 165),
        DataColumn2(
          label: SortableHeader(
            'Submission Date & Time',
            columnIndex: 6,
            activeIndex: _sortColumnIndex,
          ),
          fixedWidth: 190,
          onSort: _handleSort,
        ),
        DataColumn2(label: const Text('Open To'), fixedWidth: 174),
        // Pinned: this is the longest text in the app, and letting it flex
        // made it swallow every spare pixel. 380 fits the longest value.
        DataColumn2(
          label: const Text('Vendor Certification Type'),
          fixedWidth: 300,
        ),
      ],
      rows: _sortedRecords.map(_buildRecordRow).toList(),
    );
  }
}
