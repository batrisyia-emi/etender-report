// test/bloc/vtm_monitoring_bloc_test.dart
//
// The one place a report bloc reads a second dataset.
//
// The Outstanding Tender Security card on the VTM Monitoring report is fed
// from the tender security endpoint, not this report's own. That makes two
// things worth pinning down: the securities do arrive, and this report
// still works when they do not.
import 'package:etender_reports/data/repositories/mock_report_repository.dart';
import 'package:etender_reports/reports/bloc/vtm_monitoring/vtm_monitoring_bloc.dart';
import 'package:etender_reports/reports/models/records/tender_security_record.dart';
import 'package:etender_reports/reports/models/records/vtm_monitoring_record.dart';
import 'package:flutter_test/flutter_test.dart';

/// Everything works except the tender security endpoint, which is the state
/// the app is in while the two are being wired up in different weeks.
class NoSecuritiesRepository extends MockReportRepository {
  const NoSecuritiesRepository();

  @override
  Future<List<TenderSecurityRecord>> fetchTenderSecurityRecords() async =>
      throw StateError('tender security endpoint not deployed');
}

Future<void> loadInto(VtmMonitoringBloc bloc) async {
  bloc.add(const VtmMonitoringDataRequested());
  await pumpEventQueue();
}

void main() {
  group('VtmMonitoringBloc securities', () {
    test('loads the tender securities alongside its own records', () async {
      final bloc = VtmMonitoringBloc(repository: const MockReportRepository());
      addTearDown(bloc.close);

      await loadInto(bloc);

      expect(bloc.state.status, ReportStatus.ready);
      expect(bloc.state.records, isNotEmpty);
      expect(bloc.state.securities, isNotEmpty);
    });

    test(
      'a missing tender security endpoint does not fail the report',
      () async {
        final bloc = VtmMonitoringBloc(
          repository: const NoSecuritiesRepository(),
        );
        addTearDown(bloc.close);

        await loadInto(bloc);

        // The report is about Appendix F documents. One summary card losing
        // its figure is not a reason to show an error page instead.
        expect(bloc.state.status, ReportStatus.ready);
        expect(bloc.state.records, isNotEmpty);
        expect(bloc.state.securities, isEmpty);
        expect(bloc.state.errorMessage, isNull);
      },
    );

    test(
      'the report still fails when its own records cannot be read',
      () async {
        // Guards the opposite mistake: swallowing this report's own failure
        // along with the optional one.
        final bloc = VtmMonitoringBloc(
          repository: const _NoRecordsRepository(),
        );
        addTearDown(bloc.close);

        await loadInto(bloc);

        expect(bloc.state.status, ReportStatus.failure);
        expect(bloc.state.errorMessage, isNotEmpty);
      },
    );

    test('filters do not narrow the securities', () async {
      final bloc = VtmMonitoringBloc(repository: const MockReportRepository());
      addTearDown(bloc.close);

      await loadInto(bloc);
      final held = bloc.state.securities.length;

      bloc.add(const VtmErfcNoQueryChanged('zzzz-no-such-record-zzzz'));
      await pumpEventQueue();

      // The card reads a different dataset, so it stays whole while the
      // table empties. The card's footer says "across all tenders" for
      // exactly this reason.
      expect(bloc.state.filteredRecords, isEmpty);
      expect(bloc.state.securities, hasLength(held));
    });
  });
}

class _NoRecordsRepository extends MockReportRepository {
  const _NoRecordsRepository();

  @override
  Future<List<VtmMonitoringRecord>> fetchVtmMonitoringRecords() async =>
      throw StateError('vtm monitoring endpoint not deployed');
}
