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
import 'package:etender_reports/reports/widgets/shared/table_heading.dart';
import 'package:etender_reports/shared/app_colors.dart';
import 'package:etender_reports/shared/utils/formatters.dart';
import 'package:flutter/material.dart';

/// One row per tender or quotation: the document, its two committees, and
/// how far the opening has got.
///
/// No column here may ever carry bid data. This table is read by VTM staff
/// before evaluation, so Harga Tawaran, Appendix C, Tempoh Siap, Tempoh Sah
/// Laku, the rest of Appendix G and the OTP values themselves stay out of
/// it. The Appendix G column says who submitted it and when, never what was
/// in it, and the OTP count sits in a tooltip — never the passwords.
///
/// The blueprint lists more fields than belong in a grid. Everything the
/// record carries is still reachable, but several of the original columns
/// moved into the cell they belong to, because 22 columns came to 3740px,
/// which is wider than anyone can usefully scroll:
///
/// | Was its own column | Now |
/// |---|---|
/// | Extended | marker beside the tender number |
/// | Chairman / Member 1 / Member 2 | initials in the Committee cell, full list in its tooltip |
/// | Appointed | Committee tooltip |
/// | Swaps | Committee tooltip |
/// | Memo Ref No | Memo Sent tooltip |
/// | OTPs | Technical Opened tooltip |
///
/// Two pairs of columns look redundant and are not. **TOC Opening Date**
/// and **TOC Opening Time** are one timestamp split in two because the
/// date is what you scan a column for and the time is what you check on
/// one row. **Technical Opened** and **Commercial Opened** are two
/// different events: a two-envelope tender opens the technical envelope
/// first and holds the commercial one sealed until the technical
/// evaluation is done, so a row can honestly be Yes and No at once.
class TocReportTable extends StatefulWidget {
  const TocReportTable({
    super.key,
    required this.records,
    this.fillHeight = false,
    this.onExport,
    this.isExporting = false,
  });

  /// Typed, unlike the other four tables: the committees are nested lists
  /// and a map row cannot carry them without re-parsing on every build.
  final List<TocOpeningRecord> records;

  /// When true the rows scroll inside the height the parent gives.
  final bool fillHeight;

  /// Shows the Export menu in the panel header when provided.
  final ValueChanged<ExportFormat>? onExport;
  final bool isExporting;

  /// The 18 column widths, plus their 17 sixteen-pixel gaps and the table's
  /// own 12px side margins. Written as the sum rather than the total so a
  /// column change can be checked against it.
  ///
  /// This number *is* the horizontal scroll extent. Setting it below what
  /// the columns actually need does not compress them — it truncates the
  /// table, and the columns past the cut cannot be scrolled to at all.
  static const double minTableWidth = _columnWidthTotal + 17 * 16 + 2 * 12;

