// lib/reports/models/report_filters.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show DateTimeRange;

import 'package:etender_reports/reports/models/erfc_metrics.dart';
import 'package:etender_reports/reports/models/record_matching.dart';
import 'package:etender_reports/reports/models/supplier_metrics.dart';

/// Sentinel so copyWith can tell "not supplied" from "set to null".
const Object _unset = Object();

enum TenderDateField { endorsed, closing }

/// Filters for the tender/quotation summary report. Immutable, and owns its
/// own matching rule so the bloc stays thin and this stays unit-testable.
class TenderFilters extends Equatable {
  const TenderFilters({
    this.searchQuery = '',
    this.statuses = const {},
    this.categories = const {},
    this.procurementModes = const {},
    this.envelopeType,
    this.itemType,
    this.divisions = const {},
    this.departments = const {},
    this.units = const {},
    this.minimumValue,
    this.maximumValue,
    this.endorsedDateRange,
    this.closingDateRange,
  });

  final String searchQuery;
  final Set<String> statuses;
  final Set<String> categories;

  /// Empty means every mode, the same convention the other multi-selects use.
  final Set<String> procurementModes;

  /// 1 Envelope / 2 Envelope. Null means no envelope filter.
  final String? envelopeType;

  /// Stock Item / Non-Stock Item. Null means no item-type filter.
  final String? itemType;
  final Set<String> divisions;
  final Set<String> departments;
  final Set<String> units;
  final double? minimumValue;
  final double? maximumValue;
  final DateTimeRange? endorsedDateRange;
  final DateTimeRange? closingDateRange;

  static const List<String> searchKeys = [
    'referenceNo',
    'tenderNo',
    'title',
    'erfcId',
    'createdBy',
    'lastUpdatedBy',
  ];

  bool matches(Map<String, dynamic> record) {
    final value = double.tryParse(record['value']?.toString() ?? '') ?? 0;

    return matchesQuery(record, searchKeys, searchQuery) &&
        matchesAnyOf(statuses, record['status']) &&
        matchesAnyOf(categories, record['tenderCategory']) &&
        matchesAnyOf(procurementModes, record['modeOfProcurement']) &&
        matchesOptional(envelopeType, record['envelopeType']) &&
        matchesOptional(itemType, record['itemType']) &&
        matchesAnyOf(divisions, record['division']) &&
        matchesAnyOf(departments, record['department']) &&
        matchesAnyOf(units, record['unit']) &&
        (minimumValue == null || value >= minimumValue!) &&
        (maximumValue == null || value <= maximumValue!) &&
        matchesDateRange(
          parseRecordDate(record['endorsedDate']),
          endorsedDateRange,
        ) &&
        matchesDateRange(
          parseRecordDate(record['closingDate']),
          closingDateRange,
        );
  }

  /// True when [candidate] is exactly what the status filter already holds.
  bool hasExactStatuses(Set<String> candidate) =>
      statuses.length == candidate.length && statuses.containsAll(candidate);

  /// Applies [candidate] as the status filter, or clears it when that is
  /// already the selection — so tapping the same overview card twice gets
  /// you back to all records.
  TenderFilters toggleStatuses(Set<String> candidate) => copyWith(
    statuses: hasExactStatuses(candidate) ? const <String>{} : candidate,
  );

  TenderFilters withRange(TenderDateField field, DateTimeRange? range) {
    return switch (field) {
      TenderDateField.endorsed => copyWith(endorsedDateRange: range),
      TenderDateField.closing => copyWith(closingDateRange: range),
    };
  }

