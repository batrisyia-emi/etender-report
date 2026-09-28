// lib/reports/widgets/tender_security/tender_security_table.dart
import 'package:data_table_2/data_table_2.dart';
import 'package:etender_reports/reports/models/attributes/tender_security_attributes.dart';
import 'package:etender_reports/reports/models/export/report_export.dart';
import 'package:etender_reports/reports/models/metrics/tender_security_metrics.dart';
import 'package:etender_reports/reports/models/records/tender_security_record.dart';
import 'package:etender_reports/reports/models/sorting/report_sorting.dart';
import 'package:etender_reports/reports/widgets/shared/report_table_panel.dart';
import 'package:etender_reports/reports/widgets/shared/sortable_header.dart';
import 'package:etender_reports/reports/widgets/shared/status_chip.dart';
import 'package:etender_reports/shared/app_colors.dart';
import 'package:etender_reports/shared/utils/formatters.dart';
import 'package:flutter/material.dart';

/// One row per tenderer per tender.
///
/// The columns follow chapter 9.1's List function in its own order, with two
/// additions the blueprint asks for elsewhere: Original Copy Received
/// (Appendix F item m, which 9.1 requires as a function without saying where
/// it lives) and the scan copy link (recommendation R1).
///
/// The only editable table in the app. Four columns belong to VTM — Original
/// Copy Received, Submitted to RA/CSU, Unsuccessful Tenderer and Date of
/// Refund — and each reports its change through [onEdit]. Everything else
/// comes from the system or the supplier and is read-only.
class TenderSecurityTable extends StatefulWidget {
  const TenderSecurityTable({
    super.key,
    required this.records,
    this.onEdit,
    this.onOpenScanCopy,
    this.fillHeight = false,
    this.onExport,
    this.isExporting = false,
  });

  final List<TenderSecurityRecord> records;

  /// A VTM field changed on one row. Null leaves the controls disabled,
  /// which is what a caller with nothing to wire them to should pass.
  final void Function(TenderSecurityRecord record, TenderSecurityEdit edit)?
  onEdit;

  /// Open the scan copy. Null disables the link.
  final ValueChanged<String>? onOpenScanCopy;

  final bool fillHeight;
  final ValueChanged<ExportFormat>? onExport;
  final bool isExporting;

  /// The 12 column widths, plus their 11 sixteen-pixel gaps and the table's
  /// own 12px side margins.
  ///
  /// This number is the horizontal scroll extent. Below what the columns
  /// need it truncates the table rather than compressing it.
  static const double minTableWidth = _columnWidthTotal + 11 * 16 + 2 * 12;

  /// 170 + 190 + 145 + 150 + 140 + 190 + 100 + 130 + 175 + 150 + 150 + 130
  static const double _columnWidthTotal = 1820;

  @override
  State<TenderSecurityTable> createState() => _TenderSecurityTableState();
}

/// What changed on a row, in the shape the PATCH body takes.
class TenderSecurityEdit {
  const TenderSecurityEdit({
    this.originalCopyReceived,
    this.submittedToRevenueAssuranceDate,
    this.clearSubmittedToRevenueAssuranceDate = false,
    this.unsuccessfulTenderer,
    this.clearUnsuccessfulTenderer = false,
    this.refundDate,
    this.clearRefundDate = false,
  });

  final bool? originalCopyReceived;
  final DateTime? submittedToRevenueAssuranceDate;
  final bool clearSubmittedToRevenueAssuranceDate;
  final String? unsuccessfulTenderer;
  final bool clearUnsuccessfulTenderer;
  final DateTime? refundDate;
  final bool clearRefundDate;
}

class _TenderSecurityTableState extends State<TenderSecurityTable> {
  /// Expiry ascending: the securities closest to lapsing are the ones worth
  /// seeing first, which is what recommendation R2 is about.
  int? _sortColumnIndex = 10;
  bool _sortAscending = true;

