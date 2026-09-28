// lib/reports/bloc/vtm_monitoring/vtm_monitoring_state.dart
import 'package:equatable/equatable.dart';
import 'package:etender_reports/reports/bloc/report_status.dart';
import 'package:etender_reports/reports/models/filters/vtm_monitoring_filters.dart';
import 'package:etender_reports/reports/models/records/vtm_monitoring_record.dart';

/// Holds typed records rather than maps, like the TOC and tender security
/// reports: the nested actor objects do not survive a map row cleanly.
class VtmMonitoringState extends Equatable {
  const VtmMonitoringState({
    this.status = ReportStatus.initial,
    this.records = const [],
    this.filters = const VtmMonitoringFilters(),
    this.errorMessage,
  });

  final ReportStatus status;
  final List<VtmMonitoringRecord> records;
  final VtmMonitoringFilters filters;
  final String? errorMessage;

  List<VtmMonitoringRecord> get filteredRecords =>
      records.where(filters.matches).toList();

  /// Divisions are organisational rather than a vocabulary, so unlike the
  /// statuses and modes they come from whatever the data holds.
  List<String> get divisionOptions {
    final seen = <String>{
      for (final record in records)
        if (record.division.isNotEmpty) record.division,
    }.toList()..sort();
    return seen;
  }

  /// Fixed rather than derived: a status with no record today must stay
  /// selectable, so the filter returns an honest empty result.
  static List<String> get statusOptions => VtmMonitoringFilters.statusOptions;
  static Map<String, String> get statusLabels =>
      VtmMonitoringFilters.statusLabels;
  static List<String> get documentTypeOptions =>
      VtmMonitoringFilters.documentTypeOptions;
  static List<String> get modeOptions => VtmMonitoringFilters.modeOptions;
  static Map<String, String> get modeLabels => VtmMonitoringFilters.modeLabels;

  VtmMonitoringState copyWith({
    ReportStatus? status,
    List<VtmMonitoringRecord>? records,
    VtmMonitoringFilters? filters,
    String? errorMessage,
  }) {
    return VtmMonitoringState(
      status: status ?? this.status,
      records: records ?? this.records,
      filters: filters ?? this.filters,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, records, filters, errorMessage];
}
