// lib/reports/bloc/vendor_participation_event.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show DateTimeRange;

sealed class VendorParticipationEvent extends Equatable {
  const VendorParticipationEvent();

  @override
  List<Object?> get props => [];
}

final class VendorDataRequested extends VendorParticipationEvent {
  const VendorDataRequested();
}

final class VendorSearchChanged extends VendorParticipationEvent {
  const VendorSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class VendorOpenToChanged extends VendorParticipationEvent {
  const VendorOpenToChanged(this.openTo);

  final String? openTo;

  @override
  List<Object?> get props => [openTo];
}

final class VendorCertificationTypesChanged extends VendorParticipationEvent {
  const VendorCertificationTypesChanged(this.certificationTypes);

  final Set<String> certificationTypes;

  @override
  List<Object?> get props => [certificationTypes];
}

/// Sent by the overview cards, each of which applies its slice of the
/// funnel or clears it when already selected.
final class VendorPurchaseOptionChanged extends VendorParticipationEvent {
  const VendorPurchaseOptionChanged(this.purchaseOption);

  final String? purchaseOption;

  @override
  List<Object?> get props => [purchaseOption];
}

final class VendorSubmissionStatusChanged extends VendorParticipationEvent {
  const VendorSubmissionStatusChanged(this.status);

  /// Null clears the filter back to every respond status.
  final String? status;

  @override
  List<Object?> get props => [status];
}

final class VendorRequestedDateChanged extends VendorParticipationEvent {
  const VendorRequestedDateChanged(this.range);

  final DateTimeRange? range;

  @override
  List<Object?> get props => [range];
}

final class VendorFiltersCleared extends VendorParticipationEvent {
  const VendorFiltersCleared();
}
