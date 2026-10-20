// lib/reports/procurement_lead_time/widgets/lead_time_drilldown_table.dart
import 'package:data_table_2/data_table_2.dart';
import 'package:etender_reports/reports/models/export/report_export.dart';
import 'package:etender_reports/reports/procurement_lead_time/models/lead_time_record.dart';
import 'package:etender_reports/reports/widgets/shared/report_table_panel.dart';
import 'package:etender_reports/shared/utils/formatters.dart';
import 'package:flutter/material.dart';

/// The tenders behind one band's count, slowest first.
class LeadTimeDrilldownTable extends StatelessWidget {
  const LeadTimeDrilldownTable({
    super.key,
    required this.title,
    required this.items,
    this.fillHeight = false,
    this.onExport,
    this.isExporting = false,
  });

  final String title;

  /// Already sorted by working days, descending.
  final List<MeasuredLeadTime> items;

  final bool fillHeight;
  final ValueChanged<ExportFormat>? onExport;
  final bool isExporting;

  /// The columns as exported, so the file matches the screen.
  static final List<ExportColumn> exportColumns = [
    ExportColumn('Tender/Quotation Number', (row) => '${row['tenderNo']}'),
    ExportColumn('Project Title', (row) => '${row['projectTitle']}'),
    ExportColumn('Mode of Procurement', (row) => '${row['procurementMode']}'),
    ExportColumn('eRFC Number', (row) => '${row['erfcNo']}'),
    ExportColumn(
      'Received by VTM',
      (row) => formatDottedDate(row['vtmReceivedDate'] as DateTime?),
    ),
    ExportColumn(
      'Published',
      (row) => formatDottedDate(row['publishedDate'] as DateTime?),
    ),
    ExportColumn(
      'Working Days',
      (row) => '${row['workingDays']}',
      readNumber: (row) => row['workingDays'] as int?,
    ),
  ];

  static Map<String, dynamic> exportRow(MeasuredLeadTime item) => {
    'tenderNo': item.record.tenderNo,
    'projectTitle': item.record.projectTitle,
    'procurementMode': item.record.procurementMode,
    'erfcNo': item.record.erfcNo,
    'vtmReceivedDate': item.record.vtmReceivedDate,
    'publishedDate': item.record.publishedDate,
    'workingDays': item.workingDays,
  };

  static const int _titleColumn = 1;

  static const List<double> _widths = [190, 380, 160, 190, 130, 110, 110];

  /// Column widths, six 16px gaps and the 12px side margins.
  static final double _minWidth =
      _widths.fold<double>(0, (sum, w) => sum + w) + 6 * 16 + 2 * 12;

  @override
  Widget build(BuildContext context) {
    DataColumn2 column(int index, String label, {bool numeric = false}) =>
        DataColumn2(
          label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          // Project Title takes up the slack so the table fills the panel;
          // its entry in [_widths] is only its floor, via [_minWidth].
          fixedWidth: index == _titleColumn ? null : _widths[index],
          size: ColumnSize.L,
          numeric: numeric,
        );

    return ReportTablePanel(
      title: title,
      countLabel: '${items.length} tenders',
      minWidth: _minWidth,
      fillHeight: fillHeight,
      onExport: onExport,
      isExporting: isExporting,
      emptyMessage: 'No tenders published in this band.',
      shrinkToRows: true,
      columns: [
        column(0, 'Tender/Quotation Number'),
        column(1, 'Project Title'),
        column(2, 'Mode of Procurement'),
        column(3, 'eRFC Number'),
        column(4, 'Received by VTM'),
        column(5, 'Published'),
        column(6, 'Working Days', numeric: true),
      ],
      rows: [
        for (final item in items)
          DataRow(
            cells: [
              DataCell(Text(item.record.tenderNo)),
              DataCell(
                Tooltip(
                  message: item.record.projectTitle,
                  waitDuration: const Duration(milliseconds: 600),
                  child: Text(
                    item.record.projectTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(Text(item.record.procurementMode)),
              DataCell(Text(item.record.erfcNo)),
              DataCell(Text(formatDottedDate(item.record.vtmReceivedDate))),
              DataCell(Text(formatDottedDate(item.record.publishedDate))),
              DataCell(
                Text(
                  '${item.workingDays}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