  TenderFilters copyWith({
    String? searchQuery,
    Set<String>? statuses,
    Set<String>? categories,
    Set<String>? procurementModes,
    Object? envelopeType = _unset,
    Object? itemType = _unset,
    Set<String>? divisions,
    Set<String>? departments,
    Set<String>? units,
    Object? minimumValue = _unset,
    Object? maximumValue = _unset,
    Object? endorsedDateRange = _unset,
    Object? closingDateRange = _unset,
  }) {
    return TenderFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      statuses: statuses ?? this.statuses,
      categories: categories ?? this.categories,
      procurementModes: procurementModes ?? this.procurementModes,
      envelopeType: identical(envelopeType, _unset)
          ? this.envelopeType
          : envelopeType as String?,
      itemType: identical(itemType, _unset)
          ? this.itemType
          : itemType as String?,
      divisions: divisions ?? this.divisions,
      departments: departments ?? this.departments,
      units: units ?? this.units,
      minimumValue: identical(minimumValue, _unset)
          ? this.minimumValue
          : minimumValue as double?,
      maximumValue: identical(maximumValue, _unset)
          ? this.maximumValue
          : maximumValue as double?,
      endorsedDateRange: identical(endorsedDateRange, _unset)
          ? this.endorsedDateRange
          : endorsedDateRange as DateTimeRange?,
      closingDateRange: identical(closingDateRange, _unset)
          ? this.closingDateRange
          : closingDateRange as DateTimeRange?,
    );
  }

  @override
  List<Object?> get props => [
    searchQuery,
    statuses,
    categories,
    procurementModes,
    envelopeType,
    itemType,
    divisions,
    departments,
    units,
    minimumValue,
    maximumValue,
    endorsedDateRange,
    closingDateRange,
  ];
}

/// Filters for the vendor participation report. All single-select, per the
/// report spec, plus free-text search and a submission date range.
class VendorFilters extends Equatable {
  const VendorFilters({
    this.searchQuery = '',
    this.tenderIds = const {},
    this.openTo,
    this.certificationTypes = const {},
    this.invitationStatus,
    this.purchaseOption,
    this.participationStatus,
    this.submissionStatuses = const {},
    this.submissionDateRange,
  });

  final String searchQuery;

  /// Empty means every tender, the convention the other multi-selects use.
  final Set<String> tenderIds;
  final String? openTo;
  final Set<String> certificationTypes;

  /// Binary, so a single select: picking both would mean picking neither.
  final String? invitationStatus;
  final String? purchaseOption;

  /// Participated or Rejected: whether the vendor took up the invitation.
  final String? participationStatus;

  final Set<String> submissionStatuses;
  final DateTimeRange? submissionDateRange;

  static const List<String> searchKeys = [
    'vendorName',
    'tenderNo',
    'referenceNo',
    'title',
    'certificationType',
    'vendorCategory',
  ];

  bool matches(Map<String, dynamic> record) {
    final purchaseLabel = record['documentPurchased'] == true ? 'Yes' : 'No';

    return matchesQuery(record, searchKeys, searchQuery) &&
        matchesAnyOf(tenderIds, record['tenderNo']) &&
        matchesOptional(openTo, record['openTo']) &&
        matchesAnyOf(certificationTypes, record['certificationType']) &&
        matchesOptional(invitationStatus, record['invitationStatus']) &&
        matchesOptional(purchaseOption, purchaseLabel) &&
        matchesOptional(participationStatus, record['participationStatus']) &&
        matchesAnyOf(submissionStatuses, record['submissionStatus']) &&
        matchesDateRange(
          parseRecordDate(record['submissionDateTime']),
          submissionDateRange,
        );
  }

  bool hasExactSubmissionStatuses(Set<String> candidate) =>
      submissionStatuses.length == candidate.length &&
      submissionStatuses.containsAll(candidate);

  /// Each overview card applies its own slice of the funnel, or clears it
  /// when that slice is already the selection.
  VendorFilters toggleInvitationStatus(String candidate) => copyWith(
    invitationStatus: invitationStatus == candidate ? null : candidate,
  );

  VendorFilters toggleParticipationStatus(String candidate) => copyWith(
    participationStatus: participationStatus == candidate ? null : candidate,
  );

  VendorFilters togglePurchaseOption(String candidate) =>
      copyWith(purchaseOption: purchaseOption == candidate ? null : candidate);

