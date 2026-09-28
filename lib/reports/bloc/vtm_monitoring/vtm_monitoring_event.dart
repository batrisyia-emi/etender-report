// lib/reports/bloc/vtm_monitoring/vtm_monitoring_event.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

sealed class VtmMonitoringEvent extends Equatable {
  const VtmMonitoringEvent();

  @override
  List<Object?> get props => const [];
}

final class VtmMonitoringDataRequested extends VtmMonitoringEvent {
  const VtmMonitoringDataRequested();
}

final class VtmTenderNoQueryChanged extends VtmMonitoringEvent {
  const VtmTenderNoQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class VtmErfcNoQueryChanged extends VtmMonitoringEvent {
  const VtmErfcNoQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class VtmDocumentTypeChanged extends VtmMonitoringEvent {
  const VtmDocumentTypeChanged(this.documentType);

  /// Null clears the filter back to both types.
  final String? documentType;

  @override
  List<Object?> get props => [documentType];
}

final class VtmStatusesChanged extends VtmMonitoringEvent {
  const VtmStatusesChanged(this.statuses);

  final Set<String> statuses;

  @override
  List<Object?> get props => [statuses];
}

/// Applies a status group, or clears it when it is already the selection —
/// what the summary cards do when tapped.
final class VtmStatusGroupToggled extends VtmMonitoringEvent {
  const VtmStatusGroupToggled(this.statuses);

  final Set<String> statuses;

  @override
  List<Object?> get props => [statuses];
}

final class VtmModeChanged extends VtmMonitoringEvent {
  const VtmModeChanged(this.mode);

  /// A section 7 code. Null clears the filter back to every mode.
  final String? mode;

  @override
  List<Object?> get props => [mode];
}

final class VtmDivisionChanged extends VtmMonitoringEvent {
  const VtmDivisionChanged(this.division);

  final String? division;

  @override
  List<Object?> get props => [division];
}

final class VtmEndorsedDateChanged extends VtmMonitoringEvent {
  const VtmEndorsedDateChanged(this.range);

  final DateTimeRange? range;

  @override
  List<Object?> get props => [range];
}

final class VtmFiltersCleared extends VtmMonitoringEvent {
  const VtmFiltersCleared();
}
