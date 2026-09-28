// lib/data/actions/unimplemented_report_actions.dart
//
// What the app ships with until the actions are wired up.
//
// Every method throws. That is deliberate: a button with nothing behind it
// should say so, not look like it worked. Before this existed each of these
// was a silent `() {}` buried in a widget, which meant an unwired button
// was indistinguishable from a working one.
//
// The throw only reaches a person because every call site goes through
// `runReportAction` (lib/shared/utils/run_report_action.dart), which turns
// it into a SnackBar. Thrown straight out of an `onTap` it would just be
// logged to the console, leaving the button looking inert. Call actions
// through that helper, not directly.
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
  Future<void> updateTenderSecurity(
    String uniqueNo,
    TenderSecurityPatch patch,
  ) async => _todo(
    'updateTenderSecurity("$uniqueNo", ${patch.describe})',
    'no endpoint is wired up, so this change is on screen only and a '
        'reload will lose it.',
  );

  @override
  void openTenderSecurityScanCopy(String url) => _todo(
    'openTenderSecurityScanCopy("$url")',
    'no file host is wired up; point this at wherever scans are served.',
  );

  @override
  void appointTocCommittee(String tenderNo) => _todo(
    'appointTocCommittee("$tenderNo")',
    'the TOC appointment screen belongs to another module; route to it here.',
  );

  @override
  void startTocOpening(String tenderNo) => _todo(
    'startTocOpening("$tenderNo")',
    'the opening screen belongs to another module; route to it here.',
  );

  @override
  void fileTocAppendixP(String tenderNo) => _todo(
    'fileTocAppendixP("$tenderNo")',
    'the Appendix P form belongs to another module; route to it here.',
  );

  @override
  void viewTocOpening(String tenderNo) => _todo(
    'viewTocOpening("$tenderNo")',
    'the TOC record screen belongs to another module; route to it here.',
  );

  @override
  void openModule(AppModule module) => _todo(
    'openModule(${module.name})',
    'this reports module does not own the rest of the app.',
  );
}
