// lib/reports/widgets/sidebar_nav.dart
import 'package:etender_reports/data/actions/report_actions.dart';
import 'package:etender_reports/reports/report_type.dart';
import 'package:flutter/material.dart';

class SidebarNav extends StatefulWidget {
  final double sidebarWidth;
  final bool isCompactLayout;
  final ReportType selectedReport;
  final ValueChanged<ReportType> onReportSelected;

  /// The entries that leave this module: RFC, Tender/Quotation, TOC Review
  /// and Back To Menu. The reports module does not own those screens, so it
  /// hands them off rather than routing itself.
  final ValueChanged<AppModule> onModuleSelected;

  const SidebarNav({
    super.key,
    required this.sidebarWidth,
    required this.isCompactLayout,
    required this.selectedReport,
    required this.onReportSelected,
    required this.onModuleSelected,
  });

  @override
  State<SidebarNav> createState() => _SidebarNavState();
}

class _SidebarNavState extends State<SidebarNav> {
  // All open on load, since a report inside them is what the screen shows.
  bool _reportsExpanded = true;
  bool _supplierViewExpanded = true;
  bool _seViewExpanded = true;

  /// Reports told from the supplier's side.
  static const List<ReportType> _supplierViewReports = [
    ReportType.supplierDashboard,
    ReportType.supplier,
  ];

  /// Reports told from Sabah Electricity's side. Vendor participation lives
  /// here because it is SE reading who took up its invitations, not a
  /// supplier reading its own.
  static const List<ReportType> _seViewReports = [
    ReportType.seDashboard,
    ReportType.tenderSummary,
    ReportType.vendorParticipation,
    ReportType.erfc,
  ];

  static const Color _activeBg = Color(0xFFE0F2FE);
  static const Color _activeIcon = Color(0xFF1D4ED8);
  static const Color _activeText = Color(0xFF1E40AF);

  static const Icon _dashboardIcon = Icon(Icons.grid_view_rounded);
  static const Icon _rfcIcon = Icon(Icons.assignment_outlined);
  static const Icon _tenderIcon = Icon(Icons.article_outlined);
  static const Icon _reportsIcon = Icon(Icons.analytics_outlined);
  static const Icon _tocIcon = Icon(Icons.people_outline);
  static const Icon _backIcon = Icon(Icons.arrow_back);
  static const Icon _supplierViewIcon = Icon(
    Icons.store_mall_directory_outlined,
  );
  static const Icon _seViewIcon = Icon(Icons.business_outlined);
  static const Icon _summaryIcon = Icon(Icons.table_chart_outlined);
  static const Icon _vendorIcon = Icon(Icons.storefront_outlined);
  static const Icon _supplierIcon = Icon(Icons.local_shipping_outlined);
  static const Icon _erfcIcon = Icon(Icons.request_page_outlined);

  /// The icon each report carries wherever it is listed.
  static Icon _iconFor(ReportType report) => switch (report) {
    ReportType.seDashboard => _dashboardIcon,
    ReportType.supplierDashboard => _dashboardIcon,
    ReportType.tenderSummary => _summaryIcon,
    ReportType.vendorParticipation => _vendorIcon,
    ReportType.supplier => _supplierIcon,
    ReportType.erfc => _erfcIcon,
  };

  /// 0 = top level, 1 = under Reports, 2 = under Supplier View or SE View.
  double _indentFor(int depth) {
    if (widget.isCompactLayout) return 8;
    return switch (depth) {
      0 => 8,
      1 => 20,
      _ => 32,
    };
  }

