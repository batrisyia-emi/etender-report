// test/widgets/supplier_dashboard_test.dart
//
// The supplier dashboard takes no blocs — it reads the mock profile and
// supplier rows directly — so it is cheap to render and there was no
// excuse for having no test of it.
//
// The width cases are the point. The stage row used to be pinned at
// 1040px inside a horizontal scroller; it now wraps, and these pin that
// down at the three widths the grid distinguishes.
import 'package:etender_reports/reports/views/supplier_dashboard_view.dart';
import 'package:etender_reports/reports/widgets/dashboard/supplier/supplier_bid_stage_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget harness() => const MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: SupplierDashboardView(fillHeight: false),
    ),
  ),
);

Future<void> pumpAt(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(harness());
  await tester.pumpAndSettle();
}

/// Horizontal scrollers *inside the stage grid* that have somewhere to go.
///
/// Scoped to the grid on purpose: the period strip above it scrolls
/// sideways by design once there are more periods than fit, and that is not
/// what this file is about.
int overflowingHorizontalScrollers(WidgetTester tester) {
  var count = 0;
  final inGrid = find.descendant(
    of: find.byType(SupplierBidStageGrid),
    matching: find.byType(Scrollable),
  );
  for (final element in inGrid.evaluate()) {
    final state = element as StatefulElement;
    final scrollable = state.state as ScrollableState;
    if (scrollable.widget.axisDirection != AxisDirection.right) continue;
    if (!scrollable.position.hasContentDimensions) continue;
    if (scrollable.position.maxScrollExtent > 0) count++;
  }
  return count;
}

const _stat = SupplierBidStat(
  label: 'Label',
  value: 1,
  hint: 'Hint',
  color: Colors.blue,
  icon: Icons.circle,
);

void main() {
  group('SupplierDashboardView', () {
    testWidgets('renders the four numbered stages', (tester) async {
      await pumpAt(tester, const Size(1400, 1600));

      expect(find.byType(SupplierBidStageCard), findsNWidgets(4));
      expect(find.text('REQUEST TO PARTICIPATE'), findsOneWidget);
      expect(find.text('DOCUMENT PURCHASE'), findsOneWidget);
      expect(find.text('PARTICIPATION'), findsOneWidget);
      expect(find.text('BID SUBMISSION'), findsOneWidget);

      // Nine statuses across the four stages.
      expect(find.byType(SupplierBidStatTile), findsNWidgets(9));
    });

    testWidgets('shows the heading once, not twice', (tester) async {
      await pumpAt(tester, const Size(1400, 1600));

      // The tab strip used to carry a single inert 'My Bid' tab directly
      // above the 'My Bid' heading.
      expect(find.text('My Bid'), findsOneWidget);
    });

    testWidgets('the stages wrap rather than scroll sideways', (tester) async {
      // Below the four-column breakpoint, which used to force the row into
      // a horizontal scroller.
      await pumpAt(tester, const Size(900, 2000));

      expect(find.byType(SupplierBidStageCard), findsNWidgets(4));
      expect(
        overflowingHorizontalScrollers(tester),
        0,
        reason: 'the stage grid should wrap, not scroll sideways',
      );
    });

    testWidgets('it holds together on a narrow window', (tester) async {
      await pumpAt(tester, const Size(520, 3000));

      expect(tester.takeException(), isNull);
      expect(find.byType(SupplierBidStageCard), findsNWidgets(4));
    });

    testWidgets('every card is the same size', (tester) async {
      // The regression this guards: stage one holds three tiles and the
      // others two, so letting a card stretch to fit its contents made it
      // 47% wider than its neighbours.
      for (final size in [
        const Size(1400, 2600),
        const Size(1000, 3000),
        const Size(700, 3600),
      ]) {
        await pumpAt(tester, size);

        final cards = [
          for (final e in find.byType(SupplierBidStageCard).evaluate())
            (e.renderObject! as RenderBox).size,
        ];
        expect(cards, hasLength(4));
        expect(
          cards.map((s) => s.width.toStringAsFixed(1)).toSet(),
          hasLength(1),
          reason: 'cards differ in width at ${size.width}: $cards',
        );
      }
    });

    testWidgets('every tile is the same width', (tester) async {
      for (final size in [
        const Size(1400, 2600),
        const Size(1000, 3000),
        const Size(700, 3600),
      ]) {
        await pumpAt(tester, size);

        final widths = {
          for (final e in find.byType(SupplierBidStatTile).evaluate())
            (e.renderObject! as RenderBox).size.width.toStringAsFixed(1),
        };
        expect(
          widths,
          hasLength(1),
          reason: 'tiles differ in width at ${size.width}: $widths',
        );
      }
    });

    test('tiles sit two abreast until there is no room', () {
      const stage3 = SupplierBidStage('1', 'Three', [_stat, _stat, _stat]);
      const stage2 = SupplierBidStage('2', 'Two', [_stat, _stat]);
      const grid = SupplierBidStageGrid(
        stages: [stage3, stage2, stage2, stage2],
      );

      expect(grid.layoutFor(1400), (4, 2));
      expect(grid.layoutFor(1000), (2, 2));
      expect(grid.layoutFor(700), (2, 2));
      expect(grid.layoutFor(500), (1, 2));
      // A phone: one stage across, one tile per line.
      expect(grid.layoutFor(260), (1, 1));
    });

    test('a three-tile stage wraps rather than squeezing', () {
      const stage3 = SupplierBidStage('1', 'Three', [_stat, _stat, _stat]);
      expect(
        const SupplierBidStageCard(stage: stage3).lines.map((l) => l.length),
        [2, 1],
      );

      const stage2 = SupplierBidStage('2', 'Two', [_stat, _stat]);
      expect(
        const SupplierBidStageCard(stage: stage2).lines.map((l) => l.length),
        [2],
      );
    });
  });
}
