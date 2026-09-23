// lib/reports/bloc/tender_summary/tender_summary_state.dart
import 'package:equatable/equatable.dart';

import 'package:etender_reports/reports/models/procurement_modes.dart';
import 'package:etender_reports/reports/models/record_matching.dart';
import 'package:etender_reports/reports/models/report_filters.dart';
import 'package:etender_reports/reports/models/tender_status.dart';
import 'package:etender_reports/reports/models/tender_attributes.dart';
import 'package:etender_reports/reports/bloc/report_status.dart';

class TenderSummaryState extends Equatable {
  const TenderSummaryState({
    this.status = ReportStatus.initial,
    this.records = const [],
    this.filters = const TenderFilters(),
    this.errorMessage,
  });

  final ReportStatus status;
  final List<Map<String, dynamic>> records;
  final TenderFilters filters;
  final String? errorMessage;

  /// Derived rather than stored: one source of truth, no chance of the list
  /// and the filters drifting apart.
  List<Map<String, dynamic>> get filteredRecords =>
      records.where(filters.matches).toList();

  /// Fixed rather than derived: only some modes appear in the data at any
  /// time, but all of them must stay selectable, so the filter can answer
  /// "any Variation Orders?" with a confident no.
  List<String> get procurementModeOptions => kProcurementModes;

  /// Independent of the mode: every tender is one or the other, in any
  /// combination with its procurement route.
  List<String> get envelopeTypeOptions => kEnvelopeTypes;
  List<String> get itemTypeOptions => kItemTypes;

  /// Work | Service | Supply & Delivery, fixed for the same reason.
  List<String> get categoryOptions => kTenderCategories;

  /// The tender/quotation lifecycle in funnel order, straight off
  /// [TenderStatus].
  ///
  /// Fixed for the same reason as the modes above: a status absent from the
  /// current page of data must still be selectable.
  static List<String> get lifecycleStatuses => TenderStatus.wireValues;

  List<String> get statusOptions => lifecycleStatuses;
  List<String> get divisionOptions => distinctValues(records, 'division');
  List<String> get departmentOptions => distinctValues(records, 'department');
  List<String> get unitOptions => distinctValues(records, 'unit');

  TenderSummaryState copyWith({
    ReportStatus? status,
    List<Map<String, dynamic>>? records,
    TenderFilters? filters,
    String? errorMessage,
  }) {
    return TenderSummaryState(
      status: status ?? this.status,
      records: records ?? this.records,
      filters: filters ?? this.filters,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, records, filters, errorMessage];
}
