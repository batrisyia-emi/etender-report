// lib/data/actions/report_actions.dart
//
// The seam for everything the app *does*, as [ReportRepository] is the seam
// for everything it *reads*.
//
// A button that will eventually call a backend or leave this module routes
// through here rather than holding its own handler. That keeps the widgets
// free of wiring and puts every outbound action in one file a backend
// developer can read end to end.
//
// Construct [ReportsPage] with an implementation to wire them up; the
// default is [UnimplementedReportActions], which throws rather than
// silently doing nothing.

/// The other parts of the eTender system the sidebar can hand off to.
///
/// This reports module is one screen inside a larger app, so these are
/// navigation out of it rather than anything it renders itself.
enum AppModule {
  /// The RFC module.
  rfc,

  /// The tender / quotation module.
  tenderQuotation,

  /// The TOC review screen.
  tocReview,

  /// Back to the host application's main menu.
  mainMenu,
}

/// Everything a button in this module can ask the wider system to do.
///
/// Nothing here is implemented by the reports module: uploading a file
/// needs a picker and an endpoint, and the bidding screen belongs to
/// another part of the system. The reports only know which document or
/// tender was pressed.
abstract class ReportActions {
  const ReportActions();

  // ---- Documents -------------------------------------------------------

  /// "Upload new" in the Documents header: add a file the supplier is
  /// filing on its own account, not against one of the mandatory slots.
  ///
  /// The implementation owns the whole flow — showing a file picker,
  /// uploading, and refreshing the report afterwards.
  Future<void> uploadNewDocument();

  /// The "Upload" on a mandatory document the supplier has never filed.
  ///
  /// [documentName] is the slot being filled, exactly as the Documents tab
  /// lists it, e.g. 'EPF / KWSP Contribution Statement'. Picking the file
  /// belongs to the implementation.
  Future<void> uploadRequiredDocument(String documentName);

  /// The "Renew" / "Renew now" on a document that is expiring or already
  /// expired, e.g. 'CIDB Certificate (G5 - Electrical)'.
  Future<void> renewDocument(String documentName);

  // ---- Tenders ---------------------------------------------------------

  /// "Bid now" on a tender closing soon: open wherever a supplier submits
  /// a bid. [tenderNo] is the tender's number, e.g. 'SESB/Q/2026/058'.
  ///
  /// The bidding screen is not part of this module, so this is navigation
  /// out of it.
  void openTenderForBidding(String tenderNo);

  /// "View" on a tender that is not closing imminently: open its details.
  /// Same destination as [openTenderForBidding] in most systems, minus the
  /// intent to bid straight away.
  void viewTender(String tenderNo);

  // ---- Leaving the module ----------------------------------------------

  /// Leave the reports module for another part of the system.
  void openModule(AppModule module);
}
