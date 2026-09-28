// lib/reports/models/tender_security_filters.dart
//
// Filters for the Tender Security report.
//
// Typed against [TenderSecurityRecord] rather than a map, like the TOC
// report and unlike the older four.
import 'package:etender_reports/reports/models/records/tender_security_record.dart';
import 'package:etender_reports/reports/models/tender_security_attributes.dart';
import 'package:etender_reports/reports/models/tender_security_metrics.dart';

const Object _unset = Object();

/// The report spec's named views, as one list.
///
/// These are not independent toggles: each is a whole question about a row,
/// and asking two at once ("expired" and "refunded") is asking for nothing.
/// So the panel offers exactly one at a time, with [all] as the way back.
enum TenderSecurityView {
  all(label: 'All'),
  originalNotReceived(label: 'Original not received'),
  notSubmitted(label: 'Not submitted to RA/CSU'),
  expiringSoon(label: 'Expiring in $kTenderSecurityExpiringSoonDays days'),
  expired(label: 'Expired'),
  pendingRefund(label: 'Pending refund'),
  refunded(label: 'Refunded');

  const TenderSecurityView({required this.label});

  final String label;

  bool matches(TenderSecurityRecord record, {DateTime? asOf}) => switch (this) {
    TenderSecurityView.all => true,
    TenderSecurityView.originalNotReceived => !record.originalCopyReceived,
    TenderSecurityView.notSubmitted => !record.isSubmittedToRevenueAssurance,
    TenderSecurityView.expiringSoon => tenderSecurityIsExpiringSoon(
      record,
      asOf: asOf,
    ),
    TenderSecurityView.expired => tenderSecurityIsExpired(record, asOf: asOf),
    TenderSecurityView.pendingRefund => tenderSecurityIsPendingRefund(record),
    TenderSecurityView.refunded => tenderSecurityIsRefunded(record),
  };

  static List<String> get labels => [
    for (final view in TenderSecurityView.values) view.label,
  ];

  static TenderSecurityView fromLabel(String label) =>
      TenderSecurityView.values.firstWhere(
        (view) => view.label == label,
        orElse: () => TenderSecurityView.all,
      );
}

class TenderSecurityFilters {
  const TenderSecurityFilters({
    this.tenderNoQuery = '',
    this.vendorQuery = '',
    this.paymentType,
    this.view = TenderSecurityView.all,
  });

  /// Free text over the tender / quotation number. The spec's only search,
  /// though the vendor search below earns its place the same way.
  final String tenderNoQuery;

  /// Free text over the tenderer's name.
  final String vendorQuery;

  /// A [PaymentType] wire value. Null means every type.
  final String? paymentType;

  final TenderSecurityView view;

  bool matches(TenderSecurityRecord record, {DateTime? asOf}) {
    if (!_contains(record.tenderNo, tenderNoQuery)) return false;
    if (!_contains(record.vendorName, vendorQuery)) return false;
    if (paymentType != null && record.paymentType != paymentType) {
      return false;
    }
    return view.matches(record, asOf: asOf);
  }

  static bool _contains(String value, String query) =>
      query.isEmpty || value.toLowerCase().contains(query.toLowerCase().trim());

  /// Applies [candidate], or returns to [TenderSecurityView.all] when it is
  /// already the selection — what the summary cards do when tapped.
  TenderSecurityFilters toggleView(TenderSecurityView candidate) =>
      copyWith(view: view == candidate ? TenderSecurityView.all : candidate);

  bool get isEmpty =>
      tenderNoQuery.isEmpty &&
      vendorQuery.isEmpty &&
      paymentType == null &&
      view == TenderSecurityView.all;

  TenderSecurityFilters copyWith({
    String? tenderNoQuery,
    String? vendorQuery,
    Object? paymentType = _unset,
    TenderSecurityView? view,
  }) {
    return TenderSecurityFilters(
      tenderNoQuery: tenderNoQuery ?? this.tenderNoQuery,
      vendorQuery: vendorQuery ?? this.vendorQuery,
      paymentType: identical(paymentType, _unset)
          ? this.paymentType
          : paymentType as String?,
      view: view ?? this.view,
    );
  }

  /// The filter's own option lists, so the panel never derives them from
  /// whatever data happens to be loaded.
  static List<String> get viewOptions => TenderSecurityView.labels;
  static List<String> get paymentTypeOptions => PaymentType.wireValues;
  static Map<String, String> get paymentTypeLabels => PaymentType.labels;
}
