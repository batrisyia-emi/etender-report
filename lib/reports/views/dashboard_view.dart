// lib/dashboard/dashboard_view.dart
//
// Layout follows docs/supplier-portal-template.html: a four-card KPI row, then rows split
// 3fr / 2fr into tinted-header cards. The content is this app's own — every
// figure comes from the same blocs and metric helpers the three reports use,
// so the dashboard cannot drift from them.
import 'package:etender_reports/reports/bloc/erfc/erfc_bloc.dart';
import 'package:etender_reports/reports/bloc/tender_security/tender_security_bloc.dart';
import 'package:etender_reports/reports/bloc/tender_summary/tender_summary_bloc.dart';
import 'package:etender_reports/reports/bloc/toc/toc_bloc.dart';
import 'package:etender_reports/reports/bloc/vendor_participation/vendor_participation_bloc.dart';
import 'package:etender_reports/reports/bloc/vtm_monitoring/vtm_monitoring_bloc.dart';
import 'package:etender_reports/reports/models/metrics/erfc_metrics.dart';
import 'package:etender_reports/reports/models/metrics/tender_metrics.dart';
import 'package:etender_reports/reports/models/metrics/tender_security_metrics.dart';
import 'package:etender_reports/reports/models/metrics/toc_metrics.dart';
import 'package:etender_reports/reports/models/metrics/vendor_metrics.dart';
import 'package:etender_reports/reports/models/metrics/vtm_monitoring_metrics.dart';
import 'package:etender_reports/reports/models/records/tender_security_record.dart';
import 'package:etender_reports/reports/models/records/toc_opening_record.dart';
import 'package:etender_reports/reports/models/records/vtm_monitoring_record.dart';
import 'package:etender_reports/reports/models/status/erfc_status.dart';
import 'package:etender_reports/reports/models/status/tender_status.dart';
import 'package:etender_reports/reports/models/status/toc_status.dart';
import 'package:etender_reports/reports/models/status/vtm_monitoring_status.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_cards.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_tabs.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_theme.dart';
import 'package:etender_reports/reports/widgets/dashboard/se/se_active_tenders_grid.dart';
import 'package:etender_reports/reports/widgets/dashboard/se/se_breakdown_cards.dart';
import 'package:etender_reports/reports/widgets/dashboard/se/se_closing_soon_card.dart';
import 'package:etender_reports/reports/widgets/dashboard/se/se_kpi_row.dart';
import 'package:etender_reports/reports/widgets/dashboard/se/se_process_cards.dart';
import 'package:etender_reports/shared/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  static const List<String> _tabs = [
    'Overview',
    'Tenders',
    'eRFC',
    'Vendors',
    'TOC & Opening',
    'Tender Security',
    'VTM Monitoring',
  ];

  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final tenders = context.watch<TenderSummaryBloc>().state.records;
    final rfcs = context.watch<ErfcBloc>().state.records;
    final vendors = context.watch<VendorParticipationBloc>().state.records;
    // The securities hang off the tender report rather than their own tab:
    // they are money held against these tenders, not a separate subject.
    final securities = context.watch<TenderSecurityBloc>().state.records;
    final openings = context.watch<TocBloc>().state.records;
    final appendixF = context.watch<VtmMonitoringBloc>().state.records;

    final panel = switch (_tab) {
      1 => _TendersPanel(records: tenders, securities: securities),
      2 => _ErfcPanel(records: rfcs),
      3 => _VendorsPanel(records: vendors),
      4 => _TocPanel(records: openings),
      5 => _TenderSecurityPanel(records: securities),
      6 => _VtmPanel(records: appendixF),
      _ => _OverviewPanel(
        tenders: tenders,
        rfcs: rfcs,
        vendors: vendors,
        openings: openings,
        appendixF: appendixF,
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

/// Everything at a glance, across all three reports.
class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({
    required this.tenders,
    required this.rfcs,
    required this.vendors,
    required this.openings,
    required this.appendixF,
  });

  final List<Map<String, dynamic>> tenders;
  final List<Map<String, dynamic>> rfcs;
  final List<Map<String, dynamic>> vendors;
  final List<TocOpeningRecord> openings;
  final List<VtmMonitoringRecord> appendixF;

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
        const SizedBox(height: DashTheme.gap),
        // The two process reports get a row rather than headline cards: the
        // top row stays at four, which is what the grid lays out evenly.
        // Their own tabs carry the detail.
        DashSplitRow(
          wide: SeVtmPipelineCard(records: appendixF),
          narrow: SeTocProgressCard(records: openings),
        ),
      ],
    );
  }
}

