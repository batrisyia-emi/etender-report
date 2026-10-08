// lib/reports/report_type.dart

/// Every page reachable from the sidebar. Lives outside the widget layer so
/// the bloc and state can reference it without importing UI.
enum ReportType {
  /// Not reports: each view opens on its own dashboard.
  ///
  /// Both carry the nav label 'Dashboard' because the dropdown they sit in
  /// already says whose it is; only the page heading spells it out.
  seDashboard(navLabel: 'Dashboard', pageTitle: 'SE Dashboard'),
  supplierDashboard(navLabel: 'Dashboard', pageTitle: 'Supplier Dashboard'),
  tenderSummary(
    navLabel: 'Tender/Quotation Summary',
    pageTitle: 'Tender/Quotation Summary Report',
  ),
  vendorParticipation(
    navLabel: 'Vendor Participation',
    pageTitle: 'Vendor Participation Report',
  ),

  /// Named from the supplier's side rather than the registry's: a supplier
  /// only ever sees its own rows here, never another supplier's.
  supplier(navLabel: 'My Participation', pageTitle: 'My Participation Report'),
  erfc(navLabel: 'eRFC Reports', pageTitle: 'eRFC Reports'),
  toc(
    navLabel: 'TOC & Opening',
    pageTitle: 'TOC Appointment & Tender Opening Status',
  ),
  tenderSecurity(
    navLabel: 'Tender Security',
    pageTitle: 'Tender Security Report',
  ),
  vtmMonitoring(
    navLabel: 'VTM Monitoring',
    pageTitle: 'VTM Tender/Quotation Monitoring Report',
  );

  const ReportType({required this.navLabel, required this.pageTitle});

  /// Short form, for the sidebar.
  final String navLabel;

  /// Full form, for the page heading and the report header.
  final String pageTitle;

  /// True for everything except the two dashboards.
  ///
  /// A report draws its own header — title, criteria, record count — so the
  /// shell leaves the heading to it rather than printing the title twice.
  bool get isReport =>
      this != ReportType.seDashboard && this != ReportType.supplierDashboard;
}
