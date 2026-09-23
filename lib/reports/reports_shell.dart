// lib/reports/reports_shell.dart
import 'package:etender_reports/data/actions/report_actions.dart';
import 'package:etender_reports/data/actions/unimplemented_report_actions.dart';
import 'package:etender_reports/data/repositories/mock_report_repository.dart';
import 'package:etender_reports/data/repositories/report_repository.dart';
import 'package:etender_reports/reports/views/dashboard_view.dart';
import 'package:etender_reports/reports/views/supplier_dashboard_view.dart';
import 'package:etender_reports/reports/bloc/erfc/erfc_bloc.dart';
import 'package:etender_reports/reports/bloc/supplier/supplier_bloc.dart';
import 'package:etender_reports/reports/bloc/tender_summary/tender_summary_bloc.dart';
import 'package:etender_reports/reports/bloc/vendor_participation/vendor_participation_bloc.dart';
import 'package:etender_reports/shared/widgets/sidebar_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:etender_reports/reports/bloc/report_selection_cubit.dart';

import 'package:etender_reports/reports/report_type.dart';
import 'package:etender_reports/reports/views/erfc_report_view.dart';
import 'package:etender_reports/reports/views/supplier_report_view.dart';
import 'package:etender_reports/reports/views/tender_summary_view.dart';
import 'package:etender_reports/reports/views/vendor_participation_view.dart';

/// Provides the selection cubit and one bloc per report. Use this as the
/// route/home widget.
class ReportsPage extends StatelessWidget {
  /// Swap in [ApiReportRepository] to run against a real backend; no
  /// widget below here changes.
  const ReportsPage({
    super.key,
    this.repository = const MockReportRepository(),
    this.actions = const UnimplementedReportActions(),
  });

  final ReportRepository repository;

  /// What the buttons do. The default throws, so an unwired button says so
  /// rather than appearing to work.
  final ReportActions actions;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ReportSelectionCubit()),
        BlocProvider(
          create: (_) =>
              TenderSummaryBloc(repository: repository)
                ..add(const TenderDataRequested()),
        ),
        BlocProvider(
          create: (_) =>
              VendorParticipationBloc(repository: repository)
                ..add(const VendorDataRequested()),
        ),

        BlocProvider(
          create: (_) =>
              SupplierBloc(repository: repository)
                ..add(const SupplierDataRequested()),
        ),

        BlocProvider(
          create: (_) =>
              ErfcBloc(repository: repository)..add(const ErfcDataRequested()),
        ),
      ],
      // Read with context.read<ReportActions>() wherever a button needs
      // it, the same way the blocs are reached.
      child: RepositoryProvider<ReportActions>.value(
        value: actions,
        child: const ReportsShell(),
      ),
    );
  }
}

/// Sidebar, page title and whichever report is selected. Each view owns its
/// own loading and error handling, so this holds nothing but layout.
class ReportsShell extends StatelessWidget {
  const ReportsShell({super.key});

  /// Every report pins its page and scrolls only its table. Below this
  /// height there is not enough room for even a minimal table, so the page
  /// falls back to scrolling rather than clipping. Both the filter panel and
  /// the overview collapse, so the fallback should rarely be hit.
  static const double _fixedLayoutMinHeight = 460;

  Widget _buildBody(
    ReportType reportType, {
    required double spacing,
    required bool fillHeight,
  }) {
    return switch (reportType) {
      ReportType.seDashboard => DashboardView(
        sectionSpacing: spacing,
        fillHeight: fillHeight,
      ),
      ReportType.supplierDashboard => SupplierDashboardView(
        sectionSpacing: spacing,
        fillHeight: fillHeight,
      ),
      ReportType.tenderSummary => TenderSummaryView(
        sectionSpacing: spacing,
        fillHeight: fillHeight,
      ),
      ReportType.vendorParticipation => VendorParticipationView(
        sectionSpacing: spacing,
        fillHeight: fillHeight,
      ),
      ReportType.supplier => SupplierReportView(
        sectionSpacing: spacing,
        fillHeight: fillHeight,
      ),
      ReportType.erfc => ErfcReportView(
        sectionSpacing: spacing,
        fillHeight: fillHeight,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final selectedReport = context.watch<ReportSelectionCubit>().state;

    // The page is laid out at the window's own size: text keeps the size
    // it was designed at, and the grids below reflow to whatever width
    // there is rather than the page being scaled to fit.
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isCompactLayout = screenWidth < 900;
        final sidebarWidth = isCompactLayout ? 72.0 : 208.0;
        final contentPadding = screenWidth < 600 ? 12.0 : 16.0;
        final sectionSpacing = screenWidth < 600 ? 12.0 : 16.0;
        final pageTitleSize = screenWidth < 600 ? 16.0 : 19.0;

        final fillHeight = constraints.maxHeight >= _fixedLayoutMinHeight;

        final body = _buildBody(
          selectedReport,
          spacing: sectionSpacing,
          fillHeight: fillHeight,
        );

        final page = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: fillHeight ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Text(
              selectedReport.pageTitle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: pageTitleSize,
                color: Colors.blue.shade900,
              ),
            ),
            SizedBox(height: sectionSpacing),
            if (fillHeight) Expanded(child: body) else body,
          ],
        );

        // Without stretch, Row centres its children vertically and a
        // short report floats to the middle of the window.
        final canvas = Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SidebarNav(
              sidebarWidth: sidebarWidth,
              isCompactLayout: isCompactLayout,
              selectedReport: selectedReport,
              onReportSelected: (report) =>
                  context.read<ReportSelectionCubit>().select(report),
              onModuleSelected: context.read<ReportActions>().openModule,
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(contentPadding),
                child: fillHeight ? page : SingleChildScrollView(child: page),
              ),
            ),
          ],
        );

        return Scaffold(
          backgroundColor: const Color(0xFFEBF1F6),
          body: SafeArea(child: canvas),
        );
      },
    );
  }
}
