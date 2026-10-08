// test/widgets/report_timeline_filter_test.dart
//
// The reports and the dashboards now offer the same periods. Two things
// have to stay true for that to mean anything: the window a period covers
// is identical on both sides, and the buttons reflect the range rather than
// remembering what was last pressed.
import 'package:etender_reports/reports/widgets/dashboard/dashboard_period.dart';
import 'package:etender_reports/reports/widgets/shared/report_timeline_filter.dart';
import 'package:etender_reports/shared/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fixed clock, so none of this drifts with the real date.
final DateTime asOf = DateTime(2026, 10, 7, 9);

Future<DateTimeRange?> tapPeriod(
  WidgetTester tester,
  String label, {
  DateTimeRange? selected,
}) async {
  DateTimeRange? captured;
  var called = false;

  tester.view.physicalSize = const Size(1400, 600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ReportTimelineFilter(
          label: 'Closing date',
          selectedRange: selected,
          asOf: asOf,
          onChanged: (range) {
            captured = range;
            called = true;
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();

  expect(called, isTrue, reason: 'tapping "$label" reported nothing');
  return captured;
}

void main() {
  group('the window matches the dashboards', () {
    test('a period is whole months ending with the current one', () {
      final three = periodRange(DashPeriod.threeMonths, asOf: asOf);

      // August, September, October — not the last 90 days.
      expect(three.start, DateTime(2026, 8));
      expect(three.end.year, 2026);
      expect(three.end.month, 10);
      expect(three.end.day, 31);
    });

    test('this month is one month, not thirty days', () {
      final one = periodRange(DashPeriod.thisMonth, asOf: asOf);
      expect(one.start, DateTime(2026, 10));
      expect(one.end.day, 31);
    });

    test('a year spans twelve months back', () {
      expect(
        periodRange(DashPeriod.twelveMonths, asOf: asOf).start,
        DateTime(2025, 11),
      );
    });

    test('the offered periods are the dashboards own', () {
      expect(DashPeriod.values.map((p) => p.label), [
        'Today',
        'This Week',
        'This Month',
        '3 Months',
        '6 Months',
        '9 Months',
        '12 Months',
      ]);
    });

    test('the short periods are days and weeks, not months', () {
      // 7 October 2026 is a Wednesday.
      final today = periodRange(DashPeriod.today, asOf: asOf);
      expect(today.start, DateTime(2026, 10, 7));
      expect(today.end, DateTime(2026, 10, 7));

      final week = periodRange(DashPeriod.thisWeek, asOf: asOf);
      expect(week.start, DateTime(2026, 10, 5), reason: 'should be Monday');
      expect(week.end, DateTime(2026, 10, 11), reason: 'should be Sunday');
    });
  });

  group('the buttons read the range rather than remember a press', () {
    test('a preset range is recognised as its period', () {
      for (final period in DashPeriod.values) {
        expect(
          periodOf(periodRange(period, asOf: asOf), asOf: asOf),
          period,
          reason: '${period.label} was not recognised',
        );
      }
    });

    test('no range is no period', () {
      expect(periodOf(null, asOf: asOf), isNull);
    });

    test('a hand-picked range matches no preset', () {
      final custom = DateTimeRange(
        start: DateTime(2026, 9, 3),
        end: DateTime(2026, 9, 19),
      );
      expect(periodOf(custom, asOf: asOf), isNull);
    });
  });

  group('the control', () {
    testWidgets('leads with All, unlike the dashboards', (tester) async {
      // A dashboard opens on the current month; a report opens on
      // everything, because a report that quietly hid rows would be wrong
      // in a way nobody would notice.
      await tapPeriod(tester, 'All');
      expect(find.text('All'), findsOneWidget);
      expect(find.text('This Month'), findsOneWidget);
    });

    testWidgets('All clears the date filter', (tester) async {
      final range = await tapPeriod(
        tester,
        'All',
        selected: periodRange(DashPeriod.threeMonths, asOf: asOf),
      );
      expect(range, isNull);
    });

    testWidgets('a period reports the range it stands for', (tester) async {
      final range = await tapPeriod(tester, '6 Months');
      expect(range, isNotNull);
      expect(range!.start, DateTime(2026, 5));
    });

    testWidgets('says why nothing is lit on a custom range', (tester) async {
      tester.view.physicalSize = const Size(1400, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReportTimelineFilter(
              label: 'Closing date',
              selectedRange: DateTimeRange(
                start: DateTime(2026, 9, 3),
                end: DateTime(2026, 9, 19),
              ),
              asOf: asOf,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Custom range set in the filters'), findsOneWidget);
    });

    testWidgets('names the date it applies to', (tester) async {
      // Every report filters a different date, so the control has to say
      // which one rather than just "Period".
      await tapPeriod(tester, 'All');
      expect(find.text('Closing date'), findsOneWidget);
    });
  });

  testWidgets('the selected button is the only one highlighted', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReportTimelineFilter(
            label: 'Closing date',
            selectedRange: periodRange(DashPeriod.threeMonths, asOf: asOf),
            asOf: asOf,
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final highlighted = find
        .byType(Material)
        .evaluate()
        .map((e) => e.widget as Material)
        .where((m) => m.color == AppColors.accent)
        .length;
    expect(highlighted, 1);
  });
}
