// lib/reports/widgets/dashboard/se/se_process_cards.dart
//
// The breakdown cards for the three later reports: the opening committees,
// the securities on file, and VTM's Appendix F pipeline.
//
// Same shape as se_breakdown_cards.dart — one bar per stage, counts only.
// Nothing here reads a bid amount: see the warning on TocOpeningRecord.
import 'package:etender_reports/reports/models/metrics/tender_security_metrics.dart';
import 'package:etender_reports/reports/models/metrics/toc_metrics.dart';
import 'package:etender_reports/reports/models/metrics/vtm_monitoring_metrics.dart';
import 'package:etender_reports/reports/models/records/tender_security_record.dart';
import 'package:etender_reports/reports/models/records/toc_opening_record.dart';
import 'package:etender_reports/reports/models/records/vtm_monitoring_record.dart';
import 'package:etender_reports/reports/models/status/toc_status.dart';
import 'package:etender_reports/reports/models/status/vtm_monitoring_status.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_cards.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_primitives.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_theme.dart';
import 'package:etender_reports/shared/utils/formatters.dart';
import 'package:flutter/material.dart';

/// The five statuses between "committee named" and "done".
///
/// Grouped rather than listed one by one, because which of them a tender
/// sits at depends on whether it takes one envelope or two — a reader of a
/// dashboard wants "being opened", not the envelope mechanics.
final Set<TocStatus> _tocUnderWay = {
  for (final status in TocStatus.values)
    if (status.isUnderWay) status,
};

/// Where the openings stand, as four stages rather than eight statuses.
class SeTocProgressCard extends StatelessWidget {
  const SeTocProgressCard({super.key, required this.records});

  final List<TocOpeningRecord> records;

  @override
  Widget build(BuildContext context) {
    final stages = <(String, int, Color)>[
      (
        'Awaiting committee',
        tocCountWithStatus(records, TocStatus.open),
        DashTheme.warning,
      ),
      (
        'Committee appointed',
        tocCountWithStatus(records, TocStatus.committeeAppointed),
        DashTheme.info,
      ),
      (
        'Opening under way',
        tocCountWithStatuses(records, _tocUnderWay),
        DashTheme.accent,
      ),
      (
        'Opening completed',
        tocCountWithStatus(records, TocStatus.openingCompleted),
        DashTheme.success,
      ),
    ];

    final average = tocAverageAging(records);

    return DashCard(
      icon: Icons.groups_outlined,
      title: 'Opening Progress',
      subtitle: average == null
          ? '${records.length} openings'
          : '${records.length} openings · avg '
                '${average.toStringAsFixed(1)} days to close out',
      child: DashBarList(rows: stages, total: records.length),
    );
  }
}

/// Who is carrying the committee load, busiest first.
///
/// The blueprint sets no ceiling on assignments per officer, which is why
/// this ranks rather than flags — see question 5 in docs/toc-report.md.
class SeTocWorkloadCard extends StatelessWidget {
  const SeTocWorkloadCard({super.key, required this.records, this.limit = 5});

  final List<TocOpeningRecord> records;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final workload = tocCommitteeWorkload(records);
    final shown = workload.take(limit).toList();
    final busiest = shown.isEmpty ? 0 : shown.first.total;

    return DashCard(
      icon: Icons.person_outline,
      title: 'Committee Workload',
      subtitle: workload.isEmpty
          ? 'No committees appointed'
          : '${workload.length} officers serving',
      child: workload.isEmpty
          ? const DashEmptyNote('Nothing appointed yet.')
          : DashBarList(
              rows: [
                for (final member in shown)
                  (member.name, member.total, DashTheme.purple),
              ],
              // Scaled against the busiest officer rather than the record
              // count: the question is who carries most, not what share of
              // the openings one person sits on.
              total: busiest,
            ),
    );
  }
}

/// What is on file and what state it is in.
class SeSecurityStatusCard extends StatelessWidget {
  const SeSecurityStatusCard({super.key, required this.records});

  final List<TenderSecurityRecord> records;

