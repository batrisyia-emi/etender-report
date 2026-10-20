// lib/reports/procurement_lead_time/widgets/lead_time_summary_section.dart
import 'package:etender_reports/reports/procurement_lead_time/lead_time_rules.dart';
import 'package:etender_reports/reports/procurement_lead_time/models/lead_time_summary.dart';
import 'package:etender_reports/reports/procurement_lead_time/widgets/lead_time_kpi_cards.dart';
import 'package:etender_reports/reports/procurement_lead_time/widgets/lead_time_rating_explanation.dart';
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
    this.showExplanation = false,
  });

  final LeadTimeSummary summary;

  /// Puts the rating explanation beside this section's rating card. Only
  /// the first section on the page does, so it appears once.
  final bool showExplanation;

  final LeadTimeBucket? selectedBucket;
  final ValueChanged<LeadTimeBucket> onBucketSelected;

  /// Below this the explanation would leave the cards beside it a sliver,
  /// so it moves under the rating card instead.
  static const double _sideBySideWidth = 760;

  /// The explanation's share of the section, kept between a floor where
  /// its text still reads comfortably and a cap so it never sprawls. At
  /// those widths it comes out about as tall as the three cards.
  static const double _explanationShare = 0.45;
  static const double _explanationMinWidth = 440;
  static const double _explanationMaxWidth = 560;

  @override
  Widget build(BuildContext context) {
    return ReportPanel(
      title: summary.documentType.label,
      trailing: ReportCountPill(label: '${summary.total} tenders'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final table = LeadTimeSummaryTable(
              summary: summary,
              selectedBucket: selectedBucket,
              onBucketSelected: onBucketSelected,
            );
            final List<Widget> top;
            if (!showExplanation) {
              top = [LeadTimeKpiCards(summary: summary)];
            } else if (constraints.maxWidth >= _sideBySideWidth) {
              // The three cards in a column, rating at the bottom, with
              // the explanation of that rating beside them. The cards take
              // whatever width the explanation leaves.
              final explanationWidth =
                  (constraints.maxWidth * _explanationShare).clamp(
                    _explanationMinWidth,
                    _explanationMaxWidth,
                  );
              // IntrinsicHeight makes the row as tall as the taller side and
              // stretch brings the other up to it, so the card column and
              // the explanation start and end level.
              top = [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: LeadTimeKpiCards(
                          summary: summary,
                          stacked: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: explanationWidth,
                        // Decided here rather than measured: see stackRules.
                        // At the minimum width the rules still have room
                        // beside their badges.
                        child: const LeadTimeRatingExplanation(
                          stackRules: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ];
            } else {
              // Narrow: the cards one per row, so the explanation lands
              // straight under the rating card.
              top = [
                LeadTimeKpiCards(summary: summary),
                const SizedBox(height: 12),
                const LeadTimeRatingExplanation(),
              ];
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [...top, const SizedBox(height: 12), table],
            );
          },
        ),
      ),
    );
  }
}
