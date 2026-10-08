// lib/reports/widgets/dashboard/se/se_tender_dashboard.dart
//
// The Tenders tab: overview status, the supplier response flow, tenders
// closing soon and the tender lifecycle.
import 'package:etender_reports/reports/models/status/tender_status.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_cards.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_period.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_scroll.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_theme.dart';
import 'package:etender_reports/reports/widgets/dashboard/se/se_closing_soon_card.dart';
import 'package:etender_reports/reports/widgets/dashboard/se/se_toc_opening_dashboard.dart';
import 'package:etender_reports/shared/utils/formatters.dart';
import 'package:flutter/material.dart';

class SeTenderDashboard extends StatefulWidget {
  const SeTenderDashboard({
    super.key,
    required this.tenders,
    required this.vendors,
  });

  final List<Map<String, dynamic>> tenders;

  /// One row per supplier invited to a tender.
  final List<Map<String, dynamic>> vendors;

  @override
  State<SeTenderDashboard> createState() => _SeTenderDashboardState();
}

class _SeTenderDashboardState extends State<SeTenderDashboard> {
  DashPeriod _period = DashPeriod.thisMonth;

  static DateTime? _closing(Map<String, dynamic> record) =>
      DateTime.tryParse(record['closingDate']?.toString() ?? '');

  static int _countStatus(
    List<Map<String, dynamic>> records,
    TenderStatus status,
  ) =>
      records.where((r) => TenderStatus.fromWire(r['status']) == status).length;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final range = _period.describe();

    final records = widget.tenders.where((r) {
      final closing = _closing(r);
      return closing != null && _period.contains(closing);
    }).toList();
    final total = records.length;

    final tenderNos = {for (final r in records) r['tenderNo']};
    final requests = widget.vendors
        .where((r) => tenderNos.contains(r['tenderNo']))
        .toList();

    final lifecycle = widget.tenders.where((r) {
      final closing = _closing(r);
      return closing != null &&
          closing.year == now.year &&
          closing.month == now.month;
    }).toList();

