// lib/reports/views/supplier_dashboard_view.dart
//
// The supplier's own dashboard, laid out as docs/supplier-portal-template.html has it:
// a four-card KPI row, then the tenders closing soon beside the bid
// pipeline, then the notification feed beside the profile health panel.
//
// The template is a vendor portal, so every panel is about one signed-in
// supplier rather than the whole supplier base — ReportMockData.
// supplierProfile says which. Nothing here invents a colour or a shape:
// it wears DashTheme and the same two cards the SE dashboard is built
// from, so the two cannot drift apart.
import 'package:etender_reports/data/actions/report_actions.dart';
import 'package:etender_reports/data/mock/report_mock_data.dart';
import 'package:etender_reports/reports/bloc/tender_summary/tender_summary_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:etender_reports/reports/widgets/dashboard/dashboard_theme.dart';
import 'package:etender_reports/reports/models/supplier_dashboard_metrics.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_cards.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_tabs.dart';
import 'package:etender_reports/reports/widgets/dashboard/supplier/supplier_profile_cards.dart';
import 'package:etender_reports/reports/widgets/dashboard/supplier/supplier_tenders_card.dart';
import 'package:etender_reports/reports/widgets/dashboard/supplier/supplier_bids_cards.dart';
import 'package:etender_reports/reports/widgets/dashboard/supplier/supplier_documents_cards.dart';
import 'package:etender_reports/reports/widgets/dashboard/supplier/supplier_notifications_card.dart';

class SupplierDashboardView extends StatefulWidget {
  const SupplierDashboardView({
    super.key,
    required this.sectionSpacing,
    required this.fillHeight,
  });

  final double sectionSpacing;

  /// When true the tab strip stays put and only the panel scrolls. Below
  /// that height the whole page scrolls instead.
  final bool fillHeight;

  @override
  State<SupplierDashboardView> createState() => _SupplierDashboardViewState();
}

class _SupplierDashboardViewState extends State<SupplierDashboardView> {
  /// The template's `.stabs`, minus the counts it paints into the labels —
  /// those are already on the KPI cards. Same job as the SE dashboard's
  /// strip: narrow the page to one part of the portal.
  static const List<String> _tabs = [
    'Overview',
    'Tenders & Quotations',
    'My Bids & Quotations',
    'Profile',
    'Documents',
  ];

  int _tab = 0;

  /// Notifications the supplier has cleared with "Mark all read". The feed
  /// itself is const mock data, so the read flag has to live here.
  final Set<int> _readNotifications = <int>{};

  /// The expiry banner on the Documents tab, until it is dismissed.
  bool _expiryAlertDismissed = false;

  void _openTab(int index) => setState(() => _tab = index);