  /// 170 + 240 + 90 + 140 + 130 + 150 + 135 + 122 + 185 + 185 + 118 + 170
  /// + 180 + 110 + 250 + 225 + 168 + 85
  static const double _columnWidthTotal = 2853;

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
        (r) => r.openingDateTime, // TOC Opening Date
        null, // TOC Opening Time — the date column orders the same field
        null, // Envelope
        null, // Technical Committee
        null, // Committee
        (r) => r.memoSentAt,
        (r) => r.technicalOpenedAt,
        (r) => r.commercialOpenedAt,
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
  Widget _stacked(String value, String caption, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.w500, color: valueColor),
        ),
        Text(
          caption,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    );
  }

  /// A small leading icon, then the value.
  ///
  /// The icon repeats what the column heading already says, so it is never
  /// the only thing carrying a cell's meaning — it is there to make a
  /// column findable while scrolling sideways past eighteen of them.
  Widget _iconText(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: AppColors.placeholder),
      const SizedBox(width: 6),
      Flexible(child: Text(text, overflow: TextOverflow.ellipsis)),
    ],
  );

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

  /// Initials from a name: "Officer Alpha" reads as OA.
  ///
  /// First letters of the first two words, because the mock names and the
  /// real ones both run "title surname". A single-word name gives one
  /// letter rather than an empty circle.
  String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    final letters = words
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word[0].toUpperCase())
        .join();
    return letters.isEmpty ? '?' : letters;
  }

  /// 22px, not the 24 it looks like it wants: the row is 40px and the
  /// seat count sits under it, so a larger circle overflows the cell.
  Widget _avatar(String name) => Container(
    width: 22,
    height: 22,
    margin: const EdgeInsets.only(right: 3),
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      color: AppColors.panelHeader,
      shape: BoxShape.circle,
    ),
    child: Text(
      _initials(name),
      style: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        color: AppColors.accent,
      ),
    ),
  );

  /// Who sits on a committee, as initials over a seat count.
  ///
  /// The names are in the tooltip rather than the cell: three full names do
  /// not fit a 40px row, and the question this column answers at a glance
  /// is whether a committee exists and how big it is.
  Widget _committeeAvatars(List<TocMember> members, String detail) {
    final seats = members.length;
    return Tooltip(
      message: detail.trimRight(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [for (final member in members) _avatar(member.name)],
          ),
          Text(
            seats == 1 ? '1 member' : '$seats members',
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  /// The opening committee: who witnesses the envelopes being opened.
  Widget _committeeCell(TocOpeningRecord record) {
    if (record.committee.isEmpty) return const Text(_none);

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

    return _committeeAvatars(record.committee, detail.toString());
  }

  /// The technical committee: who evaluates what the technical envelope
  /// held.
  ///
  /// Empty is not the same as missing. A one-envelope tender has no
  /// technical envelope, so it never has one of these, and saying so is
  /// more useful than a bare dash that reads like an oversight.
  Widget _technicalCommitteeCell(TocOpeningRecord record) {
    if (record.technicalCommittee.isEmpty) {
      final oneEnvelope =
          record.envelopeTypeValue == TocEnvelopeType.oneEnvelope;
      return Tooltip(
        message: oneEnvelope
            ? 'One envelope: the technical content and the price arrive '
                  'together, so there is no technical envelope to evaluate'
            : 'No technical committee appointed yet',
        child: const Text(_none),
      );
    }

    final detail = StringBuffer('Technical evaluation committee\n');
    for (final member in record.technicalCommittee) {
      detail.writeln(
        '${member.role}: ${member.name} (${member.staffId}) '
        '- ${member.designation}',
      );
    }
    return _committeeAvatars(record.technicalCommittee, detail.toString());
  }

  /// Whether an envelope has been opened, and when.
  ///
  /// Yes or No answers the column at a glance; the timestamp underneath
  /// answers the next question without spending another column on it.
  Widget _openedCell(DateTime? at, {String? note}) {
    final opened = at != null;
    final cell = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          opened ? Icons.check_circle : Icons.cancel,
          size: 16,
          color: opened ? Colors.green.shade600 : Colors.grey.shade400,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: opened
              ? _stacked(
                  'Yes',
                  formatLastUpdate(at),
                  valueColor: Colors.green.shade700,
                )
              : const Text('No', style: TextStyle(color: AppColors.muted)),
        ),
      ],
    );
    return note == null ? cell : Tooltip(message: note, child: cell);
  }

  /// What is worth knowing about the technical opening beyond its
  /// timestamp: how many OTPs the session needed, and — on a one-envelope
  /// tender — why the commercial column says the same thing.
  String? _technicalOpenedNote(TocOpeningRecord record) {
    final notes = <String>[];
    if (record.envelopeTypeValue == TocEnvelopeType.oneEnvelope &&
        record.technicalOpenedAt != null) {
      notes.add(
        'One envelope: the technical content and the price were opened '
        'together, so both columns carry the same time',
      );
    }
    final otps = record.otpIssuedDates.length;
    if (otps > 0) notes.add('$otps OTP${otps == 1 ? '' : 's'} issued');
    return notes.isEmpty ? null : notes.join('\n');
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

  /// The acknowledgement: when it happened above, who made it below. Who
  /// and when only; the contents of either appendix never appear.
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
        DataCell(
          _iconText(
            Icons.calendar_today_outlined,
            formatDate(record.openingDateTime),
          ),
        ),
        DataCell(
          _iconText(
            Icons.schedule_outlined,
            formatTime(record.openingDateTime),
          ),
        ),
        text(record.envelopeType),
        DataCell(_technicalCommitteeCell(record)),
        DataCell(_committeeCell(record)),
        dateWithDetail(record.memoSentAt, record.memoRefNo),
        DataCell(
          _openedCell(
            record.technicalOpenedAt,
            note: _technicalOpenedNote(record),
          ),
        ),
        DataCell(_openedCell(record.commercialOpenedAt)),
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
    DataColumn2 plain(IconData icon, String label, double width) =>
        DataColumn2(label: TableHeading.label(icon, label), fixedWidth: width);

    DataColumn2 sortable(
      IconData icon,
      String label,
      int index,
      double width, {
      String? tooltip,
    }) => DataColumn2(
      label: TableHeading(
        icon: icon,
        child: SortableHeader(
          label,
          columnIndex: index,
          activeIndex: _sortColumnIndex,
        ),
      ),
      tooltip: tooltip,
      fixedWidth: width,
      onSort: _handleSort,
    );

    return [
      sortable(Icons.numbers_outlined, 'Tender / Quotation No', 0, 170),
      plain(Icons.article_outlined, 'Project Title', 240),
      plain(Icons.category_outlined, 'Type', 90),
      plain(Icons.receipt_long_outlined, 'eRFC No', 140),
      sortable(Icons.event_busy_outlined, 'Closing', 4, 130),
      sortable(
        Icons.calendar_today_outlined,
        'TOC Opening Date',
        5,
        150,
        tooltip:
            'The day the opening is booked for — Technical Opened and '
            'Commercial Opened say when it actually happened',
      ),
      plain(Icons.schedule_outlined, 'TOC Opening Time', 135),
      plain(Icons.mail_outline, 'Envelope', 122),
      plain(Icons.engineering_outlined, 'Technical Committee', 185),
      plain(Icons.groups_outlined, 'Committee', 185),
      sortable(Icons.send_outlined, 'Memo Sent', 10, 118),
      sortable(
        Icons.description_outlined,
        'Technical Opened',
        11,
        170,
        tooltip:
            'Whether the technical envelope has been opened, and when. A '
            'one-envelope tender opens both at once.',
      ),
      sortable(
        Icons.shopping_cart_outlined,
        'Commercial Opened',
        12,
        180,
        tooltip:
            'Whether the commercial envelope has been opened. On a '
            'two-envelope tender it stays sealed until the technical '
            'evaluation is done.',
      ),
      sortable(Icons.tag_outlined, 'Total Bid', 13, 110),
      sortable(
        Icons.how_to_reg_outlined,
        'Chairman Acknowledge (Appx G)',
        14,
        250,
        tooltip:
            'When the chairman acknowledged Appendix G and who did it — '
            'never what it contained',
      ),
      sortable(
        Icons.verified_outlined,
        'VTM Acknowledge (Appx P)',
        15,
        225,
        tooltip:
            'When VTM acknowledged Appendix P, who did it, and which '
            'executive signs this document type off',
      ),
      sortable(Icons.flag_outlined, 'TOC Status', 16, 168),
      sortable(Icons.hourglass_empty_outlined, 'Aging', 17, 85),
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
