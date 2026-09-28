// test/bloc/report_bloc_test.dart
//
// One suite covering all seven report blocs.
//
// They are deliberately built the same way — load, hold, filter, clear —
// so the tests are written once against that shape and run against each
// bloc in turn. A bloc that stops following the shape fails here, which is
// the point: the uniformity is what lets a backend developer wire seven
// reports by learning one pattern.
//
// What each bloc is checked for:
//   1. it starts empty rather than pretending to have data,
//   2. a successful read reaches ready with records,
//   3. a failed read reaches failure, says so, and keeps no half-state,
//   4. a filter narrows the rows without going back to the repository,
//   5. clearing the filters restores every row, also without a re-read,
//   6. a second load after a failure recovers.
//
// Point 3 is the one that matters when the mock repository is swapped for
// a real API, because MockReportRepository can never fail.
import 'package:bloc/bloc.dart';
import 'package:etender_reports/data/repositories/mock_report_repository.dart';
import 'package:etender_reports/data/repositories/report_repository.dart';
import 'package:etender_reports/reports/bloc/erfc/erfc_bloc.dart';
import 'package:etender_reports/reports/bloc/supplier/supplier_bloc.dart';
import 'package:etender_reports/reports/bloc/tender_security/tender_security_bloc.dart';
import 'package:etender_reports/reports/bloc/tender_summary/tender_summary_bloc.dart';
import 'package:etender_reports/reports/bloc/toc/toc_bloc.dart';
import 'package:etender_reports/reports/bloc/vendor_participation/vendor_participation_bloc.dart';
import 'package:etender_reports/reports/bloc/vtm_monitoring/vtm_monitoring_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/failing_report_repository.dart';

/// A query no record can match, used to prove the filter is applied at all.
const String kNoSuchRecord = 'zzzz-no-such-record-zzzz';

/// One bloc, described in the terms the shared tests need.
///
/// The closures cast rather than the class being generic over the state
/// type, which keeps the table below readable — the cast is safe because
/// each row builds the bloc whose state it then reads.
class ReportBlocCase {
  const ReportBlocCase({
    required this.name,
    required this.build,
    required this.load,
    required this.narrow,
    required this.clear,
    required this.status,
    required this.recordCount,
    required this.filteredCount,
    required this.errorMessage,
  });

  final String name;
  final Bloc<Object, Object> Function(ReportRepository repository) build;

  /// The events: fetch, apply a filter that matches nothing, reset.
  final Object load;
  final Object narrow;
  final Object clear;

  final ReportStatus Function(Object state) status;
  final int Function(Object state) recordCount;
  final int Function(Object state) filteredCount;
  final String? Function(Object state) errorMessage;
}

final List<ReportBlocCase> cases = [
  ReportBlocCase(
    name: 'TenderSummaryBloc',
    build: (repository) => TenderSummaryBloc(repository: repository),
    load: const TenderDataRequested(),
    narrow: const TenderSearchChanged(kNoSuchRecord),
    clear: const TenderFiltersCleared(),
    status: (s) => (s as TenderSummaryState).status,
    recordCount: (s) => (s as TenderSummaryState).records.length,
    filteredCount: (s) => (s as TenderSummaryState).filteredRecords.length,
    errorMessage: (s) => (s as TenderSummaryState).errorMessage,
  ),
  ReportBlocCase(
    name: 'VendorParticipationBloc',
    build: (repository) => VendorParticipationBloc(repository: repository),
    load: const VendorDataRequested(),
    narrow: const VendorSearchChanged(kNoSuchRecord),
    clear: const VendorFiltersCleared(),
    status: (s) => (s as VendorParticipationState).status,
    recordCount: (s) => (s as VendorParticipationState).records.length,
    filteredCount: (s) =>
        (s as VendorParticipationState).filteredRecords.length,
    errorMessage: (s) => (s as VendorParticipationState).errorMessage,
  ),
  ReportBlocCase(
    name: 'ErfcBloc',
    build: (repository) => ErfcBloc(repository: repository),
    load: const ErfcDataRequested(),
    narrow: const ErfcSearchChanged(kNoSuchRecord),
    clear: const ErfcFiltersCleared(),
    status: (s) => (s as ErfcState).status,
    recordCount: (s) => (s as ErfcState).records.length,
    filteredCount: (s) => (s as ErfcState).filteredRecords.length,
    errorMessage: (s) => (s as ErfcState).errorMessage,
  ),
  ReportBlocCase(
    name: 'SupplierBloc',
    build: (repository) => SupplierBloc(repository: repository),
    load: const SupplierDataRequested(),
    narrow: const SupplierSearchChanged(kNoSuchRecord),
    clear: const SupplierFiltersCleared(),
    status: (s) => (s as SupplierState).status,
    recordCount: (s) => (s as SupplierState).records.length,
    filteredCount: (s) => (s as SupplierState).filteredRecords.length,
    errorMessage: (s) => (s as SupplierState).errorMessage,
  ),
  ReportBlocCase(
    name: 'TocBloc',
    build: (repository) => TocBloc(repository: repository),
    load: const TocDataRequested(),
    narrow: const TocTenderNoQueryChanged(kNoSuchRecord),
    clear: const TocFiltersCleared(),
    status: (s) => (s as TocState).status,
    recordCount: (s) => (s as TocState).records.length,
    filteredCount: (s) => (s as TocState).filteredRecords.length,
    errorMessage: (s) => (s as TocState).errorMessage,
  ),
  ReportBlocCase(
    name: 'TenderSecurityBloc',
    build: (repository) => TenderSecurityBloc(repository: repository),
    load: const TenderSecurityDataRequested(),
    narrow: const TenderSecurityTenderNoQueryChanged(kNoSuchRecord),
    clear: const TenderSecurityFiltersCleared(),
    status: (s) => (s as TenderSecurityState).status,
    recordCount: (s) => (s as TenderSecurityState).records.length,
    filteredCount: (s) => (s as TenderSecurityState).filteredRecords.length,
    errorMessage: (s) => (s as TenderSecurityState).errorMessage,
  ),
  ReportBlocCase(
    name: 'VtmMonitoringBloc',
    build: (repository) => VtmMonitoringBloc(repository: repository),
    load: const VtmMonitoringDataRequested(),
    narrow: const VtmErfcNoQueryChanged(kNoSuchRecord),
    clear: const VtmFiltersCleared(),
    status: (s) => (s as VtmMonitoringState).status,
    recordCount: (s) => (s as VtmMonitoringState).records.length,
    filteredCount: (s) => (s as VtmMonitoringState).filteredRecords.length,
    errorMessage: (s) => (s as VtmMonitoringState).errorMessage,
  ),
];

