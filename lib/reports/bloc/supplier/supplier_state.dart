// lib/reports/bloc/supplier/supplier_state.dart
import 'package:equatable/equatable.dart';

import 'package:etender_reports/reports/models/open_to.dart';
import 'package:etender_reports/reports/models/record_matching.dart';
import 'package:etender_reports/reports/models/report_filters.dart';
import 'package:etender_reports/reports/models/supplier_status.dart';
import 'package:etender_reports/reports/models/tender_attributes.dart';
import 'package:etender_reports/reports/bloc/report_status.dart';

class SupplierState extends Equatable {
  const SupplierState({
    this.status = ReportStatus.initial,
    this.records = const [],
    this.filters = const SupplierFilters(),
    this.errorMessage,
  });

  final ReportStatus status;
  final List<Map<String, dynamic>> records;
  final SupplierFilters filters;
  final String? errorMessage;

  /// The supplier lifecycle in portal order, straight off [SupplierStatus].
  static List<String> get lifecycleStatuses => SupplierStatus.wireValues;

  List<Map<String, dynamic>> get filteredRecords =>
      records.where(filters.matches).toList();

  /// Appendix A 8.1 — the tender's eligibility rule.
  List<String> get openToOptions => OpenTo.wireValues;

  /// Fixed rather than derived: a category with no row today must stay
  /// selectable, so the filter returns an honest empty result.
  List<String> get categoryOptions => kTenderCategories;

  /// Derived, because these grow with the data.
  List<String> get divisionOptions => distinctValues(records, 'division');

  SupplierState copyWith({
    ReportStatus? status,
    List<Map<String, dynamic>>? records,
    SupplierFilters? filters,
    String? errorMessage,
  }) {
    return SupplierState(
      status: status ?? this.status,
      records: records ?? this.records,
      filters: filters ?? this.filters,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, records, filters, errorMessage];
}
