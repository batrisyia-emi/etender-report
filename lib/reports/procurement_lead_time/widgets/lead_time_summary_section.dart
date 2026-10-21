// lib/reports/procurement_lead_time/widgets/lead_time_summary_section.dart
import 'package:etender_reports/reports/procurement_lead_time/lead_time_rules.dart';
import 'package:etender_reports/reports/procurement_lead_time/models/lead_time_summary.dart';
import 'package:etender_reports/reports/procurement_lead_time/widgets/lead_time_kpi_cards.dart';
import 'package:etender_reports/reports/procurement_lead_time/widgets/lead_time_summary_table.dart';
import 'package:etender_reports/reports/widgets/shared/report_panel.dart';
import 'package:flutter/material.dart';

/// Everything about one document type in one frame: its name and count in
/// the header, the three headline cards, then the table they come from.
///
/// With All selected there are two of these, Tender then Quotation, so the
/// frame is what tells a reader where one ends and the other begins.
class LeadTimeSummarySection extends StatelessWidget {
  const LeadTimeSummarySection({
    super.key,
    required this.summary,
    required this.selectedBucket,
    required this.onBucketSelected,
  });

  final LeadTimeSummary summary;
  final LeadTimeBucket? selectedBucket;
  final ValueChanged<LeadTimeBucket> onBucketSelected;

  @override
  Widget build(BuildContext context) {
    return ReportPanel(
      title: summary.documentType.label,
      trailing: ReportCountPill(label: '${summary.total} tenders'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            LeadTimeKpiCards(summary: summary),
            const SizedBox(height: 12),
            LeadTimeSummaryTable(
              summary: summary,
              selectedBucket: selectedBucket,
              onBucketSelected: onBucketSelected,
            ),
          ],
        ),
      ),
    );
  }
}