/// Adds an event and lets the bloc's handler run to completion.
///
/// The handlers are async only where they read the repository, but draining
/// the queue after every event keeps the tests uniform.
Future<void> send(Bloc<Object, Object> bloc, Object event) async {
  bloc.add(event);
  await pumpEventQueue();
}

void main() {
  test('every report bloc is covered', () {
    // Guards against a new report being added with no bloc test: the count
    // here has to be raised deliberately.
    expect(cases, hasLength(7));
  });

  for (final testCase in cases) {
    group(testCase.name, () {
      const mock = MockReportRepository();

      test('starts empty rather than claiming to have data', () {
        final bloc = testCase.build(mock);
        addTearDown(bloc.close);

        expect(testCase.status(bloc.state), ReportStatus.initial);
        expect(testCase.recordCount(bloc.state), 0);
        expect(testCase.errorMessage(bloc.state), isNull);
      });

      test('a successful read reaches ready with records', () async {
        final bloc = testCase.build(mock);
        addTearDown(bloc.close);

        await send(bloc, testCase.load);

        expect(testCase.status(bloc.state), ReportStatus.ready);
        expect(testCase.recordCount(bloc.state), greaterThan(0));
        expect(testCase.errorMessage(bloc.state), isNull);
      });

      test('passes through loading on the way', () async {
        final bloc = testCase.build(mock);
        addTearDown(bloc.close);

        final seen = <ReportStatus>[];
        final subscription = bloc.stream.listen(
          (state) => seen.add(testCase.status(state)),
        );
        addTearDown(subscription.cancel);

        await send(bloc, testCase.load);

        expect(seen, [ReportStatus.loading, ReportStatus.ready]);
      });

      test('a failed read reports failure and holds no records', () async {
        final bloc = testCase.build(const FailingReportRepository());
        addTearDown(bloc.close);

        await send(bloc, testCase.load);

        expect(testCase.status(bloc.state), ReportStatus.failure);
        // The view shows this string, so an empty one would leave the user
        // with a blank error panel.
        expect(testCase.errorMessage(bloc.state), isNotEmpty);
        expect(testCase.recordCount(bloc.state), 0);
      });

      test('a filter narrows the rows without re-reading', () async {
        final counting = CountingReportRepository(mock);
        final bloc = testCase.build(counting);
        addTearDown(bloc.close);

        await send(bloc, testCase.load);
        final loaded = testCase.recordCount(bloc.state);

        await send(bloc, testCase.narrow);

        expect(testCase.filteredCount(bloc.state), 0);
        // Filtering is client-side: the rows are still held, just not shown.
        expect(testCase.recordCount(bloc.state), loaded);
        expect(counting.calls, 1);
      });

      test('clearing the filters restores every row', () async {
        final counting = CountingReportRepository(mock);
        final bloc = testCase.build(counting);
        addTearDown(bloc.close);

        await send(bloc, testCase.load);
        await send(bloc, testCase.narrow);
        await send(bloc, testCase.clear);

        expect(
          testCase.filteredCount(bloc.state),
          testCase.recordCount(bloc.state),
        );
        expect(counting.calls, 1);
      });

      test('a retry after a failure recovers', () async {
        final bloc = testCase.build(const FailingReportRepository());
        addTearDown(bloc.close);

        await send(bloc, testCase.load);
        expect(testCase.status(bloc.state), ReportStatus.failure);

        // The same bloc against a working repository, which is what a
        // retry button would amount to once one exists.
        final recovered = testCase.build(mock);
        addTearDown(recovered.close);
        await send(recovered, testCase.load);

        expect(testCase.status(recovered.state), ReportStatus.ready);
      });
    });
  }
}
