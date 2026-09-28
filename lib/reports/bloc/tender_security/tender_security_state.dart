// lib/reports/bloc/tender_security/tender_security_state.dart
import 'package:equatable/equatable.dart';
import 'package:etender_reports/reports/bloc/report_status.dart';
import 'package:etender_reports/reports/models/records/tender_security_record.dart';
import 'package:etender_reports/reports/models/tender_security_filters.dart';

/// Holds typed records rather than maps, like the TOC report: four of the
/// columns are edited in place, and patching a map row by key is how a typo
/// becomes a silent no-op.
class TenderSecurityState extends Equatable {
  const TenderSecurityState({
    this.status = ReportStatus.initial,
    this.records = const [],
    this.filters = const TenderSecurityFilters(),
    this.errorMessage,
  });

  final ReportStatus status;
  final List<TenderSecurityRecord> records;
  final TenderSecurityFilters filters;
  final String? errorMessage;

  List<TenderSecurityRecord> get filteredRecords =>
      records.where(filters.matches).toList();

  /// Fixed rather than derived: a view with no row today must stay
  /// selectable, so it returns an honest empty result.
  static List<String> get viewOptions => TenderSecurityFilters.viewOptions;
  static List<String> get paymentTypeOptions =>
      TenderSecurityFilters.paymentTypeOptions;

  TenderSecurityState copyWith({
    ReportStatus? status,
    List<TenderSecurityRecord>? records,
    TenderSecurityFilters? filters,
    String? errorMessage,
  }) {
    return TenderSecurityState(
      status: status ?? this.status,
      records: records ?? this.records,
      filters: filters ?? this.filters,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, records, filters, errorMessage];
}
