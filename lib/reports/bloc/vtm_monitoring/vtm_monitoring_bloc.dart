// lib/reports/bloc/vtm_monitoring/vtm_monitoring_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:etender_reports/data/repositories/report_repository.dart';
import 'package:etender_reports/reports/bloc/report_status.dart';
import 'package:etender_reports/reports/bloc/vtm_monitoring/vtm_monitoring_event.dart';
import 'package:etender_reports/reports/bloc/vtm_monitoring/vtm_monitoring_state.dart';
import 'package:etender_reports/reports/models/filters/vtm_monitoring_filters.dart';

// Re-exported so a widget only ever imports this one file.
export 'package:etender_reports/reports/bloc/report_status.dart';
export 'package:etender_reports/reports/bloc/vtm_monitoring/vtm_monitoring_event.dart';
export 'package:etender_reports/reports/bloc/vtm_monitoring/vtm_monitoring_state.dart';

class VtmMonitoringBloc extends Bloc<VtmMonitoringEvent, VtmMonitoringState> {
  VtmMonitoringBloc({required this._repository})
    : super(const VtmMonitoringState()) {
    on<VtmMonitoringDataRequested>(_onDataRequested);

    on<VtmTenderNoQueryChanged>(
      (event, emit) =>
          _emit(emit, (f) => f.copyWith(tenderNoQuery: event.query)),
    );
    on<VtmErfcNoQueryChanged>(
      (event, emit) => _emit(emit, (f) => f.copyWith(erfcNoQuery: event.query)),
    );
    on<VtmDocumentTypeChanged>(
      (event, emit) =>
          _emit(emit, (f) => f.copyWith(documentType: event.documentType)),
    );
    on<VtmStatusesChanged>(
      (event, emit) => _emit(emit, (f) => f.copyWith(statuses: event.statuses)),
    );
    on<VtmStatusGroupToggled>(
      (event, emit) => _emit(emit, (f) => f.toggleStatuses(event.statuses)),
    );
    on<VtmModeChanged>(
      (event, emit) =>
          _emit(emit, (f) => f.copyWith(modeOfProcurement: event.mode)),
    );
    on<VtmDivisionChanged>(
      (event, emit) => _emit(emit, (f) => f.copyWith(division: event.division)),
    );
    on<VtmEndorsedDateChanged>(
      (event, emit) =>
          _emit(emit, (f) => f.copyWith(endorsedDateRange: event.range)),
    );
    on<VtmFiltersCleared>(
      (event, emit) =>
          emit(state.copyWith(filters: const VtmMonitoringFilters())),
    );
  }

  final ReportRepository _repository;

  void _emit(
    Emitter<VtmMonitoringState> emit,
    VtmMonitoringFilters Function(VtmMonitoringFilters current) update,
  ) {
    emit(state.copyWith(filters: update(state.filters)));
  }

  Future<void> _onDataRequested(
    VtmMonitoringDataRequested event,
    Emitter<VtmMonitoringState> emit,
  ) async {
    emit(state.copyWith(status: ReportStatus.loading));
    try {
      final records = await _repository.fetchVtmMonitoringRecords();

      // Read second and separately on purpose. The securities feed one
      // summary card from another report's dataset, so this report has no
      // business failing when that endpoint is missing — which it will be
      // if the two are wired up in different weeks.
      var securities = state.securities;
      try {
        securities = await _repository.fetchTenderSecurityRecords();
      } catch (_) {
        securities = const [];
      }

      emit(
        state.copyWith(
          status: ReportStatus.ready,
          records: records,
          securities: securities,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ReportStatus.failure,
          errorMessage: 'Could not load VTM monitoring records.',
        ),
      );
    }
  }
}
