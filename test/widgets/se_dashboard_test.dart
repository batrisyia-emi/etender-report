// test/widgets/se_dashboard_test.dart
//
// The SE dashboard reads six blocs and lays out seven tabs. Nothing else
// in the suite renders it, so a panel that throws — a null aging figure, an
// empty record list, a division nobody has — would reach a person first.
//
// These tests pump the real widget against the mock repository and walk
// every tab, which is the cheapest way to keep that from happening.
import 'package:etender_reports/data/repositories/mock_report_repository.dart';
import 'package:etender_reports/reports/bloc/erfc/erfc_bloc.dart';
import 'package:etender_reports/reports/bloc/tender_security/tender_security_bloc.dart';
import 'package:etender_reports/reports/bloc/tender_summary/tender_summary_bloc.dart';
import 'package:etender_reports/reports/bloc/toc/toc_bloc.dart';
import 'package:etender_reports/reports/bloc/vendor_participation/vendor_participation_bloc.dart';
import 'package:etender_reports/reports/bloc/vtm_monitoring/vtm_monitoring_bloc.dart';
import 'package:etender_reports/reports/views/dashboard_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// The dashboard with every bloc it reads, loaded from the mock data.
///
/// [loaded] false leaves the blocs in their initial empty state, which is
/// what the first frame after a cold start actually looks like.
Widget harness({bool loaded = true}) {
  const repository = MockReportRepository();

  // Typed on the bloc's own event, so this stays a static call rather than
  // a dynamic one.
  B started<B extends Bloc<E, Object?>, E>(B bloc, E event) {
    if (loaded) bloc.add(event);
    return bloc;
  }

  return MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) => started(
          TenderSummaryBloc(repository: repository),
          const TenderDataRequested(),
        ),
      ),
      BlocProvider(
        create: (_) => started(
          VendorParticipationBloc(repository: repository),
          const VendorDataRequested(),
        ),
      ),
      BlocProvider(
        create: (_) => started(
          ErfcBloc(repository: repository),
          const ErfcDataRequested(),
        ),
      ),
      BlocProvider(
        create: (_) =>
            started(TocBloc(repository: repository), const TocDataRequested()),
      ),
      BlocProvider(
        create: (_) => started(
          TenderSecurityBloc(repository: repository),
          const TenderSecurityDataRequested(),
        ),
      ),
      BlocProvider(
        create: (_) => started(
          VtmMonitoringBloc(repository: repository),
          const VtmMonitoringDataRequested(),
        ),
      ),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: DashboardView(sectionSpacing: 16, fillHeight: false),
        ),
      ),
    ),
  );
}

/// Taps a tab by its label and settles.
Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  // Wide enough for the 4-column card grid, so a short last row is not
  // mistaken for a layout fault.
  const wide = Size(1400, 2400);

  testWidgets('every tab renders against the mock data', (tester) async {
    tester.view.physicalSize = wide;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    for (final tab in [
      'Tenders',
      'eRFC',
      'Vendors',
      'TOC & Opening',
      'Tender Security',
      'VTM Monitoring',
      'Overview',
    ]) {
      await openTab(tester, tab);
      expect(
        tester.takeException(),
        isNull,
        reason: 'the $tab panel threw while building',
      );
    }
  });

  testWidgets('the three later reports show their own figures', (tester) async {
    tester.view.physicalSize = wide;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await openTab(tester, 'TOC & Opening');
    expect(find.text('Openings'), findsOneWidget);
    expect(find.text('Awaiting Committee'), findsOneWidget);
    expect(find.text('Committee Workload'), findsOneWidget);

    await openTab(tester, 'Tender Security');
    expect(find.text('Outstanding Tender Security'), findsOneWidget);
    expect(find.text('Expired, Still Held'), findsOneWidget);
    expect(find.text('Security Status'), findsOneWidget);

    await openTab(tester, 'VTM Monitoring');
    expect(find.text('Appendix F Documents'), findsOneWidget);
    expect(find.text('Sent Back'), findsOneWidget);
    expect(find.text('Appendix F Pipeline'), findsOneWidget);
  });

  testWidgets('the overview carries the two process reports', (tester) async {
    tester.view.physicalSize = wide;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    // Both are on the landing tab, so neither report is invisible until
    // somebody finds its tab.
    expect(find.text('Appendix F Pipeline'), findsOneWidget);
    expect(find.text('Opening Progress'), findsOneWidget);
  });

  testWidgets('it survives the frame before any data arrives', (tester) async {
    tester.view.physicalSize = wide;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // Empty lists everywhere: averages are null, totals are zero and the
    // bar lists have nothing to scale against. This is a real frame, not a
    // hypothetical one.
    await tester.pumpWidget(harness(loaded: false));
    await tester.pumpAndSettle();

    for (final tab in ['TOC & Opening', 'Tender Security', 'VTM Monitoring']) {
      await openTab(tester, tab);
      expect(
        tester.takeException(),
        isNull,
        reason: 'the $tab panel threw with no records',
      );
    }

    // A dash rather than RM 0: nothing held and nothing read differ. Asserted
    // on the tab that shows it, since the loop above ends elsewhere.
    await openTab(tester, 'Tender Security');
    expect(find.text('No data'), findsOneWidget);
    expect(find.text('No tender security data'), findsWidgets);
  });
}
