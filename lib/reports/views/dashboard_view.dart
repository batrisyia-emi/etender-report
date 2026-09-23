// lib/dashboard/dashboard_view.dart
//
// Layout follows docs/supplier-portal-template.html: a four-card KPI row, then rows split
// 3fr / 2fr into tinted-header cards. The content is this app's own — every
// figure comes from the same blocs and metric helpers the three reports use,
// so the dashboard cannot drift from them.
import 'package:etender_reports/reports/bloc/erfc/erfc_bloc.dart';
import 'package:etender_reports/reports/bloc/tender_summary/tender_summary_bloc.dart';
import 'package:etender_reports/reports/bloc/vendor_participation/vendor_participation_bloc.dart';
import 'package:etender_reports/shared/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:etender_reports/reports/models/erfc_metrics.dart';
import 'package:etender_reports/reports/models/erfc_status.dart';
import 'package:etender_reports/reports/models/tender_metrics.dart';
import 'package:etender_reports/reports/models/tender_status.dart';
import 'package:etender_reports/reports/models/vendor_metrics.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_theme.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_cards.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_tabs.dart';
import 'package:etender_reports/reports/widgets/dashboard/se/se_kpi_row.dart';
import 'package:etender_reports/reports/widgets/dashboard/se/se_closing_soon_card.dart';
import 'package:etender_reports/reports/widgets/dashboard/se/se_breakdown_cards.dart';
import 'package:etender_reports/reports/widgets/dashboard/se/se_active_tenders_grid.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({
    super.key,
    required this.sectionSpacing,
    required this.fillHeight,
  });

  final double sectionSpacing;

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
  static const List<String> _tabs = ['Overview', 'Tenders', 'eRFC', 'Vendors'];

  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final tenders = context.watch<TenderSummaryBloc>().state.records;
    final rfcs = context.watch<ErfcBloc>().state.records;
    final vendors = context.watch<VendorParticipationBloc>().state.records;

    final panel = switch (_tab) {
      1 => _TendersPanel(records: tenders),
      2 => _ErfcPanel(records: rfcs),
      3 => _VendorsPanel(records: vendors),
      _ => _OverviewPanel(tenders: tenders, rfcs: rfcs, vendors: vendors),
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

/// Everything at a glance, across all three reports.
class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({
    required this.tenders,
    required this.rfcs,
    required this.vendors,
  });

  final List<Map<String, dynamic>> tenders;
  final List<Map<String, dynamic>> rfcs;
  final List<Map<String, dynamic>> vendors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SeKpiRow(tenders: tenders, rfcs: rfcs, vendors: vendors),
        const SizedBox(height: DashTheme.gap),
        DashSplitRow(
          wide: SeClosingSoonCard(records: tenders),
          narrow: SeTenderStatusCard(records: tenders),
        ),
        const SizedBox(height: DashTheme.gap),
        DashSplitRow(
          wide: SeErfcPipelineCard(records: rfcs),
          narrow: SeVendorFunnelCard(records: vendors),
        ),
      ],
    );
  }
}

/// The tender report's figures, with the closing-soon table given the room
/// the overview cannot spare.
class _TendersPanel extends StatelessWidget {
  const _TendersPanel({required this.records});

  final List<Map<String, dynamic>> records;

  @override
  Widget build(BuildContext context) {
    final counts = tenderStatusCounts(records);
    int countOf(Set<TenderStatus> group) =>
        TenderStatus.wiresOf(group)
            .fold<int>(0, (total, wire) => total + (counts[wire] ?? 0));

    final average = tenderAverageValue(records);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        DashCardGrid(
          cards: [
            DashKpiCard(
              icon: Icons.account_balance_wallet_outlined,
              accent: DashTheme.accent,
              value: formatValue(tenderTotalValue(records)),
              label: 'Total Estimated Value',
              note: average == null
                  ? null
                  : 'Avg ${formatValue(average, decimals: 0)}',
            ),
            DashKpiCard(
              icon: Icons.campaign_outlined,
              accent: DashTheme.success,
              value: formatNumber(
                countOf(TenderStatus.openForBidding),
                decimals: 0,
              ),
              label: 'Open for Bidding',
              note: '${countOf(const {TenderStatus.extended})} extended',
            ),
            DashKpiCard(
              icon: Icons.update_outlined,
              accent: DashTheme.warning,
              value: formatNumber(
                countOf(const {TenderStatus.extended}),
                decimals: 0,
              ),
              label: 'Extended',
              note: 'Deadline pushed out',
            ),
            DashKpiCard(
              icon: Icons.lock_clock_outlined,
              accent: DashTheme.muted,
              value: formatNumber(
                countOf(const {TenderStatus.closed}),
                decimals: 0,
              ),
              label: 'Closed',
              note: 'Bidding ended',
            ),
          ],
        ),
        const SizedBox(height: DashTheme.gap),
        SeActiveTendersGrid(records: records),
        const SizedBox(height: DashTheme.gap),
        DashSplitRow(
          wide: SeClosingSoonCard(records: records, limit: 10),
          narrow: SeTenderStatusCard(records: records),
        ),
      ],
    );
  }
}

