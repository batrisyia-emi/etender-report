// lib/reports/procurement_lead_time/bloc/lead_time_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:etender_reports/reports/bloc/report_status.dart';
import 'package:etender_reports/reports/procurement_lead_time/data/lead_time_repository.dart';
import 'package:etender_reports/reports/procurement_lead_time/lead_time_rules.dart';
import 'package:etender_reports/reports/procurement_lead_time/models/lead_time_query.dart';
import 'package:etender_reports/reports/procurement_lead_time/models/lead_time_summary.dart';
import 'package:etender_reports/reports/procurement_lead_time/services/lead_time_service.dart';
import 'package:etender_reports/reports/procurement_lead_time/services/working_day_calculator.dart';

export 'package:etender_reports/reports/bloc/report_status.dart';

/// Which bucket of which summary the drill-down is showing.
typedef LeadTimeSelection = ({DocumentType type, LeadTimeBucket bucket});

class LeadTimeState extends Equatable {
  const LeadTimeState({
    this.status = ReportStatus.initial,
    this.query,
    this.summaries = const [],
    this.selection,
    this.errorMessage,
  });

  /// [ReportStatus.initial] until the first search.
  final ReportStatus status;

  /// The last search run, which is also what the filter bar reopens on.
  final LeadTimeQuery? query;

  /// One per document type in the query, in [DocumentTypeFilter.types]
  /// order. Two when the query is 'All'.
  final List<LeadTimeSummary> summaries;

  final LeadTimeSelection? selection;
  final String? errorMessage;

  int get total => summaries.fold(0, (sum, summary) => sum + summary.total);

  LeadTimeSummary? get selectedSummary {
    final type = selection?.type;
    for (final summary in summaries) {
      if (summary.documentType == type) return summary;
    }
    return null;
  }

  @override
  List<Object?> get props => [
    status,
    query,
    summaries,
    selection,
    errorMessage,
  ];
}

class LeadTimeCubit extends Cubit<LeadTimeState> {
  LeadTimeCubit({required this._repository}) : super(const LeadTimeState());

  final LeadTimeRepository _repository;

  /// Counts searches, so only the newest one may publish its result.
  int _searchId = 0;

  /// Runs [query]. The filter bar validates before calling this.
  ///
  /// A period chip searches the moment it is tapped, so a second search
  /// can start before the first returns. Whichever was started last wins;
  /// an older one finishing late is dropped rather than overwriting it.
  Future<void> search(LeadTimeQuery query) async {
    final id = ++_searchId;
    emit(LeadTimeState(status: ReportStatus.loading, query: query));
    try {
      final (holidays, records) = await (
        _repository.fetchHolidays(),
        _repository.fetchRecords(
          receivedFrom: query.receivedFrom,
          receivedTo: query.receivedTo,
          type: query.type,
          procurementMode: query.procurementMode,
        ),
      ).wait;
      if (id != _searchId || isClosed) return;

      final measured = LeadTimeService(WorkingDayCalculator(holidays: holidays))
          .measure(records);
      final summaries = [
        for (final type in query.type.types)
          LeadTimeService.summarise(type, measured),
      ];

      emit(
        LeadTimeState(
          status: ReportStatus.ready,
          query: query,
          summaries: summaries,
          // After a search the drill-down opens on the fastest band of the
          // first table.
          selection: (
            type: query.type.types.first,
            bucket: LeadTimeRules.buckets.first,
          ),
        ),
      );
    } catch (_) {
      if (id != _searchId || isClosed) return;
      emit(
        LeadTimeState(
          status: ReportStatus.failure,
          query: query,
          errorMessage: 'Could not load procurement lead times.',
        ),
      );
    }
  }

  /// Re-runs the last search after a failure.
  Future<void> retry() async {
    final query = state.query;
    if (query != null) await search(query);
  }

  void selectBucket(DocumentType type, LeadTimeBucket bucket) {
    if (state.status != ReportStatus.ready) return;
    emit(
      LeadTimeState(
        status: state.status,
        query: state.query,
        summaries: state.summaries,
        selection: (type: type, bucket: bucket),
      ),
    );
  }
}
