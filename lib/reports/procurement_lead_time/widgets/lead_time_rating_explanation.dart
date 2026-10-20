// lib/reports/procurement_lead_time/widgets/lead_time_rating_explanation.dart
import 'package:etender_reports/reports/procurement_lead_time/lead_time_rules.dart';
import 'package:etender_reports/reports/procurement_lead_time/widgets/lead_time_rating_badge.dart';
import 'package:etender_reports/reports/widgets/shared/report_panel.dart';
import 'package:flutter/material.dart';

/// How a rating is reached, in words, beside the badge each rule earns.
///
/// Every number comes from [LeadTimeRules], so a threshold SE changes is
/// changed here too, and the page can never explain a rule it no longer
/// applies.
class LeadTimeRatingExplanation extends StatelessWidget {
  const LeadTimeRatingExplanation({super.key});

  static String _percent(double value) => '${value.toStringAsFixed(0)}%';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme.bodyMedium;
    final excellent = _percent(
      LeadTimeRules.excellentWithin3WorkingDaysPercent,
    );
    final good = _percent(LeadTimeRules.goodWithin7WorkingDaysPercent);

    final rules = [
      (
        PerformanceRating.excellent,
        'At least $excellent of tenders are published within 3 working '
            'days.',
      ),
      (
        PerformanceRating.good,
        'Not Excellent, but at least $good are published within 7 working '
            'days (the 1–3 and 4–7 working day bands together).',
      ),
      (
        PerformanceRating.belowExpectations,
        'Fewer than $good are published within 7 working days.',
      ),
    ];

    return ReportPanel(
      title: 'How the performance rating is calculated',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _Step(
              number: 1,
              style: text,
              text:
                  'Each tender or quotation is given a lead time: the working '
                  'days from the day VTM receives the eRFC to the day it is '
                  'first published. Both days count. Weekends and public '
                  'holidays do not, and publishing again after an addendum '
                  'does not change it.',
            ),
            _Step(
              number: 2,
              style: text,
              text:
                  'The lead times are sorted into the 1–3, 4–7 and more than '
                  '7 working day bands. Each band’s percentage is its '
                  'share of everything published in the period.',
            ),
            _Step(
              number: 3,
              style: text,
              text:
                  'The rating is taken from those shares, separately for '
                  'Tender and for Quotation:',
            ),
            const SizedBox(height: 8),
            // Badge first, so the colour on the cards and in the table
            // finds its rule here at a glance. On a phone the badge sits
            // above its rule; beside it the rule would be a sliver.
            Padding(
              padding: const EdgeInsets.only(left: _Step.numberWidth),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 480;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (rating, rule) in rules)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: stacked
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    LeadTimeRatingBadge(rating: rating),
                                    const SizedBox(height: 4),
                                    Text(rule, style: text),
                                  ],
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 150,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: LeadTimeRatingBadge(
                                          rating: rating,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 3),
                                        child: Text(rule, style: text),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One numbered sentence of the explanation.
class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text, this.style});

  final int number;
  final String text;
  final TextStyle? style;

  /// The column the step numbers sit in; the rules below indent to match.
  static const double numberWidth = 28;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: numberWidth,
            child: Text(
              '$number.',
              style: style?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }
}
