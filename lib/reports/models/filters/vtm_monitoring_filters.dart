// lib/reports/models/filters/vtm_monitoring_filters.dart
//
// Filters for the VTM Tender/Quotation Monitoring report, matching the
// seven the spec names.
//
// Typed against [VtmMonitoringRecord] rather than a map, like the TOC and
// tender security reports.
import 'package:etender_reports/reports/models/records/vtm_monitoring_record.dart';
import 'package:etender_reports/reports/models/status/vtm_monitoring_status.dart';
import 'package:flutter/material.dart';

const Object _unset = Object();

class VtmMonitoringFilters {
  const VtmMonitoringFilters({
    this.tenderNoQuery = '',
    this.erfcNoQuery = '',
    this.documentType,
    this.statuses = const {},
    this.modeOfProcurement,
    this.division,
    this.endorsedDateRange,
  });

  /// Free text over the tender / quotation number. Matches nothing on the
  /// rows that have no number yet, which is most of them — that is what the
  /// eRFC search below is for.
  final String tenderNoQuery;

  /// Free text over the eRFC number, the key every row carries.
  final String erfcNoQuery;

  /// Null means both tenders and quotations.
  final String? documentType;

  /// [VtmStatus] codes. Empty means every status, the convention the other
  /// reports use.
  final Set<String> statuses;

  /// A [VtmProcurementMode] code. Null means every mode.
  final String? modeOfProcurement;

  final String? division;

  final DateTimeRange? endorsedDateRange;

  bool matches(VtmMonitoringRecord record) {
    if (!_contains(record.tenderQuotationNo ?? '', tenderNoQuery)) return false;
    if (!_contains(record.erfcNo, erfcNoQuery)) return false;
    if (documentType != null && record.documentType != documentType) {
      return false;
    }
    if (statuses.isNotEmpty && !statuses.contains(record.status)) return false;
    if (modeOfProcurement != null &&
        record.modeOfProcurement != modeOfProcurement) {
      return false;
    }
    if (division != null && record.division != division) return false;
    return _matchesEndorsed(record);
  }

  static bool _contains(String value, String query) =>
      query.isEmpty || value.toLowerCase().contains(query.toLowerCase().trim());

  bool _matchesEndorsed(VtmMonitoringRecord record) {
    final range = endorsedDateRange;
    if (range == null) return true;
    final endorsed = record.endorsedDate;
    if (endorsed == null) return false;
    final day = DateTime(endorsed.year, endorsed.month, endorsed.day);
    final from = DateTime(range.start.year, range.start.month, range.start.day);
    final to = DateTime(range.end.year, range.end.month, range.end.day);
    return !day.isBefore(from) && !day.isAfter(to);
  }

  /// True when [candidate] is exactly what the status filter already holds.
  bool hasExactStatuses(Set<String> candidate) =>
      statuses.length == candidate.length && statuses.containsAll(candidate);

  /// Applies [candidate], or clears it when that is already the selection,
  /// so tapping the same summary card twice returns to all records.
  VtmMonitoringFilters toggleStatuses(Set<String> candidate) => copyWith(
    statuses: hasExactStatuses(candidate) ? const <String>{} : candidate,
  );

  bool get isEmpty =>
      tenderNoQuery.isEmpty &&
      erfcNoQuery.isEmpty &&
      documentType == null &&
      statuses.isEmpty &&
      modeOfProcurement == null &&
      division == null &&
      endorsedDateRange == null;

  VtmMonitoringFilters copyWith({
    String? tenderNoQuery,
    String? erfcNoQuery,
    Object? documentType = _unset,
    Set<String>? statuses,
    Object? modeOfProcurement = _unset,
    Object? division = _unset,
    Object? endorsedDateRange = _unset,
  }) {
    return VtmMonitoringFilters(
      tenderNoQuery: tenderNoQuery ?? this.tenderNoQuery,
      erfcNoQuery: erfcNoQuery ?? this.erfcNoQuery,
      documentType: identical(documentType, _unset)
          ? this.documentType
          : documentType as String?,
      statuses: statuses ?? this.statuses,
      modeOfProcurement: identical(modeOfProcurement, _unset)
          ? this.modeOfProcurement
          : modeOfProcurement as String?,
      division: identical(division, _unset)
          ? this.division
          : division as String?,
      endorsedDateRange: identical(endorsedDateRange, _unset)
          ? this.endorsedDateRange
          : endorsedDateRange as DateTimeRange?,
    );
  }

  /// The filter's own option lists, so the panel never derives them from
  /// whatever data happens to be loaded. Divisions are the exception: they
  /// are organisational, not a vocabulary, so the state supplies those.
  static List<String> get statusOptions => VtmStatus.codes;
  static Map<String, String> get statusLabels => VtmStatus.labels;
  static List<String> get documentTypeOptions => const ['Tender', 'Quotation'];
  static List<String> get modeOptions => VtmProcurementMode.codes;
  static Map<String, String> get modeLabels => VtmProcurementMode.labels;
}
