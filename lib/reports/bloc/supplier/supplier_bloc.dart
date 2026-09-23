// lib/reports/bloc/supplier/supplier_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:etender_reports/data/repositories/report_repository.dart';

import 'package:etender_reports/reports/models/report_filters.dart';
import 'package:etender_reports/reports/bloc/report_status.dart';
import 'package:etender_reports/reports/bloc/supplier/supplier_event.dart';
import 'package:etender_reports/reports/bloc/supplier/supplier_state.dart';

// Re-exported so a widget only ever imports this one file.
export 'package:etender_reports/reports/bloc/report_status.dart';
export 'package:etender_reports/reports/bloc/supplier/supplier_event.dart';
export 'package:etender_reports/reports/bloc/supplier/supplier_state.dart';

class SupplierBloc extends Bloc<SupplierEvent, SupplierState> {
  SupplierBloc({required this._repository}) : super(const SupplierState()) {
    on<SupplierDataRequested>(_onDataRequested);

    on<SupplierSearchChanged>(
      (event, emit) => _emit(emit, (f) => f.copyWith(searchQuery: event.query)),
    );
    on<SupplierStatusesChanged>(
      (event, emit) => _emit(emit, (f) => f.copyWith(statuses: event.statuses)),
    );
    on<SupplierStatusGroupToggled>(
      (event, emit) => _emit(emit, (f) => f.toggleStatuses(event.statuses)),
    );
    on<SupplierCategoriesChanged>(
      (event, emit) =>
          _emit(emit, (f) => f.copyWith(categories: event.categories)),
    );
    on<SupplierDivisionsChanged>(
      (event, emit) =>
          _emit(emit, (f) => f.copyWith(divisions: event.divisions)),
    );
    on<SupplierOpenToChanged>(
      (event, emit) => _emit(emit, (f) => f.copyWith(openTo: event.openTo)),
    );
    on<SupplierRequestDateChanged>(
      (event, emit) =>
          _emit(emit, (f) => f.copyWith(requestDateRange: event.range)),
    );
    on<SupplierClosingDateChanged>(
      (event, emit) =>
          _emit(emit, (f) => f.copyWith(closingDateRange: event.range)),
    );
    on<SupplierPendingPaymentOnlyChanged>(
      (event, emit) =>
          _emit(emit, (f) => f.copyWith(pendingPaymentOnly: event.value)),
    );
    on<SupplierPendingPaymentOnlyToggled>(
      (event, emit) => _emit(emit, (f) => f.togglePendingPaymentOnly()),
    );
    on<SupplierFiltersCleared>(
      (event, emit) => _emit(emit, (_) => const SupplierFilters()),
    );
  }

  final ReportRepository _repository;

  void _emit(
    Emitter<SupplierState> emit,
    SupplierFilters Function(SupplierFilters current) update,
  ) {
    emit(state.copyWith(filters: update(state.filters)));
  }

  Future<void> _onDataRequested(
    SupplierDataRequested event,
    Emitter<SupplierState> emit,
  ) async {
    emit(state.copyWith(status: ReportStatus.loading));
    try {
      // The repository is typed; the report pipeline below still
      // works on maps, so unwrap here. Removing this line is the
      // last step of moving a report onto the record classes.
      final records = [
        for (final record in await _repository.fetchSupplierRecords())
          record.toJson(),
      ];
      emit(state.copyWith(status: ReportStatus.ready, records: records));
    } catch (error) {
      emit(
        state.copyWith(
          status: ReportStatus.failure,
          errorMessage: 'Could not load supplier records.',
        ),
      );
    }
  }
}