  VendorFilters toggleSubmissionStatuses(Set<String> candidate) => copyWith(
    submissionStatuses: hasExactSubmissionStatuses(candidate)
        ? const <String>{}
        : candidate,
  );

  VendorFilters copyWith({
    String? searchQuery,
    Set<String>? tenderIds,
    Object? openTo = _unset,
    Set<String>? certificationTypes,
    Object? invitationStatus = _unset,
    Object? purchaseOption = _unset,
    Object? participationStatus = _unset,
    Set<String>? submissionStatuses,
    Object? submissionDateRange = _unset,
  }) {
    return VendorFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      tenderIds: tenderIds ?? this.tenderIds,
      openTo: identical(openTo, _unset) ? this.openTo : openTo as String?,
      certificationTypes: certificationTypes ?? this.certificationTypes,
      invitationStatus: identical(invitationStatus, _unset)
          ? this.invitationStatus
          : invitationStatus as String?,
      purchaseOption: identical(purchaseOption, _unset)
          ? this.purchaseOption
          : purchaseOption as String?,
      participationStatus: identical(participationStatus, _unset)
          ? this.participationStatus
          : participationStatus as String?,
      submissionStatuses: submissionStatuses ?? this.submissionStatuses,
      submissionDateRange: identical(submissionDateRange, _unset)
          ? this.submissionDateRange
          : submissionDateRange as DateTimeRange?,
    );
  }

  @override
  List<Object?> get props => [
    searchQuery,
    tenderIds,
    openTo,
    certificationTypes,
    invitationStatus,
    purchaseOption,
    participationStatus,
    submissionStatuses,
    submissionDateRange,
  ];
}

/// Filters for the eRFC lifecycle report: RFC number or division via search,
/// plus division, procurement mode, status and submission window.
class ErfcFilters extends Equatable {
  const ErfcFilters({
    this.searchQuery = '',
    this.divisions = const {},
    this.units = const {},
    this.procurementModes = const {},
    this.statuses = const {},
    this.submissionDateRange,
    this.overdueOnly = false,
  });

  final String searchQuery;
  final Set<String> divisions;
  final Set<String> units;

  /// Empty means every mode, the same convention the other multi-selects use.
  final Set<String> procurementModes;
  final Set<String> statuses;
  final DateTimeRange? submissionDateRange;

  /// Narrows to in-flight RFCs past the overdue threshold.
  final bool overdueOnly;

  static const List<String> searchKeys = [
    'rfcNumber',
    'division',
    'department',
    'unit',
    'createdBy',
  ];

  bool matches(Map<String, dynamic> record) {
    return matchesQuery(record, searchKeys, searchQuery) &&
        matchesAnyOf(divisions, record['division']) &&
        matchesAnyOf(units, record['unit']) &&
        matchesAnyOf(procurementModes, record['modeOfProcurement']) &&
        matchesAnyOf(statuses, record['status']) &&
        matchesDateRange(
          parseRecordDate(record['submissionDate']),
          submissionDateRange,
        ) &&
        (!overdueOnly || erfcIsOverdue(record));
  }

  /// True when [candidate] is exactly what the status filter already holds.
  bool hasExactStatuses(Set<String> candidate) =>
      statuses.length == candidate.length && statuses.containsAll(candidate);

  /// Applies [candidate], or clears it when that is already the selection,
  /// so tapping the same overview card twice returns to all records.
  ErfcFilters toggleStatuses(Set<String> candidate) => copyWith(
    statuses: hasExactStatuses(candidate) ? const <String>{} : candidate,
  );

  ErfcFilters toggleOverdueOnly() => copyWith(overdueOnly: !overdueOnly);

  ErfcFilters copyWith({
    String? searchQuery,
    Set<String>? divisions,
    Set<String>? units,
    Set<String>? procurementModes,
    Set<String>? statuses,
    Object? submissionDateRange = _unset,
    bool? overdueOnly,
  }) {
    return ErfcFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      divisions: divisions ?? this.divisions,
      units: units ?? this.units,
      procurementModes: procurementModes ?? this.procurementModes,
      statuses: statuses ?? this.statuses,
      submissionDateRange: identical(submissionDateRange, _unset)
          ? this.submissionDateRange
          : submissionDateRange as DateTimeRange?,
      overdueOnly: overdueOnly ?? this.overdueOnly,
    );
  }

  @override
  List<Object?> get props => [
    searchQuery,
    divisions,
    units,
    procurementModes,
    statuses,
    submissionDateRange,
    overdueOnly,
  ];
}

