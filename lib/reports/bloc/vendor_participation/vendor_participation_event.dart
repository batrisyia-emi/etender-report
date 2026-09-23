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

final class VendorTenderIdsChanged extends VendorParticipationEvent {
  const VendorTenderIdsChanged(this.tenderIds);

  final Set<String> tenderIds;

  @override
  List<Object?> get props => [tenderIds];
}

final class VendorParticipationTypeChanged extends VendorParticipationEvent {
  const VendorParticipationTypeChanged(this.participationType);

  final String? participationType;

  @override
  List<Object?> get props => [participationType];
}

final class VendorCertificationTypesChanged extends VendorParticipationEvent {
  const VendorCertificationTypesChanged(this.certificationTypes);

  final Set<String> certificationTypes;

  @override
  List<Object?> get props => [certificationTypes];
}

/// Sent by the overview cards, each of which applies its slice of the
/// funnel or clears it when already selected.
final class VendorInvitationFilterToggled extends VendorParticipationEvent {
  const VendorInvitationFilterToggled(this.invitationStatus);

  final String invitationStatus;

  @override
  List<Object?> get props => [invitationStatus];
}

final class VendorParticipationFilterToggled extends VendorParticipationEvent {
  const VendorParticipationFilterToggled(this.participationStatus);

  final String participationStatus;

  @override
  List<Object?> get props => [participationStatus];
}

final class VendorPurchaseFilterToggled extends VendorParticipationEvent {
  const VendorPurchaseFilterToggled(this.purchaseOption);

  final String purchaseOption;

  @override
  List<Object?> get props => [purchaseOption];
}

final class VendorSubmissionFilterToggled extends VendorParticipationEvent {
  const VendorSubmissionFilterToggled(this.submissionStatuses);

  final Set<String> submissionStatuses;

  @override
  List<Object?> get props => [submissionStatuses];
}

final class VendorInvitationStatusChanged extends VendorParticipationEvent {
  const VendorInvitationStatusChanged(this.invitationStatus);

  final String? invitationStatus;

  @override
  List<Object?> get props => [invitationStatus];
}

final class VendorPurchaseOptionChanged extends VendorParticipationEvent {
  const VendorPurchaseOptionChanged(this.purchaseOption);

  final String? purchaseOption;

  @override
  List<Object?> get props => [purchaseOption];
}

final class VendorParticipationStatusChanged extends VendorParticipationEvent {
  const VendorParticipationStatusChanged(this.participationStatus);

  final String? participationStatus;

  @override
  List<Object?> get props => [participationStatus];
}

final class VendorSubmissionStatusesChanged extends VendorParticipationEvent {
  const VendorSubmissionStatusesChanged(this.submissionStatuses);

  final Set<String> submissionStatuses;

  @override
  List<Object?> get props => [submissionStatuses];
}

final class VendorSubmissionDateChanged extends VendorParticipationEvent {
  const VendorSubmissionDateChanged(this.range);

  final DateTimeRange? range;

  @override
  List<Object?> get props => [range];
}

final class VendorFiltersCleared extends VendorParticipationEvent {
  const VendorFiltersCleared();
}
