import 'dart:async';

import 'package:etender_reports/reports/procurement_lead_time/bloc/lead_time_cubit.dart';
import 'package:etender_reports/reports/procurement_lead_time/data/lead_time_repository.dart';
import 'package:etender_reports/reports/procurement_lead_time/data/mock_lead_time_repository.dart';
import 'package:etender_reports/reports/procurement_lead_time/lead_time_rules.dart';
import 'package:etender_reports/reports/procurement_lead_time/models/lead_time_query.dart';
import 'package:etender_reports/reports/procurement_lead_time/models/lead_time_record.dart';
import 'package:etender_reports/reports/procurement_lead_time/procurement_lead_time_screen.dart';
import 'package:etender_reports/reports/procurement_lead_time/widgets/lead_time_filter_bar.dart';
import 'package:etender_reports/reports/procurement_lead_time/widgets/lead_time_rating_explanation.dart';
import 'package:etender_reports/reports/widgets/shared/kpi_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingRepository extends LeadTimeRepository {
  int calls = 0;

  @override
  Future<Set<DateTime>> fetchHolidays() async => {};

  @override
  Future<List<LeadTimeRecord>> fetchRecords({
    required DateTime publishedFrom,
    required DateTime publishedTo,
    DocumentTypeFilter type = DocumentTypeFilter.tender,
    String? procurementMode,
  }) async {
    calls++;
    throw Exception('offline');
  }
}

/// The day the screen counts its periods from in these tests.
final _today = DateTime(2026, 10, 19);

final _allMockDates = LeadTimeQuery(
  publishedFrom: DateTime(2026, 9, 1),
  publishedTo: DateTime(2026, 10, 31),
);

Future<LeadTimeCubit> _pump(
  WidgetTester tester, {
  LeadTimeRepository repository = const MockLeadTimeRepository(
    latency: Duration.zero,
  ),
  Size size = const Size(1400, 1000),
  bool fillHeight = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final cubit = LeadTimeCubit(repository: repository);
  addTearDown(cubit.close);
  final screen = ProcurementLeadTimeScreen(
    sectionSpacing: 16,
    fillHeight: fillHeight,
    today: _today,
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
      home: Scaffold(
        body: BlocProvider.value(
          value: cubit,
          child: Padding(
            padding: const EdgeInsets.all(16),
            // As ReportsShell does: unpinned, the page itself scrolls.
            child: fillHeight ? screen : SingleChildScrollView(child: screen),
          ),
        ),
      ),
    ),
  );
  return cubit;
}

ChoiceChip _chip(WidgetTester tester, String label) =>
    tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label));

/// Opens the date picker from the field showing [current] and picks [day]
/// of the month it opens on.
Future<void> _pickDay(WidgetTester tester, String current, String day) async {
  await tester.tap(_inFilters(current));
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(
      of: find.byType(DatePickerDialog),
      matching: find.text(day),
    ),
  );
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

const _badge = 'To date – not final';

/// [text] inside the filter bar only: the same date can also appear in the
/// drill-down table.
Finder _inFilters(String text) => find.descendant(
  of: find.byType(LeadTimeFilterBar),
  matching: find.text(text),
);

