// lib/reports/bloc/tender_security/tender_security_event.dart
import 'package:equatable/equatable.dart';
import 'package:etender_reports/reports/models/filters/tender_security_filters.dart';

sealed class TenderSecurityEvent extends Equatable {
  const TenderSecurityEvent();

  @override
  List<Object?> get props => const [];
}

final class TenderSecurityDataRequested extends TenderSecurityEvent {
  const TenderSecurityDataRequested();
}

final class TenderSecurityTenderNoQueryChanged extends TenderSecurityEvent {
  const TenderSecurityTenderNoQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class TenderSecurityVendorQueryChanged extends TenderSecurityEvent {
  const TenderSecurityVendorQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class TenderSecurityPaymentTypeChanged extends TenderSecurityEvent {
  const TenderSecurityPaymentTypeChanged(this.paymentType);

  /// Null clears the filter back to every type.
  final String? paymentType;

  @override
  List<Object?> get props => [paymentType];
}

final class TenderSecurityViewChanged extends TenderSecurityEvent {
  const TenderSecurityViewChanged(this.view);

  final TenderSecurityView view;

  @override
  List<Object?> get props => [view];
}

/// Applies a view, or returns to All when it is already the selection —
/// what the summary cards do when tapped.
final class TenderSecurityViewToggled extends TenderSecurityEvent {
  const TenderSecurityViewToggled(this.view);

  final TenderSecurityView view;

  @override
  List<Object?> get props => [view];
}

final class TenderSecurityFiltersCleared extends TenderSecurityEvent {
  const TenderSecurityFiltersCleared();
}

/// One of the four VTM-owned fields was edited in the table.
///
/// The bloc applies this to its own copy so the control responds. Sending it
/// to the server is the view's job, through `ReportActions`, because this
/// bloc has no writer.
final class TenderSecurityFieldEdited extends TenderSecurityEvent {
  const TenderSecurityFieldEdited({
    required this.uniqueNo,
    this.originalCopyReceived,
    this.submittedToRevenueAssuranceDate,
    this.clearSubmittedToRevenueAssuranceDate = false,
    this.unsuccessfulTenderer,
    this.clearUnsuccessfulTenderer = false,
    this.refundDate,
    this.clearRefundDate = false,
  });

  final String uniqueNo;
  final bool? originalCopyReceived;
  final DateTime? submittedToRevenueAssuranceDate;
  final bool clearSubmittedToRevenueAssuranceDate;
  final String? unsuccessfulTenderer;
  final bool clearUnsuccessfulTenderer;
  final DateTime? refundDate;
  final bool clearRefundDate;

  @override
  List<Object?> get props => [
    uniqueNo,
    originalCopyReceived,
    submittedToRevenueAssuranceDate,
    clearSubmittedToRevenueAssuranceDate,
    unsuccessfulTenderer,
    clearUnsuccessfulTenderer,
    refundDate,
    clearRefundDate,
  ];
}
