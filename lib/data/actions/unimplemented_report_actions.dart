// lib/data/actions/unimplemented_report_actions.dart
//
// What the app ships with until the actions are wired up.
//
// Every method throws. That is deliberate: a button with nothing behind it
// should say so, not look like it worked. Before this existed each of these
// was a silent `() {}` buried in a widget, which meant an unwired button
// was indistinguishable from a working one.
import 'package:etender_reports/data/actions/report_actions.dart';

class UnimplementedReportActions extends ReportActions {
  const UnimplementedReportActions();

  static Never _todo(String call, String what) => throw UnimplementedError(
    '$call: $what Implement ReportActions and pass it to ReportsPage.',
  );

  @override
  Future<void> uploadNewDocument() async => _todo(
    'uploadNewDocument()',
    'no file picker or upload endpoint is wired up.',
  );

  @override
  Future<void> uploadRequiredDocument(String documentName) async => _todo(
    'uploadRequiredDocument("$documentName")',
    'no file picker or upload endpoint is wired up.',
  );

  @override
  Future<void> renewDocument(String documentName) async =>
      _todo('renewDocument("$documentName")', 'no renewal flow is wired up.');

  @override
  void openTenderForBidding(String tenderNo) => _todo(
    'openTenderForBidding("$tenderNo")',
    'the bidding screen belongs to another module; route to it here.',
  );

  @override
  void viewTender(String tenderNo) => _todo(
    'viewTender("$tenderNo")',
    'the tender detail screen belongs to another module; route to it here.',
  );

  @override
  void openModule(AppModule module) => _todo(
    'openModule(${module.name})',
    'this reports module does not own the rest of the app.',
  );
}
