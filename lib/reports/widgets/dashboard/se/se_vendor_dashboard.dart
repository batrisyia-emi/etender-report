// lib/reports/widgets/dashboard/se/se_vendor_dashboard.dart
//
// The Vendors tab (SE view): overview status, the participation flow from
// invitation to submission, the certificate mix and the funnel.
import 'package:etender_reports/reports/widgets/dashboard/dashboard_cards.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_period.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_theme.dart';
import 'package:etender_reports/reports/widgets/dashboard/se/se_breakdown_cards.dart';
import 'package:etender_reports/reports/widgets/dashboard/se/se_tender_dashboard.dart';
import 'package:etender_reports/reports/widgets/dashboard/se/se_toc_opening_dashboard.dart';
import 'package:flutter/material.dart';

class SeVendorDashboard extends StatefulWidget {
  const SeVendorDashboard({
    super.key,
    required this.vendors,
    required this.tenders,
  });

  /// One row per supplier invited to a tender.
  final List<Map<String, dynamic>> vendors;

  /// Vendor rows carry no date of their own, so the period follows the
  /// closing date of the tender they were invited to.
  final List<Map<String, dynamic>> tenders;

  @override
  State<SeVendorDashboard> createState() => _SeVendorDashboardState();
}

class _SeVendorDashboardState extends State<SeVendorDashboard> {
  DashPeriod _period = DashPeriod.thisMonth;

  @override
  Widget build(BuildContext context) {
    final range = _period.describe();

    final tenderNos = {
      for (final t in widget.tenders)
        if (DateTime.tryParse(t['closingDate']?.toString() ?? '')
            case final closing?)
          if (_period.contains(closing)) t['tenderNo'],
    };
    final records = widget.vendors
        .where((r) => tenderNos.contains(r['tenderNo']))
        .toList();
    final total = records.length;

    int count(bool Function(Map<String, dynamic>) test) =>
        records.where(test).length;
    final invited = count((r) => r['invitationStatus'] == 'Sent');
    final participated = count(
      (r) => r['participationStatus'] == 'Participated',
    );
    final declined = count((r) => r['participationStatus'] == 'Rejected');
    final purchased = count((r) => r['documentPurchased'] == true);
    final onTime = count((r) => r['submissionStatus'] == 'Submitted');
    final late = count((r) => r['submissionStatus'] == 'Late');
    final notSubmitted = count((r) => r['submissionStatus'] == 'Not Submitted');

    final steps = [
      SeFlowStep(
        step: 'Step 1',
        flow: 'Invitation',
        title: 'Invitation Sent',
        big: invited,
        note: '${total - invited} not invited',
      ),
      SeFlowStep(
        step: 'Step 2',
        flow: 'Response',
        title: 'Participation',
        lines: [
          ('Participated', participated, DashTheme.success),
          ('Declined', declined, DashTheme.danger),
        ],
        footer: '${invited - participated - declined} pending at this stage',
      ),
      SeFlowStep(
        step: 'Step 3',
        flow: 'Purchase',
        title: 'Document Purchased',
        big: purchased,
        note: 'of $participated participated vendors',
      ),
      SeFlowStep(
        step: 'Step 4',
        flow: 'Submission',
        title: 'Bid Submission',
        lines: [
          ('Submitted', onTime, DashTheme.success),
          ('Late', late, DashTheme.warning),
          ('Not Submitted', notSubmitted, DashTheme.danger),
        ],
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        DashPeriodSelector(
          selected: _period,
          onChanged: (period) => setState(() => _period = period),
        ),
        const SizedBox(height: 20),
        SeSectionHeading(
          title: 'Vendor Overview Status',
          metadata: 'SE view · $total vendor records · $range',
        ),
        const SizedBox(height: 12),
        SeOverviewMetricGrid(
          cards: [
            SeOverviewMetric(
              label: 'Vendor Records',
              value: total,
              total: total,
              subtext: 'Vendor-tender pairings in the period',
              accent: DashTheme.accent,
              icon: Icons.groups_outlined,
            ),
            SeOverviewMetric(
              label: 'Invitations Sent',
              value: invited,
              total: total,
              subtext: 'Vendors invited to bid',
              accent: DashTheme.info,
              icon: Icons.mail_outline,
            ),
            SeOverviewMetric(
              label: 'Took Up the Invite',
              value: participated,
              total: total,
              subtext: 'Vendors that chose to participate',
              accent: DashTheme.purple,
              icon: Icons.how_to_reg_outlined,
            ),
            SeOverviewMetric(
              label: 'Document Purchased',
              value: purchased,
              total: total,
              subtext: 'Tender documents bought',
              accent: DashTheme.warning,
              icon: Icons.receipt_long_outlined,
            ),
            SeOverviewMetric(
              label: 'Submitted a Bid',
              value: onTime + late,
              total: total,
              subtext: late > 0 ? '$late of them late' : 'None submitted late',
              accent: DashTheme.success,
              icon: Icons.inbox_outlined,
            ),
          ],
        ),
        const SizedBox(height: DashTheme.gap),
        seSection(
          title: 'Vendor Participation Flow',
          metadata: 'SE view · $total vendor records · $range',
          icon: Icons.account_tree_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: Alignment.centerRight,
                child: SeFlowLegend(),
              ),
              const SizedBox(height: 12),
              SeFlowRow(steps: steps),
            ],
          ),
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
