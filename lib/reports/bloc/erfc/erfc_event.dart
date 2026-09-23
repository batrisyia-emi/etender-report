// lib/reports/bloc/erfc/erfc_event.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show DateTimeRange;

sealed class ErfcEvent extends Equatable {
  const ErfcEvent();

  @override
  List<Object?> get props => [];
}

final class ErfcDataRequested extends ErfcEvent {
  const ErfcDataRequested();
}

final class ErfcSearchChanged extends ErfcEvent {
  const ErfcSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class ErfcDivisionsChanged extends ErfcEvent {
  const ErfcDivisionsChanged(this.divisions);

  final Set<String> divisions;

  @override
  List<Object?> get props => [divisions];
}

/// Report spec 6.2: RFC Status Report by Division, Department, Unit.
final class ErfcUnitsChanged extends ErfcEvent {
  const ErfcUnitsChanged(this.units);

  final Set<String> units;

  @override
  List<Object?> get props => [units];
}

final class ErfcProcurementModesChanged extends ErfcEvent {
  const ErfcProcurementModesChanged(this.modes);

  final Set<String> modes;

  @override
  List<Object?> get props => [modes];
}

/// Sent by the overview cards: applies the group, or clears it when that
/// group is already the selection.
final class ErfcStatusGroupToggled extends ErfcEvent {
  const ErfcStatusGroupToggled(this.statuses);

  final Set<String> statuses;

  @override
  List<Object?> get props => [statuses];
}

/// Sent by the OVERDUE card, which turns the filter on and off again.
final class ErfcOverdueOnlyToggled extends ErfcEvent {
  const ErfcOverdueOnlyToggled();
}

final class ErfcStatusesChanged extends ErfcEvent {
  const ErfcStatusesChanged(this.statuses);

  final Set<String> statuses;

  @override
  List<Object?> get props => [statuses];
}

final class ErfcSubmissionDateChanged extends ErfcEvent {
  const ErfcSubmissionDateChanged(this.range);

  final DateTimeRange? range;

  @override
  List<Object?> get props => [range];
}

final class ErfcOverdueOnlyChanged extends ErfcEvent {
  const ErfcOverdueOnlyChanged(this.overdueOnly);

  final bool overdueOnly;

  @override
  List<Object?> get props => [overdueOnly];
}

final class ErfcFiltersCleared extends ErfcEvent {
  const ErfcFiltersCleared();
}