  Widget _buildItem({
    required Icon icon,
    required String title,
    required bool isActive,
    required VoidCallback onTap,
    Widget? trailing,
    int depth = 0,
  }) {
    final themedIcon = IconTheme(
      data: IconThemeData(
        color: isActive ? _activeIcon : Colors.grey.shade600,
        size: depth > 0 ? 18 : 21,
      ),
      child: icon,
    );

    // ListTile asserts when its leading widget fills the tile, which is
    // exactly what a labelless row in the 72px rail does — it took the
    // whole app down below 900px. The collapsed rail is just an icon, so
    // it does not need a ListTile at all.
    final Widget row = widget.isCompactLayout
        ? SizedBox(height: 40, child: Center(child: themedIcon))
        : ListTile(
            dense: true,
            horizontalTitleGap: depth > 0 ? 8 : null,
            visualDensity: VisualDensity.compact,
            leading: themedIcon,
            title: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isActive ? _activeText : Colors.grey.shade800,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: depth == 0 ? 13 : 12,
                height: 1.2,
              ),
            ),
            trailing: trailing,
            onTap: onTap,
          );

    final tile = Container(
      margin: EdgeInsets.only(
        left: _indentFor(depth),
        right: 8,
        top: 1,
        bottom: 1,
      ),
      decoration: BoxDecoration(
        color: isActive ? _activeBg : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Material(
        color: Colors.transparent,
        // ListTile brings its own InkWell; the collapsed rail needs one.
        child: widget.isCompactLayout
            ? InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(6),
                child: row,
              )
            : row,
      ),
    );

    // Labels are hidden in the collapsed sidebar, so the icon needs a tooltip.
    return widget.isCompactLayout ? Tooltip(message: title, child: tile) : tile;
  }

  /// A parent row plus its children, collapsed away when closed.
  Widget _buildExpandableSection({
    required Icon icon,
    required String title,
    required bool isExpanded,
    required bool containsSelection,
    required VoidCallback onToggle,
    required List<Widget> children,
    int depth = 0,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildItem(
          icon: icon,
          title: title,
          depth: depth,
          // While open, the active child carries the highlight instead.
          isActive: containsSelection && !isExpanded,
          trailing: AnimatedRotation(
            turns: isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 180),
            child: const Icon(Icons.expand_more, size: 20),
          ),
          onTap: onToggle,
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: isExpanded
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
      ],
    );
  }

  Widget _buildReportItem(ReportType report, int depth) {
    return _buildItem(
      icon: _iconFor(report),
      title: report.navLabel,
      isActive: widget.selectedReport == report,
      depth: depth,
      onTap: () => widget.onReportSelected(report),
    );
  }

  /// One of the two perspective dropdowns: the reports told from that side.
  Widget _buildViewSection({
    required Icon icon,
    required String title,
    required List<ReportType> reports,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    return _buildExpandableSection(
      icon: icon,
      title: title,
      depth: 1,
      isExpanded: isExpanded,
      containsSelection: reports.contains(widget.selectedReport),
      onToggle: onToggle,
      children: [for (final report in reports) _buildReportItem(report, 2)],
    );
  }

  Widget _buildReportsSection() {
    return _buildExpandableSection(
      icon: _reportsIcon,
      title: 'Reports',
      isExpanded: _reportsExpanded,
      containsSelection: true,
      onToggle: () => setState(() => _reportsExpanded = !_reportsExpanded),
      children: [
        _buildViewSection(
          icon: _supplierViewIcon,
          title: 'Supplier View',
          reports: _supplierViewReports,
          isExpanded: _supplierViewExpanded,
          onToggle: () =>
              setState(() => _supplierViewExpanded = !_supplierViewExpanded),
        ),
        _buildViewSection(
          icon: _seViewIcon,
          title: 'SE View',
          reports: _seViewReports,
          isExpanded: _seViewExpanded,
          onToggle: () => setState(() => _seViewExpanded = !_seViewExpanded),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.sidebarWidth,
      height: double.infinity,
      color: const Color(0xFFF3F4F6),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(widget.isCompactLayout ? 10 : 14),
              child: Row(
                children: [
                  const Icon(Icons.flash_on, color: Colors.blue, size: 24),
                  if (!widget.isCompactLayout) ...[
                    const SizedBox(width: 8),
                    Text(
                      'Sabah\nElectricity',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                        height: 1.1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _buildItem(
              icon: _rfcIcon,
              title: 'RFC',
              isActive: false,
              onTap: () => widget.onModuleSelected(AppModule.rfc),
            ),
            _buildItem(
              icon: _tenderIcon,
              title: 'Tender/Quotation',
              isActive: false,
              onTap: () => widget.onModuleSelected(AppModule.tenderQuotation),
            ),
            _buildReportsSection(),
            _buildItem(
              icon: _tocIcon,
              title: 'TOC Review',
              isActive: false,
              onTap: () => widget.onModuleSelected(AppModule.tocReview),
            ),
            const SizedBox(height: 12),
            _buildItem(
              icon: _backIcon,
              title: 'Back To Menu',
              isActive: false,
              onTap: () => widget.onModuleSelected(AppModule.mainMenu),
            ),
          ],
        ),
      ),
    );
  }
}
