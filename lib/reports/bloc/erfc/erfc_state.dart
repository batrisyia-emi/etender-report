// lib/reports/bloc/erfc/erfc_state.dart
import 'package:equatable/equatable.dart';

import 'package:etender_reports/reports/models/erfc_status.dart';
import 'package:etender_reports/reports/models/procurement_modes.dart';
import 'package:etender_reports/reports/models/record_matching.dart';
import 'package:etender_reports/reports/models/report_filters.dart';
import 'package:etender_reports/reports/bloc/report_status.dart';

class ErfcState extends Equatable {
  const ErfcState({
    this.status = ReportStatus.initial,
    this.records = const [],
    this.filters = const ErfcFilters(),
    this.errorMessage,
  });

  final ReportStatus status;
  final List<Map<String, dynamic>> records;
  final ErfcFilters filters;
  final String? errorMessage;

  /// The eRFC lifecycle in funnel order, straight off [ErfcStatus].
  static List<String> get lifecycleStatuses => ErfcStatus.wireValues;

  List<Map<String, dynamic>> get filteredRecords =>
      records.where(filters.matches).toList();

  /// Fixed rather than derived: only some modes appear in the data at any
  /// time, but all of them must stay selectable.
  List<String> get procurementModeOptions => kProcurementModes;

  List<String> get divisionOptions => distinctValues(records, 'division');
  List<String> get departmentOptions => distinctValues(records, 'department');
  List<String> get unitOptions => distinctValues(records, 'unit');

  ErfcState copyWith({
    ReportStatus? status,
    List<Map<String, dynamic>>? records,
    ErfcFilters? filters,
    String? errorMessage,
  }) {
    return ErfcState(
      status: status ?? this.status,
      records: records ?? this.records,
      filters: filters ?? this.filters,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, records, filters, errorMessage];
}