  @override
  Widget build(BuildContext context) {
    // What is out there to bid on is the tender report's data, same as the
    // SE dashboard reads it; everything else belongs to the supplier.
    final tenders = context.watch<TenderSummaryBloc>().state.records;

    final profile = ReportMockData.supplierProfile;
    final bids = ReportMockData.supplierBidPipeline;
    final documents = ReportMockData.supplierDocuments;
    final notifications = ReportMockData.supplierNotifications;

    final categories = {
      for (final category in (profile['categories'] as List))
        category.toString(),
    };
    final now = DateTime.now();

    final panel = switch (_tab) {
      1 => _TendersPanel(
        tenders: tenders,
        categories: categories,
        now: now,
        onBidNow: context.read<ReportActions>().openTenderForBidding,
        onViewTender: context.read<ReportActions>().viewTender,
      ),
      2 => _BidsPanel(bids: bids),
      3 => _ProfilePanel(
        profile: profile,
        certificates: documents,
        categories: categories,
        now: now,
      ),
      4 => _DocumentsPanel(
        documents: documents,
        now: now,
        alertDismissed: _expiryAlertDismissed,
        onDismissAlert: () => setState(() => _expiryAlertDismissed = true),
      ),
      _ => _OverviewPanel(
        profile: profile,
        bids: bids,
        certificates: documents,
        notifications: notifications,
        readNotifications: _readNotifications,
        tenders: tenders,
        categories: categories,
        now: now,
        onOpenTenders: () => _openTab(1),
        onBidNow: context.read<ReportActions>().openTenderForBidding,
        onViewTender: context.read<ReportActions>().viewTender,
        onOpenBids: () => _openTab(2),
        onOpenDocuments: () => _openTab(4),
        onMarkAllRead: () => setState(() {
          _readNotifications.addAll(
            List<int>.generate(notifications.length, (i) => i),
          );
        }),
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

/// The template's dashboard tab: the badge, the KPI row, then its two
/// split rows.
class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({
    required this.profile,
    required this.bids,
    required this.certificates,
    required this.notifications,
    required this.readNotifications,
    required this.tenders,
    required this.categories,
    required this.now,
    required this.onOpenTenders,
    required this.onBidNow,
    required this.onViewTender,
    required this.onOpenBids,
    required this.onOpenDocuments,
    required this.onMarkAllRead,
  });

  final Map<String, dynamic> profile;
  final List<Map<String, dynamic>> bids;
  final List<Map<String, dynamic>> certificates;
  final List<Map<String, dynamic>> notifications;
  final Set<int> readNotifications;
  final List<Map<String, dynamic>> tenders;
  final Set<String> categories;
  final DateTime now;

  /// Each card's header button hands the page over to the tab that holds
  /// the full list, the way the template's "View All" does.
  final VoidCallback onOpenTenders;

  /// Both leave this module for the bidding screen, which belongs to
  /// another part of the system.
  final ValueChanged<String> onBidNow;
  final ValueChanged<String> onViewTender;

  final VoidCallback onOpenBids;
  final VoidCallback onOpenDocuments;
  final VoidCallback onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SupplierVendorBadge(profile: profile, categories: categories),
        const SizedBox(height: DashTheme.gap),
        SupplierKpiRow(
          profile: profile,
          bids: bids,
          certificates: certificates,
          tenders: tenders,
          categories: categories,
          now: now,
        ),
        const SizedBox(height: DashTheme.gap),
        DashSplitRow(
          wide: SupplierMatchingTendersCard(
            tenders: tenders,
            categories: categories,
            now: now,
            onViewAll: onOpenTenders,
            onBidNow: onBidNow,
            onViewTender: onViewTender,
          ),
          narrow: SupplierBidPipelineCard(bids: bids, onViewAll: onOpenBids),
        ),
        const SizedBox(height: DashTheme.gap),
        DashSplitRow(
          wide: SupplierNotificationsCard(
            notifications: notifications,
            readNotifications: readNotifications,
            onMarkAllRead: onMarkAllRead,
          ),
          narrow: SupplierProfileHealthCard(
            profile: profile,
            certificates: certificates,
            now: now,
            onViewDocuments: onOpenDocuments,
          ),
        ),
      ],
    );
  }
}

/// `.stab` Active Tenders: the supplier's own categories in full, then
/// whatever else is open below them.
class _TendersPanel extends StatelessWidget {
  const _TendersPanel({
    required this.tenders,
    required this.categories,
    required this.now,
    required this.onBidNow,
    required this.onViewTender,
  });

  final List<Map<String, dynamic>> tenders;
  final Set<String> categories;
  final DateTime now;
  final ValueChanged<String> onBidNow;
  final ValueChanged<String> onViewTender;

