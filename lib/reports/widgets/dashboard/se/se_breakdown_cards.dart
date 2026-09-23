// lib/reports/widgets/dashboard/se/se_breakdown_cards.dart
//
// One bar per stage: the tender lifecycle, the eRFC pipeline, the
// vendor funnel, and the two eRFC panels beside them.
import 'package:flutter/material.dart';

import 'package:etender_reports/reports/models/erfc_metrics.dart';
import 'package:etender_reports/reports/models/erfc_status.dart';
import 'package:etender_reports/reports/models/tender_metrics.dart';
import 'package:etender_reports/reports/models/tender_status.dart';
import 'package:etender_reports/reports/models/vendor_metrics.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_cards.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_primitives.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_theme.dart';

class SeTenderStatusCard extends StatelessWidget {
  const SeTenderStatusCard({super.key, required this.records});

  final List<Map<String, dynamic>> records;

  @override
  Widget build(BuildContext context) {
    final counts = tenderStatusCounts(records);
    int countOf(Set<TenderStatus> group) =>
        TenderStatus.wiresOf(group)
            .fold<int>(0, (total, wire) => total + (counts[wire] ?? 0));

    final stages = <(String, int, Color)>[
      ('Published', countOf(const {TenderStatus.published}), DashTheme.success),
      ('Extended', countOf(const {TenderStatus.extended}), DashTheme.warning),
      ('Closed', countOf(const {TenderStatus.closed}), DashTheme.muted),
    ];

    return DashCard(
      icon: Icons.flag_outlined,
      title: 'Tender Lifecycle',
      subtitle: '${records.length} records',
      child: DashBarList(rows: stages, total: records.length),
    );
  }
}

class SeErfcPipelineCard extends StatelessWidget {
  const SeErfcPipelineCard({super.key, required this.records});

  final List<Map<String, dynamic>> records;

  @override
  Widget build(BuildContext context) {
    int countOf(Set<ErfcStatus> group) =>
        erfcCountWithStatus(records, ErfcStatus.wiresOf(group));

    final stages = <(String, int, Color)>[
      ('In progress', countOf(ErfcStatus.inFlight), DashTheme.info),
      ('Rejected/declined', countOf(ErfcStatus.rejected), DashTheme.danger),
      (
        'Endorsed or beyond',
        countOf(ErfcStatus.endorsedOrBeyond),
        DashTheme.success,
      ),
      ('Cancelled', countOf(const {ErfcStatus.cancelled}), DashTheme.muted),
    ];
    final average = erfcAverageProcessingDays(records);

    return DashCard(
      icon: Icons.request_page_outlined,
      title: 'eRFC Pipeline',
      subtitle: average == null
          ? '${records.length} RFCs'
          : '${records.length} RFCs · avg '
                '${average.toStringAsFixed(1)} days to endorse',
      child: DashBarList(rows: stages, total: records.length),
    );
  }
}

class SeVendorFunnelCard extends StatelessWidget {
  const SeVendorFunnelCard({super.key, required this.records});

  final List<Map<String, dynamic>> records;

  @override
  Widget build(BuildContext context) {
    final invited = vendorInvitedCount(records);
    final stages = <(String, int, Color)>[
      ('Invited', invited, DashTheme.accent),
      (
        'Took up the invite',
        vendorParticipatedCount(records),
        DashTheme.purple,
      ),
      ('Bought documents', vendorPurchasedCount(records), DashTheme.info),
      ('Submitted a bid', vendorSubmittedCount(records), DashTheme.success),
    ];

    return DashCard(
      icon: Icons.groups_outlined,
      title: 'Vendor Participation',
      subtitle: '${records.length} vendor records',
      child: DashBarList(rows: stages, total: records.length),
    );
  }
}

class SeProcessingByDivisionCard extends StatelessWidget {
  const SeProcessingByDivisionCard({super.key, required this.records});

  final List<Map<String, dynamic>> records;

  @override
  Widget build(BuildContext context) {
    final averages = erfcAverageProcessingDaysByDivision(records);
    final divisions = averages.keys.toList()
      ..sort((a, b) => averages[b]!.compareTo(averages[a]!));
    final slowest = divisions.isEmpty ? 0.0 : averages[divisions.first]!;

    return DashCard(
      icon: Icons.timelapse_outlined,
      title: 'Processing Time by Division',
      subtitle: 'Submission to endorsement, slowest first',
      child: divisions.isEmpty
          ? const Text(
              'No RFC has been endorsed yet.',
              style: TextStyle(fontSize: 12, color: DashTheme.muted),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < divisions.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  DashMeasureBar(
                    label: divisions[i],
                    valueLabel:
                        '${averages[divisions[i]]!.toStringAsFixed(1)} days',
                    fraction: slowest == 0
                        ? 0
                        : averages[divisions[i]]! / slowest,
                    // The slowest division is the one worth looking at.
                    color: i == 0 ? DashTheme.warning : DashTheme.accent,
                  ),
                ],
              ],
            ),
    );
  }
}

class SeCertificationMixCard extends StatelessWidget {
  const SeCertificationMixCard({super.key, required this.records});

  final List<Map<String, dynamic>> records;

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final record in records) {
      final type = record['certificationType']?.toString() ?? 'Unknown';
      counts[type] = (counts[type] ?? 0) + 1;
    }
    final types = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));

    // The issuing body is the prefix; it is what the eye groups by.
    const palette = [
      DashTheme.accent,
      DashTheme.info,
      DashTheme.purple,
      DashTheme.success,
      DashTheme.warning,
      DashTheme.danger,
      DashTheme.muted,
    ];

    return DashCard(
      icon: Icons.workspace_premium_outlined,
      title: 'Certification Mix',
      subtitle: '${types.length} certificate types held',
      child: types.isEmpty
          ? const Text(
              'No certification recorded.',
              style: TextStyle(fontSize: 12, color: DashTheme.muted),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < types.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  DashBar(
                    label: types[i],
                    count: counts[types[i]]!,
                    total: records.length,
                    color: palette[i % palette.length],
                  ),
                ],
              ],
            ),
    );
  }
}