void main() {
  testWidgets('opens on Last month, already searched', (tester) async {
    final cubit = await _pump(tester);
    await tester.pumpAndSettle();

    expect(_chip(tester, 'Last month').selected, isTrue);
    expect(cubit.state.query?.preset, PeriodPreset.lastMonth);
    expect(
      find.text(
        'Result – Tender, published 01.09.2026 to 30.09.2026 '
        '(Last month) · 10 tenders',
      ),
      findsOneWidget,
    );
    expect(find.text(_badge), findsNothing);
  });

  testWidgets('This month fills the dates, searches and flags the result', (
    tester,
  ) async {
    final cubit = await _pump(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'This month'));
    await tester.pumpAndSettle();

    expect(_chip(tester, 'This month').selected, isTrue);
    expect(_inFilters('01.10.2026'), findsOneWidget);
    expect(_inFilters('19.10.2026'), findsOneWidget);
    expect(cubit.state.query?.preset, PeriodPreset.thisMonth);
    expect(
      find.text(
        'Result – Tender, published 01.10.2026 to 19.10.2026 '
        '(This month) · 5 tenders',
      ),
      findsOneWidget,
    );
    expect(find.text(_badge), findsOneWidget);
  });

  testWidgets('editing a date selects Custom and waits for Search', (
    tester,
  ) async {
    final cubit = await _pump(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'This month'));
    await tester.pumpAndSettle();
    final thisMonth = cubit.state;

    await _pickDay(tester, '01.10.2026', '5');

    expect(_chip(tester, 'Custom').selected, isTrue);
    expect(_inFilters('05.10.2026'), findsOneWidget);
    // The results, and the badge describing them, are still This month's.
    expect(cubit.state, thisMonth);
    expect(find.text(_badge), findsOneWidget);

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(cubit.state.query?.preset, PeriodPreset.custom);
    expect(
      find.textContaining('published 05.10.2026 to 19.10.2026 (Custom)'),
      findsOneWidget,
    );
    expect(find.text(_badge), findsNothing);
  });

  testWidgets('Custom alone changes neither the dates nor the results', (
    tester,
  ) async {
    final cubit = await _pump(tester);
    await tester.pumpAndSettle();
    final opened = cubit.state;

    await tester.tap(find.widgetWithText(ChoiceChip, 'Custom'));
    await tester.pumpAndSettle();

    expect(_chip(tester, 'Custom').selected, isTrue);
    expect(_inFilters('01.09.2026'), findsOneWidget);
    expect(cubit.state, opened);
  });

  testWidgets('an invalid custom range shows the error and does not search', (
    tester,
  ) async {
    final cubit = await _pump(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'This month'));
    await tester.pumpAndSettle();
    final before = cubit.state;

    await _pickDay(tester, '01.10.2026', '25'); // after To, 19.10.2026
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();

    expect(
      find.text('Published Date To must be on or after Published Date From'),
      findsOneWidget,
    );
    expect(cubit.state, before);
  });

  testWidgets('offers All modes and only the five published modes', (
    tester,
  ) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    expect(find.byType(Radio<String>), findsNWidgets(6));
    for (final label in [
      'All modes',
      '7.1 Tender/Quotation',
      '7.2 Selective Tender/Quotation',
      '7.3 Restricted Tender/Quotation',
      '7.5 Tender Through Pre-Qualification',
      '7.6 Schedule Rate/JHT',
    ]) {
      expect(_inFilters(label), findsOneWidget);
    }
    // None of the eleven modes that are never published.
    for (final absent in ['7.4', 'Direct Negotiation', 'Variation Order']) {
      expect(
        find.descendant(
          of: find.byType(LeadTimeFilterBar),
          matching: find.textContaining(absent),
        ),
        findsNothing,
      );
    }
    expect(_inFilters('Document Type'), findsOneWidget);
  });

  testWidgets('one mode narrows the search once Search is pressed', (
    tester,
  ) async {
    final cubit = await _pump(tester);
    await tester.pumpAndSettle();
    final opened = cubit.state;

    await tester.tap(_inFilters('7.2 Selective Tender/Quotation'));
    await tester.pumpAndSettle();
    // Waits for Search, like Document Type.
    expect(cubit.state, opened);

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();

    expect(cubit.state.query?.procurementMode, '7.2');
    final items = cubit.state.summaries.single.items;
    expect(items, isNotEmpty);
    expect(items.every((i) => i.record.procurementMode == '7.2'), isTrue);
    expect(
      find.text(
        'Result – Tender, 7.2 Selective Tender/Quotation, published '
        '01.09.2026 to 30.09.2026 (Last month) · 2 tenders',
      ),
      findsOneWidget,
    );

    // Back to All modes.
    await tester.tap(_inFilters('All modes'));
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(cubit.state.query?.procurementMode, isNull);
    expect(cubit.state.total, 10);
  });

  testWidgets('shows the rating in the table and the result header', (
    tester,
  ) async {
    final cubit = await _pump(tester);
    await tester.pumpAndSettle();

    // Last month, Tender: 8 of 10 within 3 working days, all within 7.
    expect(cubit.state.summaries.single.rating, PerformanceRating.good);
    expect(find.text('Performance Rating'), findsOneWidget);
    expect(find.text('Rating: Good'), findsOneWidget);
  });

  testWidgets('explains the rating once, beside the Tender rating card', (
    tester,
  ) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    final explanation = find.text('How the performance rating is calculated');
    expect(explanation, findsOneWidget);
    // SE's wording, word for word, and the note.
    const good =
        'At least 90% - 94% are published within 7 working days (the 1–3 and '
        '4–7 working day bands together).';
    for (final line in [
      '95% - 100% of tenders are published within 3 working days.',
      good,
      'Less than 90% are published after 7 working days.',
    ]) {
      expect(find.text(line), findsOneWidget);
    }
    expect(
      find.textContaining(
        'The Received by VTM date is derived from the Confirmed to Proceed '
        'date.',
        findRichText: true,
      ),
      findsOneWidget,
    );

    // Beside the rating card, and level with the card column at both ends:
    // the first card's top and the rating card's bottom.
    Rect cardAround(String header) => tester.getRect(
      find.ancestor(of: find.text(header), matching: find.byType(KpiCard)),
    );
    final firstCard = cardAround('WITHIN 3 WORKING DAYS (%)');
    final ratingCard = cardAround('PERFORMANCE RATING');
    final panel = tester.getRect(find.byType(LeadTimeRatingExplanation));
    expect(panel.left, greaterThan(ratingCard.right));
    expect(panel.top, moreOrLessEquals(firstCard.top, epsilon: 0.5));
    expect(panel.bottom, moreOrLessEquals(ratingCard.bottom, epsilon: 0.5));
  });

  testWidgets('All shows the explanation once, in the Tender section', (
    tester,
  ) async {
    final cubit = await _pump(tester);
    await tester.pumpAndSettle();
    unawaited(
      cubit.search(
        LeadTimeQuery(
          publishedFrom: _allMockDates.publishedFrom,
          publishedTo: _allMockDates.publishedTo,
          type: DocumentTypeFilter.all,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('How the performance rating is calculated'),
      findsOneWidget,
    );
  });

  testWidgets('the header link opens the explanation in a dialog', (
    tester,
  ) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('How is the rating calculated?'));
    await tester.pumpAndSettle();

    final inDialog = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.textContaining('published within 3 working days'),
    );
    expect(inDialog, findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('All rates each document type in the header', (tester) async {
    final cubit = await _pump(tester);
    await tester.pumpAndSettle();
    unawaited(
      cubit.search(
        LeadTimeQuery(
          publishedFrom: _allMockDates.publishedFrom,
          publishedTo: _allMockDates.publishedTo,
          type: DocumentTypeFilter.all,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Performance Rating'), findsNWidgets(2));
    expect(find.text('Tender: Good'), findsOneWidget);
    expect(find.text('Quotation: Good'), findsOneWidget);
  });

  testWidgets('shows the Tender summary, cards and drill-down', (tester) async {
    final cubit = await _pump(tester);
    unawaited(cubit.search(_allMockDates));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Result – Tender, published 01.09.2026 to 31.10.2026 '
        '(Custom) · 15 tenders',
      ),
      findsOneWidget,
    );
    final tender = cubit.state.summaries.single;
    // The slowest tender is the only one over 7 working days.
    expect(tender.countIn(tender.items.first.bucket), 1);
    expect(
      [
        for (final b in [0, 1, 2]) tender.counts.values.elementAt(b),
      ],
      [9, 5, 1],
    );
    // The card's value, the summary table's rating row and the
    // explanation's key.
    expect(find.text('Good'), findsNWidgets(3));
    expect(
      find.text('Drill-down – 1–3 working days, 9 tenders'),
      findsOneWidget,
    );

    // Tap the 4–7 count.
    // The summary table sits under the cards and the explanation.
    await tester.ensureVisible(find.widgetWithText(TextButton, '5'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '5'));
    await tester.pumpAndSettle();
    expect(
      find.text('Drill-down – 4–7 working days, 5 tenders'),
      findsOneWidget,
    );
    // Slowest first: T.10429 (7 working days) heads the band.
    final shown = cubit.state.selectedSummary!.itemsIn(
      cubit.state.selection!.bucket,
    );
    expect(shown.first.record.tenderNo, 'T.10429');
    expect(shown.first.workingDays, 7);
    expect(find.text('T.10429'), findsOneWidget);
  });

  testWidgets('All shows separate Tender and Quotation tables', (tester) async {
    final cubit = await _pump(tester);
    unawaited(
      cubit.search(
        LeadTimeQuery(
          publishedFrom: _allMockDates.publishedFrom,
          publishedTo: _allMockDates.publishedTo,
          type: DocumentTypeFilter.all,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(cubit.state.summaries.map((s) => s.total), [15, 10]);
    expect(cubit.state.summaries.last.counts.values.toList(), [7, 2, 1]);
    expect(find.text('Tender'), findsWidgets);
    expect(find.text('Quotation'), findsWidgets);
    expect(
      find.text('Drill-down – Tender, 1–3 working days, 9 tenders'),
      findsOneWidget,
    );
  });

  testWidgets('an empty period says so', (tester) async {
    final cubit = await _pump(tester);
    unawaited(
      cubit.search(
        LeadTimeQuery(
          publishedFrom: DateTime(2025, 1, 1),
          publishedTo: DateTime(2025, 1, 31),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No results'), findsOneWidget);
  });

  testWidgets('a failure offers Retry', (tester) async {
    final repository = _FailingRepository();
    await _pump(tester, repository: repository);
    await tester.pumpAndSettle();
    expect(find.text('Could not load procurement lead times.'), findsOneWidget);
    expect(repository.calls, 1);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(repository.calls, 2);
  });

  testWidgets('narrow width does not overflow', (tester) async {
    final cubit = await _pump(
      tester,
      size: const Size(420, 900),
      fillHeight: false,
    );
    unawaited(cubit.search(_allMockDates));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // Chips give way to one Period dropdown.
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.byType(DropdownButton<PeriodPreset>), findsOneWidget);
  });
}