  @override
  Widget build(BuildContext context) {
    final other = supplierOpenTenders(tenders, now)
        .where((t) => !categories.contains(t['tenderCategory']?.toString()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SupplierMatchingTendersCard(
          tenders: tenders,
          categories: categories,
          now: now,
          limit: 50,
          onBidNow: onBidNow,
          onViewTender: onViewTender,
        ),
        const SizedBox(height: DashTheme.gap),
        DashCard(
          icon: Icons.travel_explore_outlined,
          title: 'Other Open Tenders',
          subtitle: 'Outside your registered categories',
          padded: false,
          child: other.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 24),
                  child: Text(
                    'Nothing else is open right now.',
                    style: TextStyle(fontSize: 12, color: DashTheme.muted),
                  ),
                )
              : Column(
                  children: [
                    const SupplierMatchingHeaderRow(withAction: true),
                    for (final record in other)
                      SupplierMatchingRow(
                        record: record,
                        daysLeft: DateTime.parse(
                          record['closingDate'].toString(),
                        ).difference(now).inDays,
                        onBidNow: onBidNow,
                        onViewTender: onViewTender,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// `.stab` My Bids & Quotations: the pipeline, then every bid behind it.
class _BidsPanel extends StatelessWidget {
  const _BidsPanel({required this.bids});

  final List<Map<String, dynamic>> bids;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SupplierBidPipelineCard(bids: bids),
        const SizedBox(height: DashTheme.gap),
        SupplierBidsTableCard(bids: bids),
      ],
    );
  }
}

/// `.stab` Profile & Registration.
class _ProfilePanel extends StatelessWidget {
  const _ProfilePanel({
    required this.profile,
    required this.certificates,
    required this.categories,
    required this.now,
  });

  final Map<String, dynamic> profile;
  final List<Map<String, dynamic>> certificates;
  final Set<String> categories;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SupplierVendorBadge(profile: profile, categories: categories),
        const SizedBox(height: DashTheme.gap),
        SupplierProfileHealthCard(
          profile: profile,
          certificates: certificates,
          now: now,
        ),
      ],
    );
  }
}

/// `.stab` Documents: the expiry banner, the mandatory list, and the two
/// summary cards beside it.
class _DocumentsPanel extends StatelessWidget {
  const _DocumentsPanel({
    required this.documents,
    required this.now,
    required this.alertDismissed,
    required this.onDismissAlert,
  });

  final List<Map<String, dynamic>> documents;
  final DateTime now;
  final bool alertDismissed;
  final VoidCallback onDismissAlert;

  @override
  Widget build(BuildContext context) {
    final needRenewal = supplierDocumentsNeedingRenewal(documents, now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (needRenewal.isNotEmpty && !alertDismissed) ...[
          SupplierExpiryBanner(
            documents: needRenewal,
            now: now,
            onDismiss: onDismissAlert,
          ),
          const SizedBox(height: DashTheme.gap),
        ],
        DashSplitRow(
          wide: SupplierMandatoryDocumentsCard(
            documents: documents,
            now: now,
            onUploadNew: context.read<ReportActions>().uploadNewDocument,
            onUpload: context.read<ReportActions>().uploadRequiredDocument,
            onRenew: context.read<ReportActions>().renewDocument,
          ),
          narrow: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SupplierCompletenessCard(documents: documents, now: now),
              const SizedBox(height: DashTheme.gap),
              SupplierRecentUploadsCard(documents: documents),
            ],
          ),
        ),
      ],
    );
  }
}

/// The template's red strip above the list. It states the count, then
/// names the documents behind it so the banner is actionable on its own.
/// `.doc-item` list: a file-type square, the name, what was uploaded and
/// when it lapses, then the status and whatever action it needs.
/// The template's completeness card: the ratio, then one line per state.
/// `.card` Recent Uploads: what was filed, and when.
/// The template's `.vendor-badge`: who the portal thinks you are. Without
/// it every "your" on the page is unattributed.
/// `.krow` — open tenders, bids in flight, documents about to lapse and the
/// performance score.
/// The template's lead panel: what is still open in the categories this
/// supplier is registered for, soonest closing first.
/// `.card` "Bid Pipeline": one bar per outcome, then the win rate the
/// template puts under its separator.
/// Every bid the supplier has filed, newest first, with what became of it.
/// `.notif-item` list: a coloured dot, the message, and when it landed.
/// `.score-wrap` plus `.score-items`: the headline score, then the criteria
/// behind it, then anything on file that needs renewing.
/// A labelled bar with its own value text — the criteria panel shows a
/// percentage where the pipeline shows a count, so the caller supplies it.
/// The template's `.btn`: `.btn-o` outlined by default, `.btn-p` filled
/// for the one action it wants you to take. Sized to sit inside a card
/// header without stretching it.
