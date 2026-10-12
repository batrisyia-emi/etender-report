// lib/reports/bloc/vendor_participation/vendor_participation_state.dart
import 'package:equatable/equatable.dart';
import 'package:etender_reports/reports/bloc/report_status.dart';
import 'package:etender_reports/reports/models/attributes/certification_types.dart';
import 'package:etender_reports/reports/models/attributes/open_to.dart';
import 'package:etender_reports/reports/models/filters/report_filters.dart';

class VendorParticipationState extends Equatable {
  const VendorParticipationState({
    this.status = ReportStatus.initial,
    this.records = const [],
    this.filters = const VendorFilters(),
    this.errorMessage,
  });

  final ReportStatus status;
  final List<Map<String, dynamic>> records;
  final VendorFilters filters;
  final String? errorMessage;

  /// Fixed option lists. Derived lists would only offer what the current
  /// page happens to contain, so an option with no matching row would
  /// vanish instead of returning an honest empty result.
  static const List<String> certificationTypes = kCertificationTypes;
  static const List<String> purchaseOptions = ['Yes', 'No'];

  /// Where a vendor has got to with one tender, in order.
  ///
  /// The same nine states the supplier sees on its own report —
  /// this is that journey from SE's side. Declared rather than
  /// derived, so a state no row holds today stays selectable.
  static const List<String> respondStatuses = [
    'Participation Requested',
    'Request Rejected',
    'Request Approved',
    'Pending Payment',
    'Paid',
    'Participated',
    'Not Participate',
    'Save',
    'Submitted',
  ];

  /// Appendix A section 8.1 — the tender's eligibility rule. The display
  /// text and contract thresholds live on the OpenTo enum.
  List<String> get openToOptions => OpenTo.wireValues;

  /// Derived, because tender numbers grow with the data.

  List<Map<String, dynamic>> get filteredRecords =>
      records.where(filters.matches).toList();

  VendorParticipationState copyWith({
    ReportStatus? status,
    List<Map<String, dynamic>>? records,
    VendorFilters? filters,
    String? errorMessage,
  }) {
    return VendorParticipationState(
      status: status ?? this.status,
      records: records ?? this.records,
      filters: filters ?? this.filters,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, records, filters, errorMessage];
}
