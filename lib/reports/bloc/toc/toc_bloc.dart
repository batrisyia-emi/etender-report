// lib/reports/bloc/toc/toc_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:etender_reports/data/repositories/report_repository.dart';
import 'package:etender_reports/reports/bloc/report_status.dart';
import 'package:etender_reports/reports/bloc/toc/toc_event.dart';
import 'package:etender_reports/reports/bloc/toc/toc_state.dart';
import 'package:etender_reports/reports/models/toc_filters.dart';

// Re-exported so a widget only ever imports this one file.
export 'package:etender_reports/reports/bloc/report_status.dart';
export 'package:etender_reports/reports/bloc/toc/toc_event.dart';
export 'package:etender_reports/reports/bloc/toc/toc_state.dart';

class TocBloc extends Bloc<TocEvent, TocState> {
  TocBloc({required this._repository}) : super(const TocState()) {
    on<TocDataRequested>(_onDataRequested);

    on<TocTenderNoQueryChanged>(
      (event, emit) =>
          _emit(emit, (f) => f.copyWith(tenderNoQuery: event.query)),
    );
    on<TocMemberQueryChanged>(
      (event, emit) => _emit(emit, (f) => f.copyWith(memberQuery: event.query)),
    );
    on<TocDocumentTypeChanged>(
      (event, emit) =>
          _emit(emit, (f) => f.copyWith(documentType: event.documentType)),
    );
    on<TocEnvelopeTypeChanged>(
      (event, emit) =>
          _emit(emit, (f) => f.copyWith(envelopeType: event.envelopeType)),
    );
    on<TocStatusesChanged>(
      (event, emit) => _emit(emit, (f) => f.copyWith(statuses: event.statuses)),
    );
    on<TocStatusGroupToggled>(
      (event, emit) => _emit(emit, (f) => f.toggleStatuses(event.statuses)),
    );
    on<TocClosingDateChanged>(
      (event, emit) =>
          _emit(emit, (f) => f.copyWith(closingDateRange: event.range)),
    );
    on<TocFiltersCleared>(
      (event, emit) => emit(state.copyWith(filters: const TocFilters())),
    );
  }

  final ReportRepository _repository;

  void _emit(
    Emitter<TocState> emit,
    TocFilters Function(TocFilters current) update,
  ) {
    emit(state.copyWith(filters: update(state.filters)));
  }

  Future<void> _onDataRequested(
    TocDataRequested event,
    Emitter<TocState> emit,
  ) async {
    emit(state.copyWith(status: ReportStatus.loading));
    try {
      // No unwrapping here, unlike the other four blocs: this report runs
      // on the record classes end to end.
      final records = await _repository.fetchTocRecords();
      emit(state.copyWith(status: ReportStatus.ready, records: records));
    } catch (error) {
      emit(
        state.copyWith(
          status: ReportStatus.failure,
          errorMessage: 'Could not load TOC records.',
        ),
      );
    }
  }
}