  @override
  Widget build(BuildContext context) {
    final expired = tenderSecurityExpiredCount(records);
    final stages = <(String, int, Color)>[
      (
        'Expiring soon',
        tenderSecurityExpiringSoonCount(records),
        DashTheme.warning,
      ),
      ('Expired, still held', expired, DashTheme.danger),
      (
        'Pending refund',
        tenderSecurityPendingRefundCount(records),
        DashTheme.info,
      ),
      ('Refunded', tenderSecurityRefundedCount(records), DashTheme.success),
    ];

    return DashCard(
      icon: Icons.verified_user_outlined,
      title: 'Security Status',
      subtitle: records.isEmpty
          ? 'No tender security data'
          : '${records.length} on file · '
                '${formatValue(tenderSecurityHeld(records))} held',
      child: records.isEmpty
          ? const DashEmptyNote(
              'The tender security endpoint returned nothing.',
            )
          : DashBarList(rows: stages, total: records.length),
    );
  }
}

/// The paperwork still owed on securities already lodged.
///
/// Both rows are chases rather than faults: the instrument exists, it just
/// has not reached the desk that has to hold it.
class SeSecurityHandoverCard extends StatelessWidget {
  const SeSecurityHandoverCard({super.key, required this.records});

  final List<TenderSecurityRecord> records;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, int, Color)>[
      (
        'Original not received',
        tenderSecurityOriginalNotReceivedCount(records),
        DashTheme.warning,
      ),
      (
        'Not sent to Revenue Assurance',
        tenderSecurityNotSubmittedCount(records),
        DashTheme.info,
      ),
    ];

    return DashCard(
      icon: Icons.move_to_inbox_outlined,
      title: 'Still to Chase',
      subtitle: records.isEmpty
          ? 'Nothing on file'
          : '${records.length} on file',
      child: records.isEmpty
          ? const DashEmptyNote(
              'The tender security endpoint returned nothing.',
            )
          : DashBarList(rows: rows, total: records.length),
    );
  }
}

/// The Appendix F pipeline, from preparation to floating.
class SeVtmPipelineCard extends StatelessWidget {
  const SeVtmPipelineCard({super.key, required this.records});

  final List<VtmMonitoringRecord> records;

  @override
  Widget build(BuildContext context) {
    int countOf(VtmStatus status) => vtmCountWithStatus(records, status);

    final stages = <(String, int, Color)>[
      ('Draft', countOf(VtmStatus.draft), DashTheme.muted),
      ('Submitted', countOf(VtmStatus.submitted), DashTheme.info),
      ('Verified by exec', countOf(VtmStatus.verifiedByExec), DashTheme.accent),
      (
        'Approved, awaiting float',
        countOf(VtmStatus.approvedByManager),
        DashTheme.warning,
      ),
      ('Published', countOf(VtmStatus.published), DashTheme.success),
      // Both gates in one row: which one turned the document back matters
      // less at a glance than that somebody has to redo it.
      ('Sent back', vtmRejectedCount(records), DashTheme.danger),
    ];

    final average = vtmAveragePublishedAging(records);

    return DashCard(
      icon: Icons.timeline_outlined,
      title: 'Appendix F Pipeline',
      subtitle: average == null
          ? '${records.length} documents'
          : '${records.length} documents · avg '
                '${average.toStringAsFixed(1)} days to float',
      child: DashBarList(rows: stages, total: records.length),
    );
  }
}

/// The documents VTM has to act on, by why.
class SeVtmAttentionCard extends StatelessWidget {
  const SeVtmAttentionCard({super.key, required this.records});

  final List<VtmMonitoringRecord> records;

  @override
  Widget build(BuildContext context) {
    final flags = vtmFlags(records);
    final urgent = flags
        .where((flag) => flag.severity == VtmFlagSeverity.high)
        .length;

    final rows = <(String, int, Color)>[
      ('Urgent', urgent, DashTheme.danger),
      ('To watch', flags.length - urgent, DashTheme.warning),
      (
        'Sitting over $kVtmSlowDays days',
        vtmSlowCount(records),
        DashTheme.info,
      ),
    ];

    return DashCard(
      icon: Icons.warning_amber_rounded,
      title: 'Needs Attention',
      subtitle: flags.isEmpty
          ? 'Nothing stuck or unexplained'
          : '${flags.length} findings',
      child: flags.isEmpty
          ? const DashEmptyNote(
              'Every document is moving, has its reasons recorded and '
              'carries the number it should.',
            )
          : DashBarList(rows: rows, total: flags.length),
    );
  }
}

/// Stands in for a bar list when there is nothing to chart.
class DashEmptyNote extends StatelessWidget {
  const DashEmptyNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, color: DashTheme.muted),
    );
  }
}
