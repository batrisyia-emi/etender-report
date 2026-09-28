// lib/shared/utils/run_report_action.dart
import 'dart:async';

import 'package:flutter/material.dart';

/// Calls a [ReportActions] method and, when it is not wired up yet, says so
/// on screen.
///
/// `UnimplementedReportActions` throws from every method on purpose, so an
/// unwired button cannot be mistaken for a working one. Thrown straight out
/// of an `onTap` that backfires: Flutter reports the exception to the
/// console and the button appears to do nothing, which is the exact
/// confusion the throwing was meant to prevent. The async methods are worse
/// — their failed Future is assigned to a `VoidCallback`, so nothing ever
/// awaits it.
///
/// Routing every call through here keeps the loud signal and puts it
/// somewhere a person can see. Only [UnimplementedError] is caught; once a
/// real implementation is supplied, its own failures propagate as normal
/// and are not swallowed here.
void runReportAction(BuildContext context, FutureOr<void> Function() action) {
  // Captured before the await so the callback never touches a context that
  // may have been unmounted by then.
  final messenger = ScaffoldMessenger.of(context);

  void report(UnimplementedError error) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'This action is not wired up yet.'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          showCloseIcon: true,
        ),
      );
  }

  try {
    final result = action();
    // onError catches only this type; anything else stays unhandled, which
    // is what a real bug should do.
    if (result is Future<void>) {
      result.onError<UnimplementedError>((error, _) => report(error));
    }
  } on UnimplementedError catch (error) {
    report(error);
  }
}
