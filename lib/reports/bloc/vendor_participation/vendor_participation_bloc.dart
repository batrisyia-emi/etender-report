// lib/reports/bloc/vendor_participation_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:etender_reports/data/repositories/report_repository.dart';
import 'package:etender_reports/reports/bloc/report_status.dart';
import 'package:etender_reports/reports/bloc/vendor_participation/vendor_participation_event.dart';
import 'package:etender_reports/reports/bloc/vendor_participation/vendor_participation_state.dart';
import 'package:etender_reports/reports/models/filters/report_filters.dart';

// Re-exported so a widget only ever imports this one file.
export 'package:etender_reports/reports/bloc/report_status.dart';
export 'package:etender_reports/reports/bloc/vendor_participation/vendor_participation_event.dart';
export 'package:etender_reports/reports/bloc/vendor_participation/vendor_participation_state.dart';

class VendorParticipationBloc
    extends Bloc<VendorParticipationEvent, VendorParticipationState> {
  VendorParticipationBloc({required this._repository})
    : super(const VendorParticipationState()) {
    on<VendorDataRequested>(_onDataRequested);

    on<VendorSearchChanged>(
      (event, emit) => _emit(emit, (f) => f.copyWith(searchQuery: event.query)),
    );
    on<VendorOpenToChanged>(
      (event, emit) => _emit(emit, (f) => f.copyWith(openTo: event.openTo)),
    );
    on<VendorCertificationTypesChanged>(
      (event, emit) => _emit(
        emit,
        (f) => f.copyWith(certificationTypes: event.certificationTypes),
      ),
    );
    on<VendorPurchaseOptionChanged>(
      (event, emit) =>
          _emit(emit, (f) => f.copyWith(purchaseOption: event.purchaseOption)),
    );
    on<VendorSubmissionStatusChanged>(
      (event, emit) =>
          _emit(emit, (f) => f.copyWith(submissionStatus: event.status)),
    );
    on<VendorRequestedDateChanged>(
      (event, emit) =>
          _emit(emit, (f) => f.copyWith(requestedDateRange: event.range)),
    );
    on<VendorFiltersCleared>(
      (event, emit) => _emit(emit, (_) => const VendorFilters()),
    );
  }

  final ReportRepository _repository;

  void _emit(
    Emitter<VendorParticipationState> emit,
    VendorFilters Function(VendorFilters current) update,
  ) {
    emit(state.copyWith(filters: update(state.filters)));
  }

  Future<void> _onDataRequested(
    VendorDataRequested event,
    Emitter<VendorParticipationState> emit,
  ) async {
    emit(state.copyWith(status: ReportStatus.loading));
    try {
      // The repository is typed; the report pipeline below still
      // works on maps, so unwrap here. Removing this line is the
      // last step of moving a report onto the record classes.
      final records = [
        for (final record
            in await _repository.fetchVendorParticipationRecords())
          record.toJson(),
      ];
      emit(state.copyWith(status: ReportStatus.ready, records: records));
    } catch (error) {
      emit(
        state.copyWith(
          status: ReportStatus.failure,
          errorMessage: 'Could not load vendor participation records.',
        ),
      );
    }
  }
}
