// lib/dashboard/dashboard_view.dart
//
// Layout follows docs/supplier-portal-template.html: a four-card KPI row, then rows split
// 3fr / 2fr into tinted-header cards. The content is this app's own — every
// figure comes from the same blocs and metric helpers the three reports use,
// so the dashboard cannot drift from them.
import 'package:etender_reports/reports/bloc/erfc/erfc_bloc.dart';
import 'package:etender_reports/reports/bloc/tender_summary/tender_summary_bloc.dart';
import 'package:etender_reports/reports/bloc/toc/toc_bloc.dart';
import 'package:etender_reports/reports/bloc/vendor_participation/vendor_participation_bloc.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_tabs.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_theme.dart';
import 'package:etender_reports/reports/widgets/dashboard/se/se_overview_dashboard.dart';
import 'package:etender_reports/reports/widgets/dashboard/se/se_rfc_dashboard.dart';
import 'package:etender_reports/reports/widgets/dashboard/se/se_tender_dashboard.dart';
import 'package:etender_reports/reports/widgets/dashboard/se/se_toc_opening_dashboard.dart';
import 'package:etender_reports/reports/widgets/dashboard/se/se_vendor_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key, required this.fillHeight});

  /// When true the tab strip stays put and only the panel scrolls. Below
  /// that height the whole page scrolls instead.
  final bool fillHeight;

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  /// The template's `.stabs` slice the page rather than the app: the sidebar
  /// already navigates between reports, so these narrow the same dashboard
  /// to one report's figures instead of duplicating that navigation.
  static const List<String> _tabs = [
    'Overview',
    'Tenders',
    'eRFC',
    'Vendors',
    'TOC & Opening',
  ];

  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final tenders = context.watch<TenderSummaryBloc>().state.records;
    final rfcs = context.watch<ErfcBloc>().state.records;
    final vendors = context.watch<VendorParticipationBloc>().state.records;
    final openings = context.watch<TocBloc>().state.records;

    final panel = switch (_tab) {
      1 => SeTenderDashboard(tenders: tenders, vendors: vendors),
      2 => SeRfcDashboard(records: rfcs),
      3 => SeVendorDashboard(vendors: vendors, tenders: tenders),
      4 => SeTocOpeningDashboard(records: openings),
      _ => SeOverviewDashboard(
        tenders: tenders,
        rfcs: rfcs,
        onNavigate: (index) => setState(() => _tab = index),
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: widget.fillHeight ? MainAxisSize.max : MainAxisSize.min,
      children: [
        DashTabs(
          labels: _tabs,
          selectedIndex: _tab,
          onSelected: (index) => setState(() => _tab = index),
        ),
        const SizedBox(height: 20),
        if (widget.fillHeight)
          Expanded(
            child: SingleChildScrollView(
              // The always-visible thumb is painted over the content, so
              // without this the right-hand column loses its border to it.
              padding: const EdgeInsets.only(right: kDashScrollbarGutter),
              child: panel,
            ),
          )
        else
          panel,
      ],
    );
  }
}