    const stages = [
      (TenderStatus.published, DashTheme.success),
      (TenderStatus.extended, DashTheme.warning),
      (TenderStatus.closed, DashTheme.muted),
      (TenderStatus.completed, DashTheme.info),
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
          title: 'Tender Overview Status',
          metadata: 'SE & Supplier view · $total tenders · $range',
        ),
        const SizedBox(height: 12),
        SeOverviewMetricGrid(
          cards: [
            SeOverviewMetric(
              label: 'Published',
              value: _countStatus(records, TenderStatus.published),
              total: total,
              subtext: 'VTM has published the tender',
              accent: DashTheme.success,
              icon: Icons.campaign_outlined,
            ),
            SeOverviewMetric(
              label: 'Extended',
              value: _countStatus(records, TenderStatus.extended),
              total: total,
              subtext: 'Closing date has been extended',
              accent: DashTheme.warning,
              icon: Icons.event_repeat_outlined,
            ),
            SeOverviewMetric(
              label: 'Closed',
              value: _countStatus(records, TenderStatus.closed),
              total: total,
              subtext: 'Submission no longer accepted',
              accent: DashTheme.muted,
              icon: Icons.lock_outline,
            ),
            SeOverviewMetric(
              label: 'Completed',
              value: _countStatus(records, TenderStatus.completed),
              total: total,
              subtext: 'Appendix P completed by VTM Executive',
              accent: DashTheme.info,
              icon: Icons.check_circle_outline,
            ),
          ],
        ),
        const SizedBox(height: DashTheme.gap),
        seSection(
          title: 'Tender Response Status',
          metadata:
              'SE view · ${requests.length} supplier participation requests '
              'across $total tenders · $range',
          icon: Icons.groups_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: Alignment.centerRight,
                child: SeFlowLegend(),
              ),
              const SizedBox(height: 12),
              _ResponseFlow(requests: requests),
            ],
          ),
        ),
        const SizedBox(height: DashTheme.gap),
        DashSplitRow(
          wide: SeClosingSoonCard(records: widget.tenders, limit: 10),
          narrow: seSection(
            title: 'Tender Lifecycle',
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
                    label: stages[i].$1.wireValue,
                    count: _countStatus(lifecycle, stages[i].$1),
                    total: lifecycle.length,
                    color: stages[i].$2,
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                const Text(
                  'Current status of tenders active this month, regardless '
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
}

class SeFlowLegend extends StatelessWidget {
  const SeFlowLegend({super.key});

  @override
  Widget build(BuildContext context) => const Wrap(
    spacing: 16,
    runSpacing: 6,
    children: [
      SeLegendDot(label: 'Approved / Verified', color: DashTheme.success),
      SeLegendDot(label: 'Rejected', color: DashTheme.danger),
      SeLegendDot(label: 'Pending at stage', color: DashTheme.muted),
    ],
  );
}

class SeLegendDot extends StatelessWidget {
  const SeLegendDot({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SeDot(color: color),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(color: DashTheme.muted, fontSize: 11)),
    ],
  );
}

class SeDot extends StatelessWidget {
  const SeDot({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

/// A counted line inside a step card; a null [count] reads as no data.
typedef SeFlowLine = (String label, int? count, Color color);

class SeFlowStep {
  const SeFlowStep({
    required this.step,
    required this.flow,
    required this.title,
    this.lines = const [],
    this.big,
    this.note,
    this.footer,
  });

  final String step;
  final String flow;
  final String title;
  final List<SeFlowLine> lines;
  final int? big;
  final String? note;
  final String? footer;
}

class _ResponseFlow extends StatelessWidget {
  const _ResponseFlow({required this.requests});

  final List<Map<String, dynamic>> requests;

  @override
  Widget build(BuildContext context) {
    final invited = requests.where((r) => r['invitationStatus'] == 'Sent');
    final participated = requests
        .where((r) => r['participationStatus'] == 'Participated')
        .length;
    final declined = requests
        .where((r) => r['participationStatus'] == 'Rejected')
        .length;
    final purchased = requests.where((r) => r['documentPurchased'] == true);
    final submitted = requests
        .where(
          (r) =>
              r['submissionStatus'] == 'Submitted' ||
              r['submissionStatus'] == 'Late',
        )
        .length;

    // The dataset has no VTM approval trail, so those counts stay blank.
    const noData = 'No approval data';
    final steps = [
      SeFlowStep(
        step: 'Step 1',
        flow: 'Flow 1.7',
        title: 'Participation Requested',
        big: invited.length,
        note: 'Supplier requests to participate',
      ),
      const SeFlowStep(
        step: 'Step 2',
        flow: 'Flow B',
        title: 'VTM Clerk',
        lines: [
          ('Approved', null, DashTheme.success),
          ('Rejected', null, DashTheme.danger),
        ],
        footer: noData,
      ),
      const SeFlowStep(
        step: 'Step 3',
        flow: 'Flow C',
        title: 'VTM Executive',
        lines: [
          ('Verified', null, DashTheme.success),
          ('Rejected', null, DashTheme.danger),
        ],
        footer: noData,
      ),
      const SeFlowStep(
        step: 'Step 4',
        flow: 'Flow D',
        title: 'VTM Manager',
        lines: [
          ('Approved', null, DashTheme.success),
          ('Rejected', null, DashTheme.danger),
        ],
        footer: noData,
      ),
      SeFlowStep(
        step: 'Step 5',
        flow: 'Flow 1.9',
        title: 'Paid',
        big: purchased.length,
        note: 'tender documents purchased',
      ),
      SeFlowStep(
        step: 'Step 6',
        flow: 'Flow F',
        title: 'Bid Decision',
        lines: [
          ('Participated', participated, DashTheme.success),
          ('Not Participate', declined, DashTheme.danger),
        ],
        footer:
            '${requests.length - participated - declined} pending at this '
            'stage',
      ),
      SeFlowStep(
        step: 'Step 7',
        flow: 'Flow 1.13',
        title: 'Submitted',
        big: submitted,
        note: 'of $participated participated suppliers',
      ),
    ];

    return SeFlowRow(steps: steps);
  }
}

/// Step cards laid out evenly, scrolling sideways once they get too narrow.
class SeFlowRow extends StatelessWidget {
  const SeFlowRow({super.key, required this.steps});

  final List<SeFlowStep> steps;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final fitted =
            (constraints.maxWidth - gap * (steps.length - 1)) / steps.length;
        final width = fitted < 150 ? 150.0 : fitted;
        final row = IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                SizedBox(
                  width: width,
                  child: SeFlowStepCard(step: steps[i]),
                ),
              ],
            ],
          ),
        );
        return DashHorizontalScroll(child: row);
      },
    );
  }
}

class SeFlowStepCard extends StatelessWidget {
  const SeFlowStepCard({super.key, required this.step});

  final SeFlowStep step;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: DashTheme.background,
      border: Border.all(color: DashTheme.border),
      borderRadius: BorderRadius.circular(DashTheme.radius),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: DashTheme.accent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                step.step,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                step.flow,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: DashTheme.muted, fontSize: 10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          step.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: DashTheme.text,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        if (step.big != null)
          Text(
            formatNumber(step.big!, decimals: 0),
            style: const TextStyle(
              color: DashTheme.text,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        for (final line in step.lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              children: [
                SeDot(color: line.$3),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    line.$1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: DashTheme.text, fontSize: 12),
                  ),
                ),
                Text(
                  line.$2 == null ? '-' : '${line.$2}',
                  style: TextStyle(
                    color: line.$2 == null ? DashTheme.muted : line.$3,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        if (step.note != null) ...[
          const SizedBox(height: 4),
          Text(
            step.note!,
            style: const TextStyle(
              color: DashTheme.muted,
              fontSize: 10,
              height: 1.3,
            ),
          ),
        ],
        if (step.footer != null) ...[
          const Divider(height: 14),
          Text(
            step.footer!,
            style: const TextStyle(color: DashTheme.muted, fontSize: 10),
          ),
        ],
      ],
    ),
  );
}
