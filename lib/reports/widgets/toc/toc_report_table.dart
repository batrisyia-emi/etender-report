// lib/reports/widgets/toc/toc_report_table.dart
import 'package:data_table_2/data_table_2.dart';
import 'package:etender_reports/reports/models/export/report_export.dart';
import 'package:etender_reports/reports/models/metrics/toc_metrics.dart';
import 'package:etender_reports/reports/models/records/toc_opening_record.dart';
import 'package:etender_reports/reports/models/sorting/report_sorting.dart';
import 'package:etender_reports/reports/models/status/toc_status.dart';
import 'package:etender_reports/reports/widgets/shared/report_table_panel.dart';
import 'package:etender_reports/reports/widgets/shared/sortable_header.dart';
import 'package:etender_reports/reports/widgets/shared/status_chip.dart';
import 'package:etender_reports/shared/app_colors.dart';
import 'package:etender_reports/shared/utils/formatters.dart';
import 'package:flutter/material.dart';

/// One row per tender or quotation: the document, its committee, and how far
/// the opening has got.
///
/// No column here may ever carry bid data. This table is read by VTM staff
/// before evaluation, so Harga Tawaran, Appendix C, Tempoh Siap, Tempoh Sah
/// Laku, the rest of Appendix G and the OTP values themselves stay out of
/// it. The Appendix G column says who submitted it and when, never what was
/// in it, and the OTP count sits in a tooltip — never the passwords.
///
/// The blueprint lists more fields than belong in a grid. Everything the
/// record carries is still reachable, but seven of the original columns
/// moved into the cell they belong to, because 22 columns came to 3740px,
/// which is wider than anyone can usefully scroll:
///
/// | Was its own column | Now |
/// |---|---|
/// | Extended | marker beside the tender number |
/// | Chairman / Member 1 / Member 2 | one Committee cell, full list in its tooltip |
/// | Appointed | Committee tooltip |
/// | Swaps | Committee tooltip |
/// | Memo Ref No | Memo Sent tooltip |
/// | OTPs | Opened tooltip |
class TocReportTable extends StatefulWidget {
  const TocReportTable({
    super.key,
    required this.records,
    this.fillHeight = false,
    this.onExport,
    this.isExporting = false,
  });

  /// Typed, unlike the other four tables: the committee is a nested list
  /// and a map row cannot carry it without re-parsing on every build.
  final List<TocOpeningRecord> records;

  /// When true the rows scroll inside the height the parent gives.
  final bool fillHeight;

  /// Shows the Export menu in the panel header when provided.
  final ValueChanged<ExportFormat>? onExport;
  final bool isExporting;

  /// The 15 column widths, plus their 14 sixteen-pixel gaps and the table's
  /// own 12px side margins. Written as the sum rather than the total so a
  /// column change can be checked against it.
  ///
  /// This number *is* the horizontal scroll extent. Setting it below what
  /// the columns actually need does not compress them — it truncates the
  /// table, and the columns past the cut cannot be scrolled to at all.
  static const double minTableWidth = _columnWidthTotal + 14 * 16 + 2 * 12;

  /// 170 + 240 + 90 + 140 + 130 + 175 + 122 + 200 + 118 + 175 + 110
  /// + 230 + 210 + 168 + 85
  static const double _columnWidthTotal = 2363;

  @override
  State<TocReportTable> createState() => _TocReportTableState();
}

class _TocReportTableState extends State<TocReportTable> {
  int? _sortColumnIndex;
  bool _sortAscending = true;

  void _handleSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  /// One reader per column, positionally matched to [_columns]. Null means
  /// the column is not sortable.
  static final List<Comparable<Object>? Function(TocOpeningRecord)?> _sortKeys =
      [
        (r) => r.tenderNo.toLowerCase(),
        null, // Project Title
        null, // Type
        null, // eRFC No
        (r) => r.closingDateTime,
        (r) => r.openingDateTime, // Scheduled Opening
        null, // Envelope
        null, // Committee
        (r) => r.memoSentAt,
        (r) => r.openedAt, // TOC Opening Date
        (r) => r.suppliersSubmittedCount,
        (r) => r.appendixGSubmittedAt, // Chairman Acknowledge (Appx G)
        (r) => r.appendixPSubmittedAt, // VTM Acknowledge (Appx P)
        // Process order, not alphabetical: sorting by status should walk
        // the opening from Open to Opening Completed. An unrecognised
        // status sorts before all of them rather than crashing.
        (r) => r.statusValue?.index ?? -1,
        tocAgingDays,
      ];

