// lib/reports/bloc/tender_summary/tender_summary_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:etender_reports/data/repositories/report_repository.dart';

import 'package:etender_reports/reports/models/report_filters.dart';
import 'package:etender_reports/reports/bloc/report_status.dart';
import 'package:etender_reports/reports/bloc/tender_summary/tender_summary_event.dart';
import 'package:etender_reports/reports/bloc/tender_summary/tender_summary_state.dart';

// Re-exported so a widget only ever imports this one file.
export 'package:etender_reports/reports/bloc/report_status.dart';
export 'package:etender_reports/reports/bloc/tender_summary/tender_summary_event.dart';
export 'package:etender_reports/reports/bloc/tender_summary/tender_summary_state.dart';

class TenderSummaryBloc extends Bloc<TenderSummaryEvent, TenderSummaryState> {
  TenderSummaryBloc({required this._repository})
    : super(const TenderSummaryState()) {
    on<TenderDataRequested>(_onDataRequested);

    on<TenderSearchChanged>(
      (event, emit) => _emit(emit, (f) => f.copyWith(searchQuery: event.query)),
    );
    on<TenderStatusesChanged>(
      (event, emit) => _emit(emit, (f) => f.copyWith(statuses: event.statuses)),
    );
    on<TenderStatusGroupToggled>(
      (event, emit) => _emit(emit, (f) => f.toggleStatuses(event.statuses)),
    );
    on<TenderCategoriesChanged>(
      (event, emit) =>
          _emit(emit, (f) => f.copyWith(categories: event.categories)),
    );
    on<TenderProcurementModesChanged>(
      (event, emit) =>
          _emit(emit, (f) => f.copyWith(procurementModes: event.modes)),
    );
    on<TenderEnvelopeTypeChanged>(
      (event, emit) =>
          _emit(emit, (f) => f.copyWith(envelopeType: event.envelopeType)),
    );
    on<TenderItemTypeChanged>(
      (event, emit) => _emit(emit, (f) => f.copyWith(itemType: event.itemType)),
    );
    on<TenderDivisionsChanged>(
      (event, emit) =>
          _emit(emit, (f) => f.copyWith(divisions: event.divisions)),
    );
    on<TenderDepartmentsChanged>(
      (event, emit) =>
          _emit(emit, (f) => f.copyWith(departments: event.departments)),
    );
    on<TenderUnitsChanged>(
      (event, emit) => _emit(emit, (f) => f.copyWith(units: event.units)),
    );
    on<TenderMinimumValueChanged>(
      (event, emit) =>
          _emit(emit, (f) => f.copyWith(minimumValue: event.value)),
    );
    on<TenderMaximumValueChanged>(
      (event, emit) =>
          _emit(emit, (f) => f.copyWith(maximumValue: event.value)),
    );
    on<TenderDateRangeChanged>(
      (event, emit) =>
          _emit(emit, (f) => f.withRange(event.field, event.range)),
    );
    on<TenderFiltersCleared>(
      (event, emit) => _emit(emit, (_) => const TenderFilters()),
    );
  }

  final ReportRepository _repository;

  void _emit(
    Emitter<TenderSummaryState> emit,
    TenderFilters Function(TenderFilters current) update,
  ) {
    emit(state.copyWith(filters: update(state.filters)));
  }

  Future<void> _onDataRequested(
    TenderDataRequested event,
    Emitter<TenderSummaryState> emit,
  ) async {
    emit(state.copyWith(status: ReportStatus.loading));
    try {
      // The repository is typed; the report pipeline below still
      // works on maps, so unwrap here. Removing this line is the
      // last step of moving a report onto the record classes.
      final records = [
        for (final record in await _repository.fetchTenderRecords())
          record.toJson(),
      ];
      emit(state.copyWith(status: ReportStatus.ready, records: records));
    } catch (error) {
      emit(
        state.copyWith(
          status: ReportStatus.failure,
          errorMessage: 'Could not load tender records.',
        ),
      );
    }
  }
}
