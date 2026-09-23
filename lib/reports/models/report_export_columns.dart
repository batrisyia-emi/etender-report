// lib/reports/models/report_export_columns.dart
//
// Export columns mirror the on-screen tables, so a file matches what the
// user was looking at. Audit fields the tables omit are included here, since
// a spreadsheet has room and reviewers ask for them.
import 'package:etender_reports/shared/utils/formatters.dart';

import 'package:etender_reports/reports/models/erfc_metrics.dart';
import 'package:etender_reports/reports/models/open_to.dart';
import 'package:etender_reports/reports/models/report_export.dart';
import 'package:etender_reports/reports/models/supplier_metrics.dart';

String _text(Map<String, dynamic> r, String key) => r[key]?.toString() ?? '';

num? _number(Map<String, dynamic> r, String key) =>
    num.tryParse(r[key]?.toString() ?? '');

/// Report spec 6.1 — Tender/Quotation Summary.
final List<ExportColumn> tenderExportColumns = [
  ExportColumn('Ref No', (r) => _text(r, 'referenceNo')),
  ExportColumn('Tender/Quotation No', (r) => _text(r, 'tenderNo')),
  ExportColumn('Title', (r) => _text(r, 'title')),
  ExportColumn('Tender Category', (r) => _text(r, 'tenderCategory')),
  ExportColumn('Division', (r) => _text(r, 'division')),
  ExportColumn('Department', (r) => _text(r, 'department')),
  ExportColumn('Unit', (r) => _text(r, 'unit')),
  ExportColumn(
    'Tender Value (RM)',
    (r) => formatValue(r['value']),
    readNumber: (r) => _number(r, 'value'),
  ),
  ExportColumn('Mode of Procurement', (r) => _text(r, 'modeOfProcurement')),
  ExportColumn('Envelope', (r) => _text(r, 'envelopeType')),
  ExportColumn('Item Type', (r) => _text(r, 'itemType')),
  ExportColumn('RFC Endorsed Date', (r) => formatDateOnly(r['endorsedDate'])),
  ExportColumn('Floating Date', (r) => formatDateOnly(r['floatingDate'])),
  ExportColumn('Tender Closing Date', (r) => formatDateOnly(r['closingDate'])),
  ExportColumn('Status', (r) => _text(r, 'status')),
  // Audit trail: not on screen, useful in a file.
  ExportColumn('eRFC ID', (r) => _text(r, 'erfcId')),
  ExportColumn('Created By', (r) => _text(r, 'createdBy')),
  ExportColumn('Last Update', (r) => formatLastUpdate(r['lastUpdate'])),
  ExportColumn('Updated By', (r) => _text(r, 'lastUpdatedBy')),
];

/// Report spec 6.1 — Vendor Participation.
final List<ExportColumn> vendorExportColumns = [
  ExportColumn('Tender/Quotation ID', (r) => _text(r, 'tenderNo')),
  ExportColumn('Ref No', (r) => _text(r, 'referenceNo')),
  ExportColumn('Title', (r) => _text(r, 'title')),
  ExportColumn('Tender Category', (r) => _text(r, 'tenderCategory')),
  ExportColumn('Vendor Name', (r) => _text(r, 'vendorName')),
  ExportColumn('Invitation Status', (r) => _text(r, 'invitationStatus')),
  ExportColumn(
    'Document Purchased',
    (r) => r['documentPurchased'] == true ? 'Yes' : 'No',
  ),
  ExportColumn('Participation', (r) => _text(r, 'participationStatus')),
  ExportColumn('Submission Status', (r) => _text(r, 'submissionStatus')),
  ExportColumn(
    'Submission Date & Time',
    (r) => formatLastUpdate(r['submissionDateTime']),
  ),
  // The blueprint sentence in full: a spreadsheet has room for it.
  ExportColumn('Open To', (r) => OpenTo.fullLabelFor(r['openTo'])),
  ExportColumn('Vendor Category', (r) => _text(r, 'vendorCategory')),
  ExportColumn(
    'Vendor Certification Type',
    (r) => _text(r, 'certificationType'),
  ),
];