/// Filters for the supplier report: where the supplier's own request has
/// reached. Multi-select throughout, plus free-text search, a request
/// window and the pending-payment shortcut.
///
/// No supplier or tender-number picker: the report is one supplier's own,
/// so neither narrowed anything it is allowed to see.
class SupplierFilters extends Equatable {
  const SupplierFilters({
    this.searchQuery = '',
    this.statuses = const {},
    this.categories = const {},
    this.divisions = const {},
    this.openTo,
    this.requestDateRange,
    this.closingDateRange,
    this.pendingPaymentOnly = false,
  });

  final String searchQuery;

  /// Empty means every status, the convention the other multi-selects use.
  final Set<String> statuses;
  final Set<String> categories;
  final Set<String> divisions;

  /// Appendix A 8.1 eligibility. Single-select, like the vendor report's.
  final String? openTo;

  final DateTimeRange? requestDateRange;
  final DateTimeRange? closingDateRange;

  /// Narrows to the rows that owe a document fee.
  final bool pendingPaymentOnly;

  static const List<String> searchKeys = [
    'supplierName',
    'supplierId',
    'tenderNo',
    'referenceNo',
    'title',
  ];

  bool matches(Map<String, dynamic> record) {
    return matchesQuery(record, searchKeys, searchQuery) &&
        matchesAnyOf(statuses, record['status']) &&
        matchesAnyOf(categories, record['tenderCategory']) &&
        matchesAnyOf(divisions, record['division']) &&
        matchesOptional(openTo, record['openTo']) &&
        matchesDateRange(
          parseRecordDate(record['requestDate']),
          requestDateRange,
        ) &&
        matchesDateRange(
          parseRecordDate(record['closingDate']),
          closingDateRange,
        ) &&
        (!pendingPaymentOnly || supplierIsAwaitingPayment(record));
  }

  /// True when [candidate] is exactly what the status filter already holds.
  bool hasExactStatuses(Set<String> candidate) =>
      statuses.length == candidate.length && statuses.containsAll(candidate);

  /// Applies [candidate], or clears it when that is already the selection,
  /// so tapping the same overview card twice returns to all records.
  SupplierFilters toggleStatuses(Set<String> candidate) => copyWith(
    statuses: hasExactStatuses(candidate) ? const <String>{} : candidate,
  );

  SupplierFilters togglePendingPaymentOnly() =>
      copyWith(pendingPaymentOnly: !pendingPaymentOnly);

  SupplierFilters copyWith({
    String? searchQuery,
    Set<String>? statuses,
    Set<String>? categories,
    Set<String>? divisions,
    Object? openTo = _unset,
    Object? requestDateRange = _unset,
    Object? closingDateRange = _unset,
    bool? pendingPaymentOnly,
  }) {
    return SupplierFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      statuses: statuses ?? this.statuses,
      categories: categories ?? this.categories,
      divisions: divisions ?? this.divisions,
      openTo: identical(openTo, _unset) ? this.openTo : openTo as String?,
      requestDateRange: identical(requestDateRange, _unset)
          ? this.requestDateRange
          : requestDateRange as DateTimeRange?,
      closingDateRange: identical(closingDateRange, _unset)
          ? this.closingDateRange
          : closingDateRange as DateTimeRange?,
      pendingPaymentOnly: pendingPaymentOnly ?? this.pendingPaymentOnly,
    );
  }

  @override
  List<Object?> get props => [
    searchQuery,
    statuses,
    categories,
    divisions,
    openTo,
    requestDateRange,
    closingDateRange,
    pendingPaymentOnly,
  ];
}
