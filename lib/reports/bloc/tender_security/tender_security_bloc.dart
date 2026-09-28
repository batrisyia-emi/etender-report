// lib/reports/bloc/tender_security/tender_security_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:etender_reports/data/repositories/report_repository.dart';
import 'package:etender_reports/reports/bloc/report_status.dart';
import 'package:etender_reports/reports/bloc/tender_security/tender_security_event.dart';
import 'package:etender_reports/reports/bloc/tender_security/tender_security_state.dart';
import 'package:etender_reports/reports/models/tender_security_filters.dart';

// Re-exported so a widget only ever imports this one file.
export 'package:etender_reports/reports/bloc/report_status.dart';
export 'package:etender_reports/reports/bloc/tender_security/tender_security_event.dart';
export 'package:etender_reports/reports/bloc/tender_security/tender_security_state.dart';

class TenderSecurityBloc
    extends Bloc<TenderSecurityEvent, TenderSecurityState> {
  TenderSecurityBloc({required this._repository})
    : super(const TenderSecurityState()) {
    on<TenderSecurityDataRequested>(_onDataRequested);

    on<TenderSecurityTenderNoQueryChanged>(
      (event, emit) =>
          _emit(emit, (f) => f.copyWith(tenderNoQuery: event.query)),
    );
    on<TenderSecurityVendorQueryChanged>(
      (event, emit) => _emit(emit, (f) => f.copyWith(vendorQuery: event.query)),
    );
    on<TenderSecurityPaymentTypeChanged>(
      (event, emit) =>
          _emit(emit, (f) => f.copyWith(paymentType: event.paymentType)),
    );
    on<TenderSecurityViewChanged>(
      (event, emit) => _emit(emit, (f) => f.copyWith(view: event.view)),
    );
    on<TenderSecurityViewToggled>(
      (event, emit) => _emit(emit, (f) => f.toggleView(event.view)),
    );
    on<TenderSecurityFiltersCleared>(
      (event, emit) =>
          emit(state.copyWith(filters: const TenderSecurityFilters())),
    );

    on<TenderSecurityFieldEdited>(_onFieldEdited);
  }

  final ReportRepository _repository;

  void _emit(
    Emitter<TenderSecurityState> emit,
    TenderSecurityFilters Function(TenderSecurityFilters current) update,
  ) {
    emit(state.copyWith(filters: update(state.filters)));
  }

  Future<void> _onDataRequested(
    TenderSecurityDataRequested event,
    Emitter<TenderSecurityState> emit,
  ) async {
    emit(state.copyWith(status: ReportStatus.loading));
    try {
      final records = await _repository.fetchTenderSecurityRecords();
      emit(state.copyWith(status: ReportStatus.ready, records: records));
    } catch (error) {
      emit(
        state.copyWith(
          status: ReportStatus.failure,
          errorMessage: 'Could not load tender security records.',
        ),
      );
    }
  }

  /// Applies an edit to this bloc's copy so the control the user touched
  /// responds immediately.
  ///
  /// Display only: nothing here writes to a server, and a reload restores
  /// whatever the repository returns. The view sends the same edit to
  /// `ReportActions.updateTenderSecurity`, which is what makes it stick.
  void _onFieldEdited(
    TenderSecurityFieldEdited event,
    Emitter<TenderSecurityState> emit,
  ) {
    emit(
      state.copyWith(
        records: [
          for (final record in state.records)
            if (record.uniqueNo == event.uniqueNo)
              record.copyWith(
                originalCopyReceived: event.originalCopyReceived,
                submittedToRevenueAssuranceDate:
                    event.submittedToRevenueAssuranceDate,
                clearSubmittedToRevenueAssuranceDate:
                    event.clearSubmittedToRevenueAssuranceDate,
                unsuccessfulTenderer: event.unsuccessfulTenderer,
                clearUnsuccessfulTenderer: event.clearUnsuccessfulTenderer,
                refundDate: event.refundDate,
                clearRefundDate: event.clearRefundDate,
              )
            else
              record,
        ],
      ),
    );
  }
}