/// Report spec 6.2 — eRFC lifecycle. Aging is derived, so it is computed
/// here the same way the table computes it.
final List<ExportColumn> erfcExportColumns = [
  ExportColumn('RFC Number', (r) => _text(r, 'rfcNumber')),
  ExportColumn('Division', (r) => _text(r, 'division')),
  ExportColumn('Department', (r) => _text(r, 'department')),
  ExportColumn('Unit', (r) => _text(r, 'unit')),
  ExportColumn('Mode of Procurement', (r) => _text(r, 'modeOfProcurement')),
  ExportColumn(
    'Value (RM)',
    (r) => formatValue(r['value']),
    readNumber: (r) => _number(r, 'value'),
  ),
  ExportColumn('Submission Date', (r) => formatDateOnly(r['submissionDate'])),
  ExportColumn('Verified 1 Date', (r) => formatDateOnly(r['verified1Date'])),
  ExportColumn('Verified 2 Date', (r) => formatDateOnly(r['verified2Date'])),
  ExportColumn('Endorsed Date', (r) => formatDateOnly(r['endorsedDate'])),
  ExportColumn('Current Status', (r) => _text(r, 'status')),
  ExportColumn(
    'Aging (days)',
    (r) => erfcAgingDays(r)?.toString() ?? '',
    readNumber: (r) => erfcAgingDays(r),
  ),
  ExportColumn('Overdue', (r) => erfcIsOverdue(r) ? 'Yes' : 'No'),
  ExportColumn('Created By', (r) => _text(r, 'createdBy')),
];

/// The supplier view - one row per tender the signed-in supplier took part
/// in, with the dates that show how far the request got and what it cost.
///
/// No supplier name or ID: the export mirrors what the report shows, and
/// naming suppliers there would tell one supplier who else bid.
final List<ExportColumn> supplierExportColumns = [
  ExportColumn('Tender/Quotation No', (r) => _text(r, 'tenderNo')),
  ExportColumn('Ref No', (r) => _text(r, 'referenceNo')),
  ExportColumn('Title', (r) => _text(r, 'title')),
  ExportColumn('Tender Category', (r) => _text(r, 'tenderCategory')),
  ExportColumn('Division', (r) => _text(r, 'division')),
  ExportColumn('Mode of Procurement', (r) => _text(r, 'modeOfProcurement')),
  ExportColumn('Published Date', (r) => formatDateOnly(r['publishedDate'])),
  ExportColumn('Request Date', (r) => formatDateOnly(r['requestDate'])),
  ExportColumn('Decision Date', (r) => formatDateOnly(r['decisionDate'])),
  ExportColumn(
    'Days to Decision',
    (r) => supplierDecisionDays(r)?.toString() ?? '',
    readNumber: supplierDecisionDays,
  ),
  ExportColumn('Payment Date', (r) => formatDateOnly(r['paymentDate'])),
  ExportColumn(
    'Document Fee (RM)',
    (r) => formatValue(r['documentFee']),
    readNumber: (r) => _number(r, 'documentFee'),
  ),
  ExportColumn('Tender Closing Date', (r) => formatDateOnly(r['closingDate'])),
  ExportColumn(
    'Bid Submitted',
    (r) => formatLastUpdate(r['submissionDateTime']),
  ),
  ExportColumn(
    'Bid Amount (RM)',
    (r) => formatValue(r['bidAmount']),
    readNumber: (r) => _number(r, 'bidAmount'),
  ),
  ExportColumn('Current Status', (r) => _text(r, 'status')),
  // The blueprint sentence in full: a spreadsheet has room for it.
  ExportColumn('Open To', (r) => OpenTo.fullLabelFor(r['openTo'])),
  ExportColumn('Certification Type', (r) => _text(r, 'certificationType')),
];
