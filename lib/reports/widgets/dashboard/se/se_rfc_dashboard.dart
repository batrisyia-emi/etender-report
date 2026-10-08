// lib/reports/widgets/dashboard/se/se_rfc_dashboard.dart
//
// The RFC tab (SE view): overview status, the approval flow gate by gate,
// processing time by division and the lifecycle for the current month.
import 'package:etender_reports/reports/models/status/erfc_status.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_cards.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_period.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_theme.dart';
import 'package:etender_reports/reports/widgets/dashboard/se/se_breakdown_cards.dart';
import 'package:etender_reports/reports/widgets/dashboard/se/se_tender_dashboard.dart';
import 'package:etender_reports/reports/widgets/dashboard/se/se_toc_opening_dashboard.dart';
import 'package:flutter/material.dart';

class SeRfcDashboard extends StatefulWidget {
  const SeRfcDashboard({super.key, required this.records});

  final List<Map<String, dynamic>> records;

  @override
  State<SeRfcDashboard> createState() => _SeRfcDashboardState();
}

class _SeRfcDashboardState extends State<SeRfcDashboard> {
  DashPeriod _period = DashPeriod.thisMonth;

  static DateTime? _submitted(Map<String, dynamic> record) =>
      DateTime.tryParse(record['submissionDate']?.toString() ?? '');

  static int _count(List<Map<String, dynamic>> records, Set<ErfcStatus> set) =>
      records
          .where((r) => set.contains(ErfcStatus.fromWire(r['status'])))
          .length;

  static const _inApproval = {
    ErfcStatus.submitted,
    ErfcStatus.firstVerified,
    ErfcStatus.secondVerified,
  };
  static const _completed = {
    ErfcStatus.erfcCompleted,
    ErfcStatus.paperworkReceived,
    ErfcStatus.confirmToProceed,
  };

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final range = _period.describe();

    final records = widget.records.where((r) {
      final date = _submitted(r);
      return _period.contains(date);
    }).toList();
    final total = records.length;

    final lifecycle = widget.records.where((r) {
      final date = _submitted(r);
      return date != null && date.year == now.year && date.month == now.month;
    }).toList();

    int count(Set<ErfcStatus> set) => _count(records, set);

    final steps = [
      SeFlowStep(
        step: 'Step 1',
        flow: 'Submission',
        title: 'Submitted',
        big: total,
        note: 'RFCs submitted in $range',
      ),
      _gate(
        records,
        step: 'Step 2',
        title: '1st Verifier',
        approved: (r) => r['verified1Date'] != null,
        stopped: const {
          ErfcStatus.rejectedByFirstVerifier,
          ErfcStatus.declinedByFirstVerifier,
        },
        waiting: const {ErfcStatus.submitted},
        approvedLabel: 'Verified',
      ),
      _gate(
        records,
        step: 'Step 3',
        title: '2nd Verifier',
        approved: (r) => r['verified2Date'] != null,
        stopped: const {
          ErfcStatus.rejectedBySecondVerifier,
          ErfcStatus.declinedBySecondVerifier,
        },
        waiting: const {ErfcStatus.firstVerified},
        approvedLabel: 'Verified',
      ),
      _gate(
        records,
        step: 'Step 4',
        title: 'Endorser',
        approved: (r) => ErfcStatus.endorsedOrBeyond.contains(
          ErfcStatus.fromWire(r['status']),
        ),
        stopped: const {
          ErfcStatus.rejectedByEndorser,
          ErfcStatus.declinedByEndorser,
        },
        waiting: const {ErfcStatus.secondVerified},
        approvedLabel: 'Endorsed',
      ),
      SeFlowStep(
        step: 'Step 5',
        flow: 'Tender prep',
        title: 'RFC Completed',
        big: count(_completed),
        note: 'of ${count(ErfcStatus.endorsedOrBeyond)} endorsed RFCs',
      ),
    ];

    const stages = [
      ('In Approval', DashTheme.warning),
      ('Endorsed', DashTheme.success),
      ('RFC Completed', DashTheme.info),
      ('Rejected / Declined', DashTheme.danger),
    ];
    final stageCounts = [
      _count(lifecycle, _inApproval),
      _count(lifecycle, const {ErfcStatus.endorsed}),
      _count(lifecycle, _completed),
      _count(lifecycle, ErfcStatus.rejectedOrDeclined),
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
          title: 'RFC Overview Status',
          metadata: 'SE view · $total RFCs · $range',
        ),
        const SizedBox(height: 12),
        SeOverviewMetricGrid(
          cards: [
            SeOverviewMetric(
              label: 'Submitted',
              value: total,
              total: total,
              subtext: 'RFCs raised in the period',
              accent: DashTheme.accent,
              icon: Icons.request_page_outlined,
            ),
            SeOverviewMetric(
              label: 'In Approval',
              value: count(_inApproval),
              total: total,
              subtext: 'Waiting on a verifier or the endorser',
              accent: DashTheme.warning,
              icon: Icons.autorenew,
            ),
            SeOverviewMetric(
              label: 'Endorsed',
              value: count(ErfcStatus.endorsedOrBeyond),
              total: total,
              subtext: 'Endorsed, validity running or used',
              accent: DashTheme.success,
              icon: Icons.verified_outlined,
            ),
            SeOverviewMetric(
              label: 'RFC Completed',
              value: count(_completed),
              total: total,
              subtext: 'Flowed to tender preparation',
              accent: DashTheme.info,
              icon: Icons.check_circle_outline,
            ),
            SeOverviewMetric(
              label: 'Rejected / Declined',
              value: count(ErfcStatus.rejectedOrDeclined),
              total: total,
              subtext: 'Stopped at an approval gate',
              accent: DashTheme.danger,
              icon: Icons.block_outlined,
            ),
          ],
        ),
        const SizedBox(height: DashTheme.gap),
        seSection(
          title: 'RFC Approval Flow',
          metadata:
              'SE view · $total RFCs through three approval gates · $range',
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
          wide: SeProcessingByDivisionCard(records: records),
          narrow: seSection(
            title: 'RFC Lifecycle',
            metadata:
                '${dashMonthName(now.month)} ${now.year} · '
                '${lifecycle.length} records',
            icon: Icons.bar_chart,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < stages.length; i++) ...[
                  if (i > 0) const SizedBox(height: 14),
                  SeLifecycleProgress(
                    label: stages[i].$1,
                    count: stageCounts[i],
                    total: lifecycle.length,
                    color: stages[i].$2,
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                const Text(
                  'Current status of RFCs submitted this month, regardless '
                  'of the period filter.',
                  style: TextStyle(
                    color: DashTheme.muted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  SeFlowStep _gate(
    List<Map<String, dynamic>> records, {
    required String step,
    required String title,
    required bool Function(Map<String, dynamic>) approved,
    required Set<ErfcStatus> stopped,
    required Set<ErfcStatus> waiting,
    required String approvedLabel,
  }) {
    final passed = records.where(approved).length;
    final stoppedCount = _count(records, stopped);
    final pending = _count(records, waiting);
    return SeFlowStep(
      step: step,
      flow: 'Approval',
      title: title,
      lines: [
        (approvedLabel, passed, DashTheme.success),
        ('Rejected', stoppedCount, DashTheme.danger),
      ],
      footer: '$pending pending at this stage',
    );
  }
}
