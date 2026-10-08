// lib/reports/models/filters/report_criteria.dart
//
// What each report's filters say, in words, for the report header.
//
// A report that does not state its own criteria cannot be read away from
// the screen that produced it: 18 rows means nothing without "status
// Published or Extended, Distribution division, closing in September". The
// filter panel knows all of this but collapses, and an exported file loses
// it entirely.
//
// Only filters that are actually set are described. A report with nothing
// applied says so once, rather than listing nine "All" lines.
import 'package:etender_reports/reports/models/filters/report_filters.dart';
import 'package:etender_reports/reports/models/filters/tender_security_filters.dart';
import 'package:etender_reports/reports/models/filters/toc_filters.dart';
import 'package:etender_reports/reports/models/filters/vtm_monitoring_filters.dart';
import 'package:etender_reports/shared/utils/formatters.dart';
import 'package:flutter/material.dart' show DateTimeRange;

/// One line of the header's criteria block.
class ReportCriterion {
  const ReportCriterion(this.label, this.value);

  final String label;
  final String value;

  @override
  String toString() => '$label: $value';
}

/// How many values to name before summarising the rest.
///
/// Four fits a line. Beyond that the list stops being readable and the
/// count is the more useful fact.
const int _kMaxNamedValues = 4;

/// A chosen set, or null when nothing is chosen.
ReportCriterion? _fromSet(String label, Set<String> values) {
  if (values.isEmpty) return null;
  final sorted = values.toList()..sort();
  if (sorted.length <= _kMaxNamedValues) {
    return ReportCriterion(label, sorted.join(', '));
  }
  final named = sorted.take(_kMaxNamedValues).join(', ');
  return ReportCriterion(
    label,
    '$named and ${sorted.length - _kMaxNamedValues} more',
  );
}

ReportCriterion? _fromText(String label, String value) =>
    value.trim().isEmpty ? null : ReportCriterion(label, '"${value.trim()}"');

ReportCriterion? _fromOption(String label, String? value) =>
    value == null || value.isEmpty ? null : ReportCriterion(label, value);

ReportCriterion? _fromRange(String label, DateTimeRange? range) =>
    range == null ? null : ReportCriterion(label, formatDateRange(range));

ReportCriterion? _fromFlag(String label, bool value, String whenTrue) =>
    value ? ReportCriterion(label, whenTrue) : null;

/// An open-ended money band reads better as "from" or "up to" than as a
/// range with a blank end.
ReportCriterion? _fromMoney(double? minimum, double? maximum) {
  if (minimum == null && maximum == null) return null;
  final from = minimum == null ? null : formatValue(minimum, decimals: 0);
  final to = maximum == null ? null : formatValue(maximum, decimals: 0);
  return ReportCriterion('Value', switch ((from, to)) {
    (final f?, final t?) => '$f to $t',
    (final f?, null) => '$f and above',
    (null, final t?) => 'up to $t',
    _ => '',
  });
}

List<ReportCriterion> _compact(List<ReportCriterion?> items) => [
  for (final item in items) ?item,
];

extension TenderFilterCriteria on TenderFilters {
  List<ReportCriterion> describe() => _compact([
    _fromText('Search', searchQuery),
    _fromOption('Document type', documentType),
    _fromSet('Status', statuses),
    _fromSet('Category', categories),
    _fromSet('Procurement mode', procurementModes),
    _fromOption('Envelope', envelopeType),
    _fromOption('Item type', itemType),
    _fromSet('Division', divisions),
    _fromSet('Department', departments),
    _fromSet('Unit', units),
    _fromMoney(minimumValue, maximumValue),
    _fromRange('Endorsed', endorsedDateRange),
    _fromRange('Closing', closingDateRange),
  ]);
}

extension VendorFilterCriteria on VendorFilters {
  List<ReportCriterion> describe() => _compact([
    _fromText('Search', searchQuery),
    _fromOption('Open to', openTo),
    _fromSet('Certification', certificationTypes),
    _fromOption('Invitation', invitationStatus),
    _fromOption('Document purchase', purchaseOption),
    _fromOption('Participation', participationStatus),
    _fromSet('Submission', submissionStatuses),
    _fromRange('Submitted', submissionDateRange),
  ]);
}

extension ErfcFilterCriteria on ErfcFilters {
  List<ReportCriterion> describe() => _compact([
    _fromText('Search', searchQuery),
    _fromSet('Status', statuses),
    _fromSet('Division', divisions),
    _fromSet('Unit', units),
    _fromSet('Procurement mode', procurementModes),
    _fromRange('Submitted', submissionDateRange),
    _fromFlag('Overdue', overdueOnly, 'overdue only'),
  ]);
}

extension SupplierFilterCriteria on SupplierFilters {
  List<ReportCriterion> describe() => _compact([
    _fromText('Search', searchQuery),
    _fromSet('Status', statuses),
    _fromSet('Category', categories),
    _fromSet('Division', divisions),
    _fromOption('Open to', openTo),
    _fromRange('Requested', requestDateRange),
    _fromRange('Closing', closingDateRange),
    _fromFlag('Payment', pendingPaymentOnly, 'pending payment only'),
  ]);
}

extension TocFilterCriteria on TocFilters {
  List<ReportCriterion> describe() => _compact([
    _fromText('Tender/Quotation no.', tenderNoQuery),
    _fromText('Committee member', memberQuery),
    _fromOption('Document type', documentType),
    _fromOption('Envelope', envelopeType),
    _fromSet('Status', statuses),
    _fromRange('Closing', closingDateRange),
  ]);
}

extension TenderSecurityFilterCriteria on TenderSecurityFilters {
  List<ReportCriterion> describe() => _compact([
    _fromText('Tender/Quotation no.', tenderNoQuery),
    _fromText('Vendor', vendorQuery),
    _fromOption('Payment type', paymentType),
    // The named view is a filter like any other, and the one most likely
    // to explain a short report.
    view == TenderSecurityView.all ? null : ReportCriterion('View', view.label),
  ]);
}

extension VtmMonitoringFilterCriteria on VtmMonitoringFilters {
  List<ReportCriterion> describe() => _compact([
    _fromText('eRFC no.', erfcNoQuery),
    _fromText('Tender/Quotation no.', tenderNoQuery),
    _fromOption('Document type', documentType),
    _fromSet('Status', statuses),
    _fromOption('Procurement mode', modeOfProcurement),
    _fromOption('Division', division),
    _fromRange('eRFC endorsed', endorsedDateRange),
  ]);
}