/// The tender report's figures, with the closing-soon table given the room
/// the overview cannot spare.
class _TendersPanel extends StatelessWidget {
  const _TendersPanel({required this.records, this.securities = const []});

  final List<Map<String, dynamic>> records;

  /// From the tender security dataset, so the tender filters do not reach
  /// it — see the same caveat on the VTM Monitoring card.
  final List<TenderSecurityRecord> securities;

  @override
  Widget build(BuildContext context) {
    final counts = tenderStatusCounts(records);
    int countOf(Set<TenderStatus> group) =>
        TenderStatus.wiresOf(group)
            .fold<int>(0, (total, wire) => total + (counts[wire] ?? 0));

    final average = tenderAverageValue(records);

    // Lodged less refunded: what SESB is still holding for tenderers.
    final outstandingSecurity = tenderSecurityHeld(securities);
    final securitiesHeld = securities
        .where((record) => !tenderSecurityIsRefunded(record))
        .length;

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
            DashKpiCard(
              icon: Icons.task_alt,
              accent: DashTheme.info,
              value: formatNumber(
                countOf(const {TenderStatus.completed}),
                decimals: 0,
              ),
              label: 'Completed',
              note: 'Process concluded',
            ),
            DashKpiCard(
              icon: Icons.savings_outlined,
              accent: DashTheme.purple,
              // A dash, not RM 0: nothing held and nothing read are
              // different statements.
              value: securities.isEmpty
                  ? '-'
                  : formatValue(outstandingSecurity),
              label: 'Outstanding Tender Security',
              note: securities.isEmpty
                  ? 'No tender security data'
                  : '$securitiesHeld held, across all tenders',
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

/// The opening committees: where each tender stands and who carries the load.
///
/// Counts and dates only. No figure on this page comes from a bid — see the
/// warning on [TocOpeningRecord].
class _TocPanel extends StatelessWidget {
  const _TocPanel({required this.records});

  final List<TocOpeningRecord> records;

  @override
  Widget build(BuildContext context) {
    final awaiting = tocCountWithStatus(records, TocStatus.open);
    final completed = tocCountWithStatus(records, TocStatus.openingCompleted);
    final flags = tocExceptionFlags(records);
    final urgent = flags
        .where((flag) => flag.severity == TocFlagSeverity.high)
        .length;
    final average = tocAverageAging(records);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        DashCardGrid(
          cards: [
            DashKpiCard(
              icon: Icons.gavel_outlined,
              accent: DashTheme.accent,
              value: formatNumber(records.length, decimals: 0),
              label: 'Openings',
              note: '$completed completed',
            ),
            DashKpiCard(
              icon: Icons.person_add_alt,
              accent: awaiting > 0 ? DashTheme.warning : DashTheme.muted,
              value: formatNumber(awaiting, decimals: 0),
              label: 'Awaiting Committee',
              note: awaiting > 0 ? 'Nobody appointed yet' : 'All appointed',
              noteColor: awaiting > 0 ? DashTheme.warning : null,
            ),
            DashKpiCard(
              icon: Icons.warning_amber_rounded,
              accent: flags.isEmpty ? DashTheme.muted : DashTheme.danger,
              value: formatNumber(flags.length, decimals: 0),
              label: 'Needs Attention',
              note: flags.isEmpty ? 'Nothing outstanding' : '$urgent urgent',
              noteColor: urgent > 0 ? DashTheme.danger : null,
            ),
            DashKpiCard(
              icon: Icons.timelapse_outlined,
              accent: DashTheme.purple,
              value: average == null
                  ? '-'
                  : '${average.toStringAsFixed(1)} days',
              label: 'Avg Days to Close Out',
              note: 'Closing to Appendix P',
            ),
          ],
        ),
        const SizedBox(height: DashTheme.gap),
        DashSplitRow(
          wide: SeTocProgressCard(records: records),
          narrow: SeTocWorkloadCard(records: records),
        ),
      ],
    );
  }
}

/// The securities on file: what is held, what has lapsed, what is owed back.
class _TenderSecurityPanel extends StatelessWidget {
  const _TenderSecurityPanel({required this.records});

  final List<TenderSecurityRecord> records;