  void _handleSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  /// One reader per column, positionally matched to [_columns].
  static final List<Comparable<Object>? Function(TenderSecurityRecord)?>
  _sortKeys = [
    (r) => r.tenderNo.toLowerCase(),
    (r) => r.vendorName.toLowerCase(),
    (r) => r.uniqueNo.toLowerCase(),
    (r) => r.amount,
    (r) => r.bankName.toLowerCase(),
    null, // Instrument (payment type + reference)
    null, // Scan copy
    null, // Original copy received
    (r) => r.submittedToRevenueAssuranceDate,
    null, // Unsuccessful tenderer
    (r) => r.expiryDate,
    (r) => r.refundDate,
  ];

  List<TenderSecurityRecord> get _sortedRecords => sortRows(
    rows: widget.records,
    columns: _sortKeys,
    columnIndex: _sortColumnIndex,
    ascending: _sortAscending,
  );

  bool get _editable => widget.onEdit != null;

  void _edit(TenderSecurityRecord record, TenderSecurityEdit edit) =>
      widget.onEdit?.call(record, edit);

  /// A date VTM sets and can clear: the date once it is there, a button to
  /// set it when it is not.
  Widget _editableDateCell({
    required DateTime? value,
    required String setLabel,
    required String helpText,
    required ValueChanged<DateTime> onPicked,
    required VoidCallback onCleared,
    Color? setColor,
  }) {
    if (value == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: _editable
              ? () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: now,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(now.year + 5),
                    helpText: helpText,
                  );
                  if (picked != null) onPicked(picked);
                }
              : null,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.accent,
            minimumSize: const Size(0, 30),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(fontSize: 12),
          ),
          child: Text(setLabel),
        ),
      );
    }

    return Row(
      children: [
        Flexible(
          child: Text(
            formatDateOnly(value),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: setColor ?? AppColors.tableBodyText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (_editable)
          IconButton(
            icon: const Icon(Icons.close, size: 14),
            tooltip: 'Clear this date',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            color: AppColors.muted,
            onPressed: onCleared,
          ),
      ],
    );
  }

  /// The expiry cell carries the R2 highlight: red once lapsed, amber with
  /// a countdown while it is close. A refunded security shows neither — it
  /// is not held any more, so its expiry stopped mattering.
  Widget _expiryCell(TenderSecurityRecord record) {
    final expiry = record.expiryDate;
    if (expiry == null) return const Text(_none);

    if (tenderSecurityIsExpired(record)) {
      return Row(
        children: [
          const Icon(Icons.error_outline, size: 15, color: Color(0xFFC62828)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              formatDateOnly(expiry),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFC62828),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }
    if (tenderSecurityIsExpiringSoon(record)) {
      final days = tenderSecurityDaysToExpiry(record) ?? 0;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            formatDateOnly(expiry),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFEF6C00),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            days == 0
                ? 'expires today'
                : '${days == 1 ? '1 day' : '$days days'} left',
            style: const TextStyle(fontSize: 11, color: Color(0xFFEF6C00)),
          ),
        ],
      );
    }
    return Text(formatDateOnly(expiry));
  }

  /// The blueprint groups the payment type and the bank's reference under
  /// one heading, so they share one cell.
  Widget _instrumentCell(TenderSecurityRecord record) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        StatusChip(
          label: record.paymentTypeLabel,
          colors: switch (record.paymentTypeValue) {
            PaymentType.bankGuarantee => ChipPalette.indigo,
            PaymentType.bankDraft => ChipPalette.blue,
            PaymentType.cashiersOrder => ChipPalette.blueGrey,
            null => ChipPalette.grey,
          },
        ),
        Text(
          record.referenceNo.isEmpty ? _none : record.referenceNo,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    );
  }

  /// Three states, so a dropdown rather than a tick box: blank is not `NO`,
  /// and only `YES` releases the security.
  Widget _outcomeCell(TenderSecurityRecord record) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<UnsuccessfulTenderer>(
        value: record.outcome,
        isDense: true,
        isExpanded: true,
        style: const TextStyle(fontSize: 12, color: AppColors.tableBodyText),
        items: [
          for (final option in UnsuccessfulTenderer.values)
            DropdownMenuItem(value: option, child: Text(option.label)),
        ],
        onChanged: _editable
            ? (option) {
                if (option == null || option == record.outcome) return;
                _edit(
                  record,
                  TenderSecurityEdit(
                    unsuccessfulTenderer: option.wireValue,
                    clearUnsuccessfulTenderer:
                        option == UnsuccessfulTenderer.notDecided,
                  ),
                );
              }
            : null,
      ),
    );
  }

  Widget _scanCopyCell(TenderSecurityRecord record) {
    final url = record.scanCopy;
    if (url == null || url.isEmpty) return const Text(_none);

    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: widget.onOpenScanCopy == null
            ? null
            : () => widget.onOpenScanCopy!(url),
        icon: const Icon(Icons.description_outlined, size: 15),
        label: const Text('View'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          minimumSize: const Size(0, 30),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  DataRow _buildRecordRow(TenderSecurityRecord record) {
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
            record.tenderNo,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.blue.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        text(record.vendorName),
        text(record.uniqueNo),
        DataCell(Text(formatValue(record.amount))),
        text(record.bankName),
        DataCell(_instrumentCell(record)),
        DataCell(_scanCopyCell(record)),
        DataCell(
          Tooltip(
            message: 'Original copy received (Appendix F item m)',
            child: Checkbox(
              value: record.originalCopyReceived,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: _editable
                  ? (next) => _edit(
                      record,
                      TenderSecurityEdit(originalCopyReceived: next ?? false),
                    )
                  : null,
            ),
          ),
        ),
        DataCell(
          _editableDateCell(
            value: record.submittedToRevenueAssuranceDate,
            setLabel: 'Record date',
            helpText: 'Submitted to Revenue Assurance / CSU',
            onPicked: (date) => _edit(
              record,
              TenderSecurityEdit(submittedToRevenueAssuranceDate: date),
            ),
            onCleared: () => _edit(
              record,
              const TenderSecurityEdit(
                clearSubmittedToRevenueAssuranceDate: true,
              ),
            ),
          ),
        ),
        DataCell(_outcomeCell(record)),
        DataCell(_expiryCell(record)),
        DataCell(
          _editableDateCell(
            value: record.refundDate,
            setLabel: 'Record refund',
            helpText: 'Date of refund',
            setColor: Colors.green.shade700,
            onPicked: (date) =>
                _edit(record, TenderSecurityEdit(refundDate: date)),
            onCleared: () =>
                _edit(record, const TenderSecurityEdit(clearRefundDate: true)),
          ),
        ),
      ],
    );
  }

  /// Chapter 9.1's List columns in their own order, with the scan copy and
  /// the original-copy tick inserted where they read best.
  List<DataColumn> get _columns {
    DataColumn2 plain(String label, double width, {String? tooltip}) =>
        DataColumn2(label: Text(label), tooltip: tooltip, fixedWidth: width);

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
      sortable('Tender/Quotation No.', 0, 170),
      sortable('Name of Tenderer', 1, 190),
      sortable('Unique Number', 2, 145),
      sortable('Amount', 3, 150, tooltip: 'Amount of Tender Security'),
      sortable('Bank Name', 4, 140),
      plain(
        'Instrument',
        190,
        tooltip: "Cashier's Order, Bank Draft or Bank Guarantee number",
      ),
      plain('Scan Copy', 100),
      plain(
        'Original',
        130,
        tooltip: 'Original copy received — Appendix F item (m)',
      ),
      sortable(
        'Submitted to RA/CSU',
        8,
        175,
        tooltip: 'Submitted to Revenue Assurance / Contract Services Unit',
      ),
      plain('Unsuccessful', 150, tooltip: 'Unsuccessful Tenderer'),
      sortable('Expiry Date', 10, 150),
      sortable(
        'Date of Refund',
        11,
        130,
        tooltip: 'Date of Refund Tender Security',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ReportTablePanel(
      title: 'Tender Security Submissions',
      minWidth: TenderSecurityTable.minTableWidth,
      countLabel: '${widget.records.length} securities',
      fillHeight: widget.fillHeight,
      onExport: widget.onExport,
      isExporting: widget.isExporting,
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _sortAscending,
      emptyMessage: 'No securities match your filter criteria.',
      columns: _columns,
      rows: _sortedRecords.map(_buildRecordRow).toList(),
    );
  }
}

/// Stands in for every empty cell, matching `formatDateOnly`.
const String _none = '—';
