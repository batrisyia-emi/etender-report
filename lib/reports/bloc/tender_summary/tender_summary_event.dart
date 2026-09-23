// lib/reports/bloc/tender_summary/tender_summary_event.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show DateTimeRange;

import 'package:etender_reports/reports/models/report_filters.dart';

sealed class TenderSummaryEvent extends Equatable {
  const TenderSummaryEvent();

  @override
  List<Object?> get props => [];
}

final class TenderDataRequested extends TenderSummaryEvent {
  const TenderDataRequested();
}

final class TenderSearchChanged extends TenderSummaryEvent {
  const TenderSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class TenderStatusesChanged extends TenderSummaryEvent {
  const TenderStatusesChanged(this.statuses);

  final Set<String> statuses;

  @override
  List<Object?> get props => [statuses];
}

/// Sent by the overview cards: applies the group, or clears it when that
/// group is already the selection.
final class TenderStatusGroupToggled extends TenderSummaryEvent {
  const TenderStatusGroupToggled(this.statuses);

  final Set<String> statuses;

  @override
  List<Object?> get props => [statuses];
}

/// Works / Goods / Services / Consultancy.
final class TenderCategoriesChanged extends TenderSummaryEvent {
  const TenderCategoriesChanged(this.categories);

  final Set<String> categories;

  @override
  List<Object?> get props => [categories];
}

final class TenderProcurementModesChanged extends TenderSummaryEvent {
  const TenderProcurementModesChanged(this.modes);

  final Set<String> modes;

  @override
  List<Object?> get props => [modes];
}

/// 1 Envelope / 2 Envelope. Null clears the filter.
final class TenderEnvelopeTypeChanged extends TenderSummaryEvent {
  const TenderEnvelopeTypeChanged(this.envelopeType);

  final String? envelopeType;

  @override
  List<Object?> get props => [envelopeType];
}

/// Stock Item / Non-Stock Item. Null clears the filter.
final class TenderItemTypeChanged extends TenderSummaryEvent {
  const TenderItemTypeChanged(this.itemType);

  final String? itemType;

  @override
  List<Object?> get props => [itemType];
}

final class TenderDivisionsChanged extends TenderSummaryEvent {
  const TenderDivisionsChanged(this.divisions);

  final Set<String> divisions;

  @override
  List<Object?> get props => [divisions];
}

final class TenderDepartmentsChanged extends TenderSummaryEvent {
  const TenderDepartmentsChanged(this.departments);

  final Set<String> departments;

  @override
  List<Object?> get props => [departments];
}

final class TenderUnitsChanged extends TenderSummaryEvent {
  const TenderUnitsChanged(this.units);

  final Set<String> units;

  @override
  List<Object?> get props => [units];
}

final class TenderMinimumValueChanged extends TenderSummaryEvent {
  const TenderMinimumValueChanged(this.value);

  final double? value;

  @override
  List<Object?> get props => [value];
}

final class TenderMaximumValueChanged extends TenderSummaryEvent {
  const TenderMaximumValueChanged(this.value);

  final double? value;

  @override
  List<Object?> get props => [value];
}

/// One event for all three date pickers, keyed by [field].
final class TenderDateRangeChanged extends TenderSummaryEvent {
  const TenderDateRangeChanged(this.field, this.range);

  final TenderDateField field;
  final DateTimeRange? range;

  @override
  List<Object?> get props => [field, range];
}

final class TenderFiltersCleared extends TenderSummaryEvent {
  const TenderFiltersCleared();
}
