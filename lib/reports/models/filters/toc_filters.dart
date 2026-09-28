// lib/reports/models/filters/toc_filters.dart
//
// Filters for the TOC report.
//
// Unlike the other four reports, these match against [TocOpeningRecord]
// rather than a raw map. The committee is a nested list, which a
// stringly-typed filter cannot search without re-parsing it on every
// keystroke.
import 'package:etender_reports/reports/models/records/toc_opening_record.dart';
import 'package:etender_reports/reports/models/status/toc_status.dart';
import 'package:flutter/material.dart';

const Object _unset = Object();

class TocFilters {
  const TocFilters({
    this.tenderNoQuery = '',
    this.memberQuery = '',
    this.documentType,
    this.envelopeType,
    this.statuses = const {},
    this.closingDateRange,
  });

  /// Free text over the tender / quotation number.
  final String tenderNoQuery;

  /// Free text over every committee member's name and staff ID. A record
  /// matches when any one of its three members does.
  final String memberQuery;

  /// Null means both tenders and quotations.
  final String? documentType;

  /// '1 Envelope' / '2 Envelope'. Null means both, which is also what the
  /// filter falls back to — three of the eight statuses only occur under
  /// one arrangement, so narrowing by envelope narrows the status list too.
  final String? envelopeType;

  /// Empty means every status, the convention the other reports use.
  final Set<String> statuses;

  final DateTimeRange? closingDateRange;

  bool matches(TocOpeningRecord record) {
    if (!_matchesTenderNo(record)) return false;
    if (!_matchesMember(record)) return false;
    if (documentType != null && record.documentType != documentType) {
      return false;
    }
    if (statuses.isNotEmpty && !statuses.contains(record.status)) {
      return false;
    }
    if (envelopeType != null && record.envelopeType != envelopeType) {
      return false;
    }
    return _matchesClosing(record);
  }

  bool _matchesTenderNo(TocOpeningRecord record) {
    if (tenderNoQuery.isEmpty) return true;
    return record.tenderNo.toLowerCase().contains(
      tenderNoQuery.toLowerCase().trim(),
    );
  }

  /// Matches a member's name or their staff ID, so either identifier the
  /// user happens to have works.
  bool _matchesMember(TocOpeningRecord record) {
    if (memberQuery.isEmpty) return true;
    final needle = memberQuery.toLowerCase().trim();
    for (final member in record.committee) {
      if (member.name.toLowerCase().contains(needle) ||
          member.staffId.toLowerCase().contains(needle)) {
        return true;
      }
    }
    return false;
  }

  bool _matchesClosing(TocOpeningRecord record) {
    final range = closingDateRange;
    if (range == null) return true;
    final closing = record.closingDateTime;
    if (closing == null) return false;
    final day = DateTime(closing.year, closing.month, closing.day);
    final from = DateTime(range.start.year, range.start.month, range.start.day);
    final to = DateTime(range.end.year, range.end.month, range.end.day);
    return !day.isBefore(from) && !day.isAfter(to);
  }

  /// True when [candidate] is exactly what the status filter already holds.
  bool hasExactStatuses(Set<String> candidate) =>
      statuses.length == candidate.length && statuses.containsAll(candidate);

  /// Applies [candidate], or clears it when that is already the selection,
  /// so tapping the same summary card twice returns to all records.
  TocFilters toggleStatuses(Set<String> candidate) => copyWith(
    statuses: hasExactStatuses(candidate) ? const <String>{} : candidate,
  );

  bool get isEmpty =>
      tenderNoQuery.isEmpty &&
      memberQuery.isEmpty &&
      documentType == null &&
      envelopeType == null &&
      statuses.isEmpty &&
      closingDateRange == null;

  TocFilters copyWith({
    String? tenderNoQuery,
    String? memberQuery,
    Object? documentType = _unset,
    Object? envelopeType = _unset,
    Set<String>? statuses,
    Object? closingDateRange = _unset,
  }) {
    return TocFilters(
      tenderNoQuery: tenderNoQuery ?? this.tenderNoQuery,
      memberQuery: memberQuery ?? this.memberQuery,
      documentType: identical(documentType, _unset)
          ? this.documentType
          : documentType as String?,
      envelopeType: identical(envelopeType, _unset)
          ? this.envelopeType
          : envelopeType as String?,
      statuses: statuses ?? this.statuses,
      closingDateRange: identical(closingDateRange, _unset)
          ? this.closingDateRange
          : closingDateRange as DateTimeRange?,
    );
  }

  /// The filter's own option list, so the panel never derives it from data
  /// that happens to be loaded.
  static List<String> get statusOptions => TocStatus.wireValues;
  static List<String> get documentTypeOptions => TocDocumentType.wireValues;
  static List<String> get envelopeTypeOptions => TocEnvelopeType.wireValues;
}