/// The eRFC report's figures, with processing time broken out by division —
/// the one view the overview has no room for.
class _ErfcPanel extends StatelessWidget {
  const _ErfcPanel({required this.records});

  final List<Map<String, dynamic>> records;

  @override
  Widget build(BuildContext context) {
    int countOf(Set<ErfcStatus> group) =>
        erfcCountWithStatus(records, ErfcStatus.wiresOf(group));

    final overdue = records.where(erfcIsOverdue).length;
    final oldest = erfcOldestInFlightDays(records);
    final average = erfcAverageProcessingDays(records);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        DashCardGrid(
          cards: [
            DashKpiCard(
              icon: Icons.request_page_outlined,
              accent: DashTheme.accent,
              value: formatNumber(records.length, decimals: 0),
              label: 'Total RFCs',
              note: formatValue(erfcPipelineValue(records)),
            ),
            DashKpiCard(
              icon: Icons.autorenew,
              accent: DashTheme.info,
              value: formatNumber(countOf(ErfcStatus.inFlight), decimals: 0),
              label: 'In Progress',
              note: oldest == null
                  ? 'Nothing in flight'
                  : 'Oldest waiting $oldest days',
            ),
            DashKpiCard(
              icon: Icons.warning_amber_rounded,
              accent: overdue > 0 ? DashTheme.danger : DashTheme.muted,
              value: formatNumber(overdue, decimals: 0),
              label: 'Overdue',
              note: 'Past $kErfcOverdueDays days',
              noteColor: overdue > 0 ? DashTheme.danger : null,
            ),
            DashKpiCard(
              icon: Icons.timelapse_outlined,
              accent: DashTheme.purple,
              value: average == null
                  ? '-'
                  : '${average.toStringAsFixed(1)} days',
              label: 'Avg Processing',
              note: 'Submission to endorsement',
            ),
          ],
        ),
        const SizedBox(height: DashTheme.gap),
        DashSplitRow(
          wide: SeProcessingByDivisionCard(records: records),
          narrow: SeErfcPipelineCard(records: records),
        ),
      ],
    );
  }
}

/// The vendor report's funnel, plus the certification mix behind it.
class _VendorsPanel extends StatelessWidget {
  const _VendorsPanel({required this.records});

  final List<Map<String, dynamic>> records;

  @override
  Widget build(BuildContext context) {
    final invited = vendorInvitedCount(records);
    final submitted = vendorSubmittedCount(records);
    final late = records.where((r) => r['submissionStatus'] == 'Late').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        DashCardGrid(
          cards: [
            DashKpiCard(
              icon: Icons.groups_outlined,
              accent: DashTheme.accent,
              value: formatNumber(records.length, decimals: 0),
              label: 'Vendor Records',
            ),
            DashKpiCard(
              icon: Icons.mail_outline,
              accent: DashTheme.info,
              value: formatNumber(invited, decimals: 0),
              label: 'Invitations Sent',
              note: '${records.length - invited} not invited',
            ),
            DashKpiCard(
              icon: Icons.how_to_reg_outlined,
              accent: DashTheme.purple,
              value: formatNumber(
                vendorParticipatedCount(records),
                decimals: 0,
              ),
              label: 'Took Up the Invite',
            ),
            DashKpiCard(
              icon: Icons.inbox_outlined,
              accent: DashTheme.success,
              value: formatNumber(submitted, decimals: 0),
              label: 'Submitted a Bid',
              note: late > 0 ? '$late late' : 'None late',
              noteColor: late > 0 ? DashTheme.warning : null,
            ),
          ],
        ),
        const SizedBox(height: DashTheme.gap),
        DashSplitRow(
          wide: SeCertificationMixCard(records: records),
          narrow: SeVendorFunnelCard(records: records),
        ),
      ],
    );
  }
}

/// `.krow` — four across, dropping to two and then one as the window
/// narrows. Every tab lays its KPI cards out through this.
/// The overview's four cross-report headline figures.
/// The template's lead panel is a table, so this one is too: the tenders
/// whose closing date is still ahead, soonest first.
/// One bar per lifecycle stage, in funnel order — the same three groupings
/// the tender report's overview cards use.
/// Average days from submission to endorsement, per division. Slowest first,
/// which is the order the question is usually asked in.
/// Which certificates the vendors on this report actually hold.
/// A bar whose figure is not a count — days, here — so it carries its own
/// label rather than an "n of total".
/// The template's `.tcard-grid`: every tender still open for bidding as its
/// own card, two across. Urgency drives the 3px left border, soonest first.
/// One `.tcard`: reference and title over a two-column meta grid, with the
/// deadline along the bottom.
/// `.tc-item` x2 — an uppercase label over its value, twice across.
/// `.pill` — the small rounded label the template puts beside a card title.
/// A labelled count with a proportional bar — the template's own way of
/// showing a breakdown, and the same shape the eRFC processing panel uses.
