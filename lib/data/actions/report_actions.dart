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
///
/// Only one destination survives. The sidebar used to link to the RFC,
/// Tender/Quotation and TOC Review modules as well, but none of them exist
/// in this frontend, so they were dropped rather than left as buttons that
/// only apologise. Adding one back is a value here plus an entry in
/// `SidebarNav`.
/// The changed fields of one tender security row.
///
/// A field left null was not touched. Clearing a nullable field is a
/// separate flag, because null already means "unchanged" here.
class TenderSecurityPatch {
  const TenderSecurityPatch({
    this.originalCopyReceived,
    this.submittedToRevenueAssuranceDate,
    this.clearSubmittedToRevenueAssuranceDate = false,
    this.unsuccessfulTenderer,
    this.clearUnsuccessfulTenderer = false,
    this.refundDate,
    this.clearRefundDate = false,
  });

  final bool? originalCopyReceived;

  /// When it went to Revenue Assurance / Contract Services. A date, not a
  /// tick — see open question Q1 in docs/tender-security-report.md.
  final DateTime? submittedToRevenueAssuranceDate;
  final bool clearSubmittedToRevenueAssuranceDate;

  /// `YES`, `NO`, or null for "not decided". Set
  /// [clearUnsuccessfulTenderer] to send that null deliberately.
  final String? unsuccessfulTenderer;
  final bool clearUnsuccessfulTenderer;

  final DateTime? refundDate;
  final bool clearRefundDate;

  /// The PATCH body: only what changed.
  Map<String, dynamic> toJson() => {
    if (originalCopyReceived != null)
      'originalCopyReceived': originalCopyReceived,
    if (clearSubmittedToRevenueAssuranceDate)
      'submittedToRevenueAssuranceDate': null
    else if (submittedToRevenueAssuranceDate != null)
      'submittedToRevenueAssuranceDate': submittedToRevenueAssuranceDate!
          .toIso8601String(),
    if (clearUnsuccessfulTenderer)
      'unsuccessfulTenderer': null
    else if (unsuccessfulTenderer != null)
      'unsuccessfulTenderer': unsuccessfulTenderer,
    if (clearRefundDate)
      'refundDate': null
    else if (refundDate != null)
      'refundDate': refundDate!.toIso8601String(),
  };

  /// Names the field that changed, for the "not wired up" notice.
  String get describe => toJson().keys.join(', ');
}

enum AppModule {
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

  // ---- Tender security -------------------------------------------------

  /// PATCH /api/vtm/tender-security/{uniqueNo}
  ///
  /// The four VTM-owned fields on a tender security row. Only the ones that
  /// changed are sent; a null in [patch] means "no change", which is why
  /// clearing a field has its own flag rather than passing null.
  ///
  /// The report applies the edit to its own copy as soon as it is made, so
  /// the table responds. That is display only — this call is what makes it
  /// real, and until it is implemented a reload loses the change.
  Future<void> updateTenderSecurity(String uniqueNo, TenderSecurityPatch patch);

  /// Open a tender security's scan copy. [url] is the `scanCopy` the
  /// endpoint supplied, and is relative to whatever host serves files.
  void openTenderSecurityScanCopy(String url);

  // ---- Tender Opening Committee ----------------------------------------
  //
  // The buttons on the TOC report's "Needs Attention" panel. Each flag there
  // names one remedy (see TocRemedy) and these are where those remedies go.

  /// "Appoint committee": open the appointment screen for [tenderNo], where
  /// three members are named. Raised when an opening has no committee and is
  /// closing soon, or when an extension cleared the committee it had.
  void appointTocCommittee(String tenderNo);

  /// "Start opening": open the session for [tenderNo], whose opening day
  /// has come and whose opening has not begun. Where that leads depends on
  /// the envelope arrangement — one envelope is opened once, two are opened
  /// in turn — which is the opening module's business, not this report's.
  void startTocOpening(String tenderNo);

  /// "File Appendix P": open the form that closes out [tenderNo]'s opening
  /// day. Who fills it is still an open question for the BA — see
  /// docs/toc-report.md.
  void fileTocAppendixP(String tenderNo);

  /// "View" on a flagged opening: its TOC record.
  ///
  /// Not the same screen as [viewTender], which shows the tender itself.
  /// This one shows the committee, the declarations and the appendices.
  void viewTocOpening(String tenderNo);

  // ---- Leaving the module ----------------------------------------------

  /// Leave the reports module for another part of the system.
  void openModule(AppModule module);
}
