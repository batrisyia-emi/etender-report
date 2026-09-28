// lib/reports/widgets/vtm_monitoring/vtm_monitoring_table.dart
import 'package:data_table_2/data_table_2.dart';
import 'package:etender_reports/shared/app_colors.dart';
import 'package:etender_reports/shared/utils/formatters.dart';
import 'package:flutter/material.dart';

import 'package:etender_reports/reports/models/records/vtm_monitoring_record.dart';
import 'package:etender_reports/reports/models/report_export.dart';
import 'package:etender_reports/reports/models/report_sorting.dart';
import 'package:etender_reports/reports/models/vtm_monitoring_metrics.dart';
import 'package:etender_reports/reports/models/vtm_monitoring_status.dart';
import 'package:etender_reports/reports/widgets/shared/report_table_panel.dart';
import 'package:etender_reports/reports/widgets/shared/sortable_header.dart';
import 'package:etender_reports/reports/widgets/shared/status_chip.dart';

/// One row per eRFC, following the report spec's column order.
///
/// The four date columns read as a trail: endorsed, submitted, verified,
/// approved, floated. A gap in that trail is where the document is now.
class VtmMonitoringTable extends StatefulWidget {
  const VtmMonitoringTable({
    super.key,
    required this.records,
    this.fillHeight = false,
    this.onExport,
    this.isExporting = false,
  });

  final List<VtmMonitoringRecord> records;

  final bool fillHeight;
  final ValueChanged<ExportFormat>? onExport;
  final bool isExporting;

  /// The 16 column widths, plus their 15 sixteen-pixel gaps and the table's
  /// own 12px side margins.
  ///
  /// This number is the horizontal scroll extent. Below what the columns
  /// need it truncates the table rather than compressing it.
  static const double minTableWidth = _columnWidthTotal + 15 * 16 + 2 * 12;

  /// 165 + 172 + 250 + 100 + 175 + 190 + 140 + 130 + 190 + 134 + 115 + 115
  /// + 115 + 120 + 130 + 95
  static const double _columnWidthTotal = 2336;

  @override
  State<VtmMonitoringTable> createState() => _VtmMonitoringTableState();
}

class _VtmMonitoringTableState extends State<VtmMonitoringTable> {
  /// Aging descending: the longest-waiting document is the one worth
  /// seeing first on a monitoring report.
  int? _sortColumnIndex = 15;
  bool _sortAscending = false;

  void _handleSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  /// One reader per column, positionally matched to [_columns].
  static final List<Comparable<Object>? Function(VtmMonitoringRecord)?>
  _sortKeys = [
    (r) => r.erfcNo.toLowerCase(),
    (r) => r.tenderQuotationNo?.toLowerCase(),
    null, // Project Title
    null, // Document Type
    null, // Mode
    null, // Division
    (r) => r.estimatedValue,
    (r) => r.documentPrice,
    // Process order, not alphabetical: sorting by status walks the
    // Appendix F from Draft to Published.
    (r) => r.statusValue?.index ?? -1,
    (r) => r.endorsedDate,
    (r) => r.submittedDate,
    (r) => r.verifiedDate,
    (r) => r.approvedDate,
    (r) => r.floatingDate,
    (r) => r.closingDate,
    (r) => vtmAgingDays(r),
  ];

  List<VtmMonitoringRecord> get _sortedRecords => sortRows(
    rows: widget.records,
    columns: _sortKeys,
    columnIndex: _sortColumnIndex,
    ascending: _sortAscending,
  );

  /// Grey while it is a draft, blue and teal through the two gates, green
  /// once approved, indigo once floated, red for either rejection.
  ///
  /// Both rejections share red: which gate turned the document back matters
  /// less at a glance than the fact that somebody has to redo it — the same
  /// choice the eRFC report makes.
  ChipColors _statusColors(VtmStatus? status) => switch (status) {
    VtmStatus.draft => ChipPalette.grey,
    VtmStatus.submitted => ChipPalette.blue,
    VtmStatus.verifiedByExec => ChipPalette.teal,
    VtmStatus.approvedByManager => ChipPalette.green,
    VtmStatus.published => ChipPalette.indigo,
    VtmStatus.rejectedByExec || VtmStatus.rejectedByManager => ChipPalette.red,
    null => ChipPalette.grey,
  };

  /// The status, with what happens next and whose step it is behind it.
  Widget _statusCell(VtmMonitoringRecord record) {
    final status = record.statusValue;
    final chip = StatusChip(
      label: record.status.isEmpty ? _none : record.statusLabel,
      colors: _statusColors(status),
    );
    if (status == null) return chip;

    final next = status.nextStatuses;
    final message = StringBuffer()
      ..writeln(status.description)
      ..writeln()
      ..writeln('Owner: ${status.actor}');
    if (next.isEmpty) {
      message.write('Nothing further is expected.');
    } else {
      message.write('Next: ${next.map((s) => s.label).join(' or ')}');
    }

    return Tooltip(message: message.toString(), child: chip);
  }

