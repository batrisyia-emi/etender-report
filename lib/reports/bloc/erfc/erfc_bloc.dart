// lib/reports/bloc/erfc/erfc_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:etender_reports/data/repositories/report_repository.dart';

import 'package:etender_reports/reports/models/report_filters.dart';
import 'package:etender_reports/reports/bloc/report_status.dart';
import 'package:etender_reports/reports/bloc/erfc/erfc_event.dart';
import 'package:etender_reports/reports/bloc/erfc/erfc_state.dart';

// Re-exported so a widget only ever imports this one file.
export 'package:etender_reports/reports/bloc/report_status.dart';
export 'package:etender_reports/reports/bloc/erfc/erfc_event.dart';
export 'package:etender_reports/reports/bloc/erfc/erfc_state.dart';

class ErfcBloc extends Bloc<ErfcEvent, ErfcState> {
  ErfcBloc({required this._repository}) : super(const ErfcState()) {
    on<ErfcDataRequested>(_onDataRequested);

    on<ErfcSearchChanged>(
      (event, emit) => _emit(emit, (f) => f.copyWith(searchQuery: event.query)),
    );
    on<ErfcDivisionsChanged>(
      (event, emit) =>
          _emit(emit, (f) => f.copyWith(divisions: event.divisions)),
    );
    on<ErfcUnitsChanged>(
      (event, emit) => _emit(emit, (f) => f.copyWith(units: event.units)),
    );
    on<ErfcProcurementModesChanged>(
      (event, emit) =>
          _emit(emit, (f) => f.copyWith(procurementModes: event.modes)),
    );
    on<ErfcStatusGroupToggled>(
      (event, emit) => _emit(emit, (f) => f.toggleStatuses(event.statuses)),
    );
    on<ErfcOverdueOnlyToggled>(
      (event, emit) => _emit(emit, (f) => f.toggleOverdueOnly()),
    );
    on<ErfcStatusesChanged>(
      (event, emit) => _emit(emit, (f) => f.copyWith(statuses: event.statuses)),
    );
    on<ErfcSubmissionDateChanged>(
      (event, emit) =>
          _emit(emit, (f) => f.copyWith(submissionDateRange: event.range)),
    );
    on<ErfcOverdueOnlyChanged>(
      (event, emit) =>
          _emit(emit, (f) => f.copyWith(overdueOnly: event.overdueOnly)),
    );
    on<ErfcFiltersCleared>(
      (event, emit) => _emit(emit, (_) => const ErfcFilters()),
    );
  }

  final ReportRepository _repository;

  void _emit(
    Emitter<ErfcState> emit,
    ErfcFilters Function(ErfcFilters current) update,
  ) {
    emit(state.copyWith(filters: update(state.filters)));
  }

  Future<void> _onDataRequested(
    ErfcDataRequested event,
    Emitter<ErfcState> emit,
  ) async {
    emit(state.copyWith(status: ReportStatus.loading));
    try {
      // The repository is typed; the report pipeline below still
      // works on maps, so unwrap here. Removing this line is the
      // last step of moving a report onto the record classes.
      final records = [
        for (final record in await _repository.fetchErfcRecords())
          record.toJson(),
      ];
      emit(state.copyWith(status: ReportStatus.ready, records: records));
    } catch (error) {
      emit(
        state.copyWith(
          status: ReportStatus.failure,
          errorMessage: 'Could not load eRFC records.',
        ),
      );
    }
  }
}
