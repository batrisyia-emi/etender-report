// lib/reports/bloc/toc/toc_event.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

sealed class TocEvent extends Equatable {
  const TocEvent();

  @override
  List<Object?> get props => const [];
}

final class TocDataRequested extends TocEvent {
  const TocDataRequested();
}

final class TocTenderNoQueryChanged extends TocEvent {
  const TocTenderNoQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class TocMemberQueryChanged extends TocEvent {
  const TocMemberQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class TocDocumentTypeChanged extends TocEvent {
  const TocDocumentTypeChanged(this.documentType);

  /// Null clears the filter back to both types.
  final String? documentType;

  @override
  List<Object?> get props => [documentType];
}

final class TocEnvelopeTypeChanged extends TocEvent {
  const TocEnvelopeTypeChanged(this.envelopeType);

  /// Null clears the filter back to both arrangements.
  final String? envelopeType;

  @override
  List<Object?> get props => [envelopeType];
}

final class TocStatusesChanged extends TocEvent {
  const TocStatusesChanged(this.statuses);

  final Set<String> statuses;

  @override
  List<Object?> get props => [statuses];
}

/// Applies a status group, or clears it when it is already the selection —
/// what the summary cards do when tapped.
final class TocStatusGroupToggled extends TocEvent {
  const TocStatusGroupToggled(this.statuses);

  final Set<String> statuses;

  @override
  List<Object?> get props => [statuses];
}

final class TocClosingDateChanged extends TocEvent {
  const TocClosingDateChanged(this.range);

  final DateTimeRange? range;

  @override
  List<Object?> get props => [range];
}

final class TocFiltersCleared extends TocEvent {
  const TocFiltersCleared();
}