  @override
  Widget build(BuildContext context) {
    final expired = tenderSecurityExpiredCount(records);
    final expiringSoon = tenderSecurityExpiringSoonCount(records);
    final pendingRefund = tenderSecurityPendingRefundCount(records);
    final held = records.where((r) => !tenderSecurityIsRefunded(r)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        DashCardGrid(
          cards: [
            DashKpiCard(
              icon: Icons.savings_outlined,
              accent: DashTheme.accent,
              // A dash, not RM 0: nothing held and nothing read are
              // different statements.
              value: records.isEmpty
                  ? '-'
                  : formatValue(tenderSecurityHeld(records)),
              label: 'Outstanding Tender Security',
              note: records.isEmpty ? 'No data' : '$held still held',
            ),
            DashKpiCard(
              icon: Icons.schedule_outlined,
              accent: expiringSoon > 0 ? DashTheme.warning : DashTheme.muted,
              value: formatNumber(expiringSoon, decimals: 0),
              label: 'Expiring Soon',
              note: 'Within $kTenderSecurityExpiringSoonDays days',
              noteColor: expiringSoon > 0 ? DashTheme.warning : null,
            ),
            DashKpiCard(
              icon: Icons.report_gmailerrorred_outlined,
              accent: expired > 0 ? DashTheme.danger : DashTheme.muted,
              value: formatNumber(expired, decimals: 0),
              label: 'Expired, Still Held',
              // The state the report exists to surface: a lapsed instrument
              // on file secures nothing.
              note: expired > 0 ? 'Securing nothing' : 'None lapsed',
              noteColor: expired > 0 ? DashTheme.danger : null,
            ),
            DashKpiCard(
              icon: Icons.assignment_return_outlined,
              accent: pendingRefund > 0 ? DashTheme.info : DashTheme.muted,
              value: formatNumber(pendingRefund, decimals: 0),
              label: 'Pending Refund',
              note: 'Unsuccessful, not yet returned',
            ),
          ],
        ),
        const SizedBox(height: DashTheme.gap),
        DashSplitRow(
          wide: SeSecurityStatusCard(records: records),
          narrow: SeSecurityHandoverCard(records: records),
        ),
      ],
    );
  }
}

/// VTM's own pipeline: Appendix F from preparation to floating.
class _VtmPanel extends StatelessWidget {
  const _VtmPanel({required this.records});

  final List<VtmMonitoringRecord> records;

  @override
  Widget build(BuildContext context) {
    final inProgress = vtmInProgressCount(records);
    final rejected = vtmRejectedCount(records);
    final awaitingFloat = vtmCountWithStatus(
      records,
      VtmStatus.approvedByManager,
    );
    final slow = vtmSlowCount(records);
    final published = vtmPublishedCount(records);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        DashCardGrid(
          cards: [
            DashKpiCard(
              icon: Icons.description_outlined,
              accent: DashTheme.accent,
              value: formatNumber(records.length, decimals: 0),
              label: 'Appendix F Documents',
              note: '$published floated',
            ),
            DashKpiCard(
              icon: Icons.autorenew,
              accent: inProgress > 0 ? DashTheme.info : DashTheme.muted,
              value: formatNumber(inProgress, decimals: 0),
              label: 'In Progress',
              note: 'Moving through preparation',
            ),
            DashKpiCard(
              icon: Icons.assignment_return_outlined,
              accent: rejected > 0 ? DashTheme.danger : DashTheme.muted,
              value: formatNumber(rejected, decimals: 0),
              label: 'Sent Back',
              note: rejected > 0
                  ? 'With the preparer to correct'
                  : 'Nothing sent back',
              noteColor: rejected > 0 ? DashTheme.danger : null,
            ),
            DashKpiCard(
              icon: Icons.outbox_outlined,
              accent: awaitingFloat > 0 ? DashTheme.warning : DashTheme.muted,
              value: formatNumber(awaitingFloat, decimals: 0),
              label: 'Awaiting Float',
              note: slow > 0
                  ? '$slow sitting over $kVtmSlowDays days'
                  : 'Approved, one step from suppliers',
              noteColor: slow > 0 ? DashTheme.danger : null,
            ),
          ],
        ),
        const SizedBox(height: DashTheme.gap),
        DashSplitRow(
          wide: SeVtmPipelineCard(records: records),
          narrow: SeVtmAttentionCard(records: records),
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
