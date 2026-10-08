// test/widgets/report_header_test.dart
//
// The header is what makes these screens readable as reports: it names
// itself, says when it ran, states its criteria and admits how much of the
// data it is showing. Each of those is a claim that has to stay true.
import 'package:etender_reports/reports/models/filters/report_criteria.dart';
import 'package:etender_reports/reports/widgets/shared/report_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pump(
  WidgetTester tester, {
  List<ReportCriterion> criteria = const [],
  int shown = 10,
  int total = 10,
  String unit = 'records',
}) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ReportHeader(
            title: 'Tender/Quotation Summary Report',
            criteria: criteria,
            shownCount: shown,
            totalCount: total,
            unit: unit,
            generatedAt: DateTime(2026, 10, 7, 14, 32),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('names the report', (tester) async {
    await pump(tester);

    expect(find.text('Tender/Quotation Summary Report'), findsOneWidget);
  });

  testWidgets('states the count and the run time on one line', (tester) async {
    await pump(tester, shown: 42, total: 42, unit: 'tenders');

    // One line, not three labelled rows. Pinned through generatedAt so the
    // assertion does not drift with the clock.
    expect(find.text('42 tenders  ·  07/10/2026 14:32'), findsOneWidget);
  });

  testWidgets('stays compact', (tester) async {
    // The guard on this file's whole point: the first version of the header
    // was 198px tall above a filter panel that is already tall.
    await pump(tester);
    final plain = tester.getSize(find.byType(ReportHeader)).height;

    await pump(
      tester,
      criteria: const [
        ReportCriterion('Status', 'Published'),
        ReportCriterion('Division', 'Distribution'),
      ],
      shown: 18,
      total: 42,
    );
    final withCriteria = tester.getSize(find.byType(ReportHeader)).height;

    expect(plain, lessThan(60));
    expect(withCriteria, lessThan(90));
  });

  testWidgets('shows no criteria row when nothing is filtered', (tester) async {
    await pump(tester);

    // Nothing to say, so nothing is said — the old version spent a whole
    // labelled row on "None applied". Unfiltered, the header is exactly the
    // title and the count line.
    expect(find.byType(Text), findsNWidgets(2));
  });

  testWidgets('lists each criterion that is applied', (tester) async {
    await pump(
      tester,
      criteria: const [
        ReportCriterion('Status', 'Published, Extended'),
        ReportCriterion('Division', 'Distribution'),
      ],
      shown: 18,
      total: 42,
    );

    // The chips are RichText — label and value are separate spans — so the
    // finder has to be told to look inside them.
    expect(find.textContaining('Status', findRichText: true), findsWidgets);
    expect(
      find.textContaining('Distribution', findRichText: true),
      findsWidgets,
    );
  });

  testWidgets('"of" appears only when rows were excluded', (tester) async {
    await pump(tester, shown: 42, total: 42, unit: 'tenders');
    expect(find.textContaining('42 tenders  ·'), findsOneWidget);

    await pump(tester, shown: 18, total: 42, unit: 'tenders');
    expect(find.textContaining('18 of 42 tenders  ·'), findsOneWidget);
  });

  testWidgets('explains an empty result rather than leaving it blank', (
    tester,
  ) async {
    await pump(
      tester,
      criteria: const [ReportCriterion('Status', 'Completed')],
      shown: 0,
      total: 42,
    );

    expect(find.textContaining('0 of 42 records'), findsOneWidget);
    expect(find.text('No record matches these criteria.'), findsOneWidget);
  });

  testWidgets('a genuinely empty report does not blame the filters', (
    tester,
  ) async {
    // Nothing filtered and nothing to show: the data is absent, not hidden.
    await pump(tester, shown: 0, total: 0);

    expect(find.textContaining('0 records'), findsOneWidget);
    expect(find.text('No record matches these criteria.'), findsNothing);
  });

  testWidgets('a long criteria list wraps instead of overflowing', (
    tester,
  ) async {
    await pump(
      tester,
      criteria: const [
        ReportCriterion('Search', '"substation maintenance"'),
        ReportCriterion('Status', 'Published, Extended, Closed, Completed'),
        ReportCriterion('Category', 'Work, Service, Supply & Delivery'),
        ReportCriterion('Division', 'Distribution, Generation, Transmission'),
        ReportCriterion('Department', 'Engineering, Operations'),
        ReportCriterion('Value', 'RM 50,000 and above'),
        ReportCriterion('Closing', '01/09/2026 – 31/10/2026'),
      ],
      shown: 3,
      total: 42,
    );

    expect(tester.takeException(), isNull);
  });
}