  List<TocOpeningRecord> get _sortedRecords => sortRows(
    rows: widget.records,
    columns: _sortKeys,
    columnIndex: _sortColumnIndex,
    ascending: _sortAscending,
  );

  /// Grey while it is only open, blue once a committee exists, warming
  /// through the opening itself, green when it is done. Switching on the
  /// enum means a new status is a compile error here rather than a silently
  /// grey chip; an unrecognised one from the server stays grey on purpose.
  ChipColors _statusColors(TocStatus? status) => switch (status) {
    TocStatus.open => ChipPalette.grey,
    TocStatus.committeeAppointed => ChipPalette.blue,
    TocStatus.openingInProgress => ChipPalette.indigo,
    TocStatus.technicalOpened => ChipPalette.amber,
    TocStatus.commercialSealed => ChipPalette.orange,
    TocStatus.commercialOpened || TocStatus.tenderOpened => ChipPalette.teal,
    TocStatus.openingCompleted => ChipPalette.green,
    null => ChipPalette.grey,
  };

  /// Two lines in one cell: a value over a quieter caption.
  Widget _stacked(String value, String caption) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Text(
          caption,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    );
  }

  /// The number, with a marker when an extension cleared the committee.
  Widget _tenderNoCell(TocOpeningRecord record) {
    final number = Text(
      record.tenderNo,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.blue.shade800,
        fontWeight: FontWeight.w500,
      ),
    );
    if (!record.isExtended) return number;

    return Row(
      children: [
        Flexible(child: number),
        const SizedBox(width: 6),
        Tooltip(
          message: 'Extended after appointment, which clears the committee',
          child: Icon(Icons.update, size: 15, color: Colors.amber.shade800),
        ),
      ],
    );
  }

  /// The chairman is the accountable seat, so that is the name on screen.
  /// The other two, their staff IDs, who has signed, when the committee was
  /// appointed and any swaps all live in the tooltip.
  Widget _committeeCell(TocOpeningRecord record) {
    if (record.committee.isEmpty) return const Text(_none);

    final chairman = record.memberAt(TocRole.chairman);
    final others = record.committee.length - (chairman == null ? 0 : 1);

    final detail = StringBuffer();
    for (final member in record.committee) {
      detail.writeln('${member.role}: ${member.name} (${member.staffId})');
    }
    if (record.appointedAt != null) {
      detail.writeln('Appointed ${formatDate(record.appointedAt)}');
    }
    for (final swap in record.replacements) {
      detail.writeln(
        'Replaced ${swap.role}: ${swap.replacedName} by ${swap.newName} '
        '- ${swap.remarks}',
      );
    }

    return Tooltip(
      message: detail.toString().trimRight(),
      child: _stacked(
        chairman?.name ?? record.committee.first.name,
        others == 1 ? '+1 member' : '+$others members',
      ),
    );
  }

  /// Grey once Appendix P is in, amber while the opening is still running.
  Widget _agingCell(TocOpeningRecord record) {
    final aging = tocAgingDays(record);
    if (aging == null) return const Text(_none);

    final done = record.appendixPSubmittedAt != null;
    return Text(
      '$aging',
      style: TextStyle(
        color: done ? AppColors.muted : Colors.orange.shade800,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// Submitted-by over submitted-on, for the two appendix columns. Who and
  /// when only; the contents of either appendix never appear.
  /// The acknowledgement: when it happened above, who made it below.
  ///
  /// Two lines because the row is 40px and a third would be clipped — so
  /// the date carries its time, and the name carries the role beside it
  /// rather than on its own line.
  Widget _acknowledgementCell(String? by, DateTime? at, {String? role}) {
    if (at == null) return const Text(_none);
    final who = by == null || by.isEmpty ? 'Acknowledged' : by;

    // VTM staff are named by role rather than by person, so the name may
    // already be the designation the document type implies. Printing both
    // would read "Executive Quotation · Exec. Quotation".
    final saysItAlready =
        role != null &&
        who.toLowerCase().contains(role.split('. ').last.toLowerCase());

    return _stacked(
      formatLastUpdate(at),
      role == null || role.isEmpty || saysItAlready ? who : '$who · $role',
    );
  }

  /// Which executive signs this one off, from the document type.
  ///
  /// Null for a document type the app does not recognise, so the cell says
  /// who acknowledged it without inventing a job title.
  String? _execRole(TocOpeningRecord record) =>
      switch (TocDocumentType.fromWire(record.documentType)) {
        TocDocumentType.tender => 'Exec. Tender',
        TocDocumentType.quotation => 'Exec. Quotation',
        null => null,
      };

  DataRow _buildRecordRow(TocOpeningRecord record) {
    DataCell text(String? value) => DataCell(
      Text(
        value == null || value.isEmpty ? _none : value,
        overflow: TextOverflow.ellipsis,
      ),
    );
    DataCell dateTime(DateTime? value) => DataCell(
      Text(
        value == null ? _none : formatLastUpdate(value),
        overflow: TextOverflow.ellipsis,
      ),
    );

    // A date with something extra behind it, shown on hover.
    DataCell dateWithDetail(DateTime? value, String? detail) {
      final label = Text(formatDate(value));
      if (value == null || detail == null || detail.isEmpty) {
        return DataCell(label);
      }
      return DataCell(Tooltip(message: detail, child: label));
    }

    final otps = record.otpIssuedDates.length;

    return DataRow(
      cells: [
        DataCell(_tenderNoCell(record)),
        DataCell(
          Tooltip(
            message: record.projectTitle,
            child: Text(record.projectTitle, overflow: TextOverflow.ellipsis),
          ),
        ),
        text(record.documentType),
        text(record.erfcNo),
        dateTime(record.closingDateTime),
        dateTime(record.openingDateTime),
        text(record.envelopeType),
        DataCell(_committeeCell(record)),
        dateWithDetail(record.memoSentAt, record.memoRefNo),
        // How many OTPs were issued, never the passwords themselves.
        DataCell(
          record.openedAt == null
              ? const Text(_none)
              : Tooltip(
                  message: otps == 0
                      ? 'No OTP recorded'
                      : '$otps OTP${otps == 1 ? '' : 's'} issued',
                  child: Text(
                    formatLastUpdate(record.openedAt),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
        ),
        DataCell(
          Text(
            record.openedAt == null
                ? _none
                : '${record.suppliersSubmittedCount}',
          ),
        ),
        DataCell(
          _acknowledgementCell(
            record.appendixGSubmittedBy,
            record.appendixGSubmittedAt,
          ),
        ),
        DataCell(
          _acknowledgementCell(
            record.appendixPSubmittedBy,
            record.appendixPSubmittedAt,
            role: _execRole(record),
          ),
        ),
        DataCell(
          // The status as the server sent it, so an unrecognised value is
          // visible rather than blank. An envelope mismatch is not fixed
          // here — it is raised on the Needs Attention panel.
          StatusChip(
            label: record.status.isEmpty ? _none : record.status,
            colors: _statusColors(record.statusValue),
          ),
        ),
        DataCell(_agingCell(record)),
      ],
    );
  }

  /// Positionally matched to [_sortKeys]; the sortable ones are the dates
  /// and counts a user would actually order by.
  List<DataColumn> get _columns {
    DataColumn2 plain(String label, double width) =>
        DataColumn2(label: Text(label), fixedWidth: width);

    DataColumn2 sortable(
      String label,
      int index,
      double width, {
      String? tooltip,
    }) => DataColumn2(
      label: SortableHeader(
        label,
        columnIndex: index,
        activeIndex: _sortColumnIndex,
      ),
      tooltip: tooltip,
      fixedWidth: width,
      onSort: _handleSort,
    );

    return [
      sortable('Tender / Quotation No', 0, 170),
      plain('Project Title', 240),
      plain('Type', 90),
      plain('eRFC No', 140),
      sortable('Closing', 4, 130),
      sortable(
        'Scheduled Opening',
        5,
        175,
        tooltip:
            'When the opening is booked for — TOC Opening Date is '
            'when it actually happened',
      ),
      plain('Envelope', 122),
      plain('Committee', 200),
      sortable('Memo Sent', 8, 118),
      sortable('TOC Opening Date', 9, 175),
      sortable('Total Bid', 10, 110),
      sortable(
        'Chairman Acknowledge (Appx G)',
        11,
        230,
        tooltip:
            'When the chairman acknowledged Appendix G and who did it — '
            'never what it contained',
      ),
      sortable(
        'VTM Acknowledge (Appx P)',
        12,
        210,
        tooltip:
            'When VTM acknowledged Appendix P, who did it, and which '
            'executive signs this document type off',
      ),
      sortable('Status', 13, 168),
      sortable('Aging', 14, 85),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ReportTablePanel(
      title: 'TOC Appointment & Opening Records',
      minWidth: TocReportTable.minTableWidth,
      countLabel: '${widget.records.length} openings',
      fillHeight: widget.fillHeight,
      onExport: widget.onExport,
      isExporting: widget.isExporting,
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _sortAscending,
      emptyMessage: 'No openings match your filter criteria.',
      columns: _columns,
      rows: _sortedRecords.map(_buildRecordRow).toList(),
    );
  }
}

/// Stands in for every empty cell, matching `formatDate`.
const String _none = '—';
