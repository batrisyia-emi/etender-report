// lib/reports/bloc/toc/toc_state.dart
import 'package:equatable/equatable.dart';
import 'package:etender_reports/reports/bloc/report_status.dart';
import 'package:etender_reports/reports/models/filters/toc_filters.dart';
import 'package:etender_reports/reports/models/records/toc_opening_record.dart';
import 'package:etender_reports/reports/models/status/toc_status.dart';

/// Unlike the other reports, this one holds typed records rather than maps.
/// The committee is a nested list, and re-parsing it on every filter pass
/// would be both slower and easier to get wrong.
class TocState extends Equatable {
  const TocState({
    this.status = ReportStatus.initial,
    this.records = const [],
    this.filters = const TocFilters(),
    this.errorMessage,
  });

  final ReportStatus status;
  final List<TocOpeningRecord> records;
  final TocFilters filters;
  final String? errorMessage;

  List<TocOpeningRecord> get filteredRecords =>
      records.where(filters.matches).toList();

  /// Fixed rather than derived: a status with no record today must stay
  /// selectable, so the filter returns an honest empty result.
  static List<String> get statusOptions => TocStatus.wireValues;
  static List<String> get documentTypeOptions => TocDocumentType.wireValues;
  static List<String> get envelopeTypeOptions => TocEnvelopeType.wireValues;

  TocState copyWith({
    ReportStatus? status,
    List<TocOpeningRecord>? records,
    TocFilters? filters,
    String? errorMessage,
  }) {
    return TocState(
      status: status ?? this.status,
      records: records ?? this.records,
      filters: filters ?? this.filters,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, records, filters, errorMessage];
}