  /// Grey once floated — the wait is over and the number is history. Red
  /// past the threshold while it is still moving, amber otherwise.
  Widget _agingCell(VtmMonitoringRecord record) {
    final aging = vtmAgingDays(record);
    if (aging == null) return const Text(_none);

    final slow = vtmIsSlow(record);
    final color = record.isPublished
        ? AppColors.muted
        : slow
        ? Colors.red.shade700
        : Colors.orange.shade800;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (slow) ...[
          Icon(Icons.warning_amber_rounded, size: 15, color: color),
          const SizedBox(width: 4),
        ],
        Text(
          '$aging',
          style: TextStyle(
            color: color,
            fontWeight: slow ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// A step that has happened shows its date; one that has not shows a
  /// dash, so the gap in the trail is where the document is now.
  DataCell _stepCell(DateTime? value, {String? by}) {
    if (value == null) return const DataCell(Text(_none));
    final date = Text(formatDateOnly(value));
    if (by == null || by.isEmpty) return DataCell(date);
    return DataCell(Tooltip(message: by, child: date));
  }

  DataRow _buildRecordRow(VtmMonitoringRecord record) {
    DataCell text(String? value) => DataCell(
      Text(
        value == null || value.isEmpty ? _none : value,
        overflow: TextOverflow.ellipsis,
      ),
    );

    return DataRow(
      cells: [
        DataCell(
          Text(
            record.erfcNo,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.blue.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        // Null until the document is approved, which is most of the rows.
        text(record.tenderQuotationNo),
        DataCell(
          Tooltip(
            message: record.projectTitle,
            child: Text(record.projectTitle, overflow: TextOverflow.ellipsis),
          ),
        ),
        DataCell(
          record.tenderTypeValue == null
              ? Text(record.documentType)
              : Tooltip(
                  message: record.tenderTypeValue!.label,
                  child: Text(
                    '${record.documentType} (${record.tenderType})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
        ),
        DataCell(
          Tooltip(
            message: record.modeLabel,
            child: Text(
              '${record.modeOfProcurement}  ${record.modeLabel}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          Tooltip(
            message: '${record.division}\n${record.department}',
            child: Text(record.division, overflow: TextOverflow.ellipsis),
          ),
        ),
        DataCell(Text(formatValue(record.estimatedValue))),
        DataCell(
          Text(
            record.documentPrice == 0
                ? 'Free'
                : formatValue(record.documentPrice),
            style: record.documentPrice == 0
                ? const TextStyle(color: AppColors.muted)
                : null,
          ),
        ),
        DataCell(_statusCell(record)),
        _stepCell(record.endorsedDate),
        _stepCell(record.submittedDate, by: record.preparedBy?.name),
        _stepCell(record.verifiedDate, by: record.verifiedBy?.name),
        _stepCell(record.approvedDate, by: record.approvedBy?.name),
        _stepCell(record.floatingDate),
        _stepCell(record.closingDate),
        DataCell(_agingCell(record)),
      ],
    );
  }

  /// The report spec's column order.
  List<DataColumn> get _columns {
    DataColumn2 plain(String label, double width, {String? tooltip}) =>
        DataColumn2(label: Text(label), tooltip: tooltip, fixedWidth: width);

    DataColumn2 sortable(
      String label,
      int index,
      double width, {
      String? tooltip,
      bool numeric = false,
    }) => DataColumn2(
      label: SortableHeader(
        label,
        columnIndex: index,
        activeIndex: _sortColumnIndex,
      ),
      tooltip: tooltip,
      fixedWidth: width,
      numeric: numeric,
      onSort: _handleSort,
    );

    return [
      sortable('eRFC No.', 0, 165),
      sortable(
        'Tender/Quotation No.',
        1,
        172,
        tooltip: 'Assigned once the Appendix F is approved',
      ),
      plain('Project Title', 250),
      plain('Type', 100, tooltip: 'Document type, and 1 or 2 stage'),
      plain('Mode', 175, tooltip: 'Mode of procurement, Appendix A section 7'),
      plain('Division', 190),
      sortable('Value (RM)', 6, 140, numeric: true),
      sortable(
        'Doc Price (RM)',
        7,
        130,
        numeric: true,
        tooltip: 'What a supplier pays for the document',
      ),
      sortable('Status', 8, 190),
      sortable('eRFC Endorsed', 9, 134),
      sortable('Submitted', 10, 115),
      sortable('Verified', 11, 115),
      sortable('Approved', 12, 115),
      sortable('Floating Date', 13, 120),
      sortable('Closing Date', 14, 130),
      sortable(
        'Aging',
        15,
        95,
        tooltip:
            'Days from eRFC endorsement to today, or to the floating date '
            'once published',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ReportTablePanel(
      title: 'Appendix F Documents',
      minWidth: VtmMonitoringTable.minTableWidth,
      countLabel: '${widget.records.length} documents',
      fillHeight: widget.fillHeight,
      onExport: widget.onExport,
      isExporting: widget.isExporting,
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _sortAscending,
      emptyMessage: 'No documents match your filter criteria.',
      columns: _columns,
      rows: _sortedRecords.map(_buildRecordRow).toList(),
    );
  }
}

/// Stands in for every empty cell, matching `formatDateOnly`.
const String _none = '—';
