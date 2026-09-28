// test/widgets/run_report_action_test.dart
import 'package:etender_reports/shared/utils/run_report_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps a button that runs [action] through `runReportAction`.
Future<void> pumpButton(
  WidgetTester tester,
  Future<void> Function() action,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => runReportAction(context, action),
            child: const Text('Go'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('a synchronous UnimplementedError becomes a SnackBar', (
    tester,
  ) async {
    await pumpButton(
      tester,
      () => throw UnimplementedError('openModule(tocReview): not wired up.'),
    );

    await tester.tap(find.text('Go'));
    await tester.pump();

    expect(
      find.text('UnimplementedError: openModule(tocReview): not wired up.'),
      findsNothing,
    );
    // The message only, without the exception's own type prefix.
    expect(find.text('openModule(tocReview): not wired up.'), findsOneWidget);
  });

  testWidgets('an async UnimplementedError becomes a SnackBar too', (
    tester,
  ) async {
    // uploadNewDocument and friends return a Future that nothing awaits, so
    // this is the path those three buttons take.
    await pumpButton(tester, () async {
      throw UnimplementedError('uploadNewDocument(): not wired up.');
    });

    await tester.tap(find.text('Go'));
    await tester.pump();
    await tester.pump();

    expect(find.text('uploadNewDocument(): not wired up.'), findsOneWidget);
  });

  testWidgets('an UnimplementedError with no message still says something', (
    tester,
  ) async {
    await pumpButton(tester, () => throw UnimplementedError());

    await tester.tap(find.text('Go'));
    await tester.pump();

    expect(find.text('This action is not wired up yet.'), findsOneWidget);
  });

  testWidgets('a wired action shows nothing', (tester) async {
    var called = false;
    await pumpButton(tester, () async => called = true);

    await tester.tap(find.text('Go'));
    await tester.pump();
    await tester.pump();

    expect(called, isTrue);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('any other error propagates rather than being swallowed', (
    tester,
  ) async {
    // A real implementation's own failures must not be quietly turned into
    // a "not wired up" notice.
    await pumpButton(tester, () => throw StateError('the server said no'));

    await tester.tap(find.text('Go'));
    await tester.pump();

    expect(tester.takeException(), isStateError);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('a second tap replaces the first notice', (tester) async {
    await pumpButton(
      tester,
      () => throw UnimplementedError('viewTender("T.10001"): not wired up.'),
    );

    await tester.tap(find.text('Go'));
    await tester.pump();
    await tester.tap(find.text('Go'));
    await tester.pump();
    // Long enough for the outgoing bar to finish its dismissal.
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
  });
}
