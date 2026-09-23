// lib/reports/bloc/supplier/supplier_event.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show DateTimeRange;

sealed class SupplierEvent extends Equatable {
  const SupplierEvent();

  @override
  List<Object?> get props => [];
}

final class SupplierDataRequested extends SupplierEvent {
  const SupplierDataRequested();
}

final class SupplierSearchChanged extends SupplierEvent {
  const SupplierSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class SupplierStatusesChanged extends SupplierEvent {
  const SupplierStatusesChanged(this.statuses);

  final Set<String> statuses;

  @override
  List<Object?> get props => [statuses];
}

/// Sent by the overview cards, each of which applies its slice of the
/// funnel or clears it when already selected.
final class SupplierStatusGroupToggled extends SupplierEvent {
  const SupplierStatusGroupToggled(this.statuses);

  final Set<String> statuses;

  @override
  List<Object?> get props => [statuses];
}

final class SupplierCategoriesChanged extends SupplierEvent {
  const SupplierCategoriesChanged(this.categories);

  final Set<String> categories;

  @override
  List<Object?> get props => [categories];
}

final class SupplierDivisionsChanged extends SupplierEvent {
  const SupplierDivisionsChanged(this.divisions);

  final Set<String> divisions;

  @override
  List<Object?> get props => [divisions];
}

final class SupplierOpenToChanged extends SupplierEvent {
  const SupplierOpenToChanged(this.openTo);

  final String? openTo;

  @override
  List<Object?> get props => [openTo];
}

final class SupplierRequestDateChanged extends SupplierEvent {
  const SupplierRequestDateChanged(this.range);

  final DateTimeRange? range;

  @override
  List<Object?> get props => [range];
}

final class SupplierClosingDateChanged extends SupplierEvent {
  const SupplierClosingDateChanged(this.range);

  final DateTimeRange? range;

  @override
  List<Object?> get props => [range];
}

final class SupplierPendingPaymentOnlyChanged extends SupplierEvent {
  const SupplierPendingPaymentOnlyChanged(this.value);

  final bool value;

  @override
  List<Object?> get props => [value];
}

/// The card's tap: flips the shortcut rather than setting it outright.
final class SupplierPendingPaymentOnlyToggled extends SupplierEvent {
  const SupplierPendingPaymentOnlyToggled();
}

final class SupplierFiltersCleared extends SupplierEvent {
  const SupplierFiltersCleared();
}
