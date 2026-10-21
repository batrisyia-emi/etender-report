// lib/reports/procurement_lead_time/widgets/lead_time_rating_explanation.dart
import 'package:etender_reports/reports/procurement_lead_time/lead_time_rules.dart';
import 'package:etender_reports/reports/procurement_lead_time/widgets/lead_time_rating_badge.dart';
import 'package:etender_reports/reports/widgets/shared/report_panel.dart';
import 'package:flutter/material.dart';

/// How a rating is reached, in words, beside the badge each rule earns.
///
/// The rule text is SE's own wording, kept verbatim; see the note on
/// `rules` in [build].
class LeadTimeRatingExplanation extends StatelessWidget {
  const LeadTimeRatingExplanation({super.key, this.framed = true});

  /// True on the page, in a titled panel. False inside [show]'s dialog,
  /// whose own title says the same.
  final bool framed;

  /// Below this the rule beside its badge would be a sliver.
  static const double _stackBelowWidth = 340;

  static const String title = 'How the performance rating is calculated';

  /// The same explanation in a dialog, for the link beside the rating in
  /// the result header on a screen too narrow for the panel beside the
  /// search.
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(title),
        content: const SizedBox(
          width: 680,
          child: SingleChildScrollView(
            child: LeadTimeRatingExplanation(framed: false),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The small body size, so the box beside the search stays short.
    final text = theme.textTheme.bodySmall;
    // SE's wording, word for word. It is not built from LeadTimeRules: if
    // a threshold there changes, change these three lines with it.
    const rules = [
      (
        PerformanceRating.excellent,
        '95% - 100% are published within 3 working days.',
      ),
      (
        PerformanceRating.good,
        '90% - 94% are published within 7 working days (the 1–3 '
            'and 4–7 working day bands together).',
      ),
      (
        PerformanceRating.belowExpectations,
        'Less than 90% are published after 7 working days.',
      ),
    ];

    Widget rulesColumn(bool stacked) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (rating, rule) in rules)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
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
                        width: 130,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: LeadTimeRatingBadge(rating: rating),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(rule, style: text),
                        ),
                      ),
                    ],
                  ),
          ),
      ],
    );

    final body = Padding(
      padding: framed
          ? const EdgeInsets.fromLTRB(12, 10, 12, 10)
          : EdgeInsets.zero,
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
                'first published.',
          ),
          _Step(
            number: 2,
            style: text,
            text:
                'The lead times are sorted into the 1–3, 4–7 and more than '
                "7 working day bands. Each band's percentage is its "
                'share of all those received in the period.',
          ),
          _Step(number: 3, style: text, text: 'The rating is as listed below:'),
          const SizedBox(height: 4),
          // Badge first, so the colour on the cards and in the table
          // finds its rule here at a glance. On a phone the badge sits
          // above its rule; beside it the rule would be a sliver.
          Padding(
            padding: const EdgeInsets.only(left: _Step.numberWidth),
            child: LayoutBuilder(
              builder: (context, constraints) =>
                  rulesColumn(constraints.maxWidth < _stackBelowWidth),
            ),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Note: ',
                  style: text?.copyWith(fontWeight: FontWeight.w600),
                ),
                const TextSpan(
                  text:
                      'The Received by VTM date is derived from the Confirmed '
                      'to Proceed date.',
                ),
              ],
            ),
            style: text?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );

    return framed ? ReportPanel(title: title, child: body) : body;
  }
}

/// One numbered sentence of the explanation.
class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text, this.style});

  final int number;
  final String text;
  final TextStyle? style;

  /// The column the step numbers sit in; the rules below indent to match.
  static const double numberWidth = 22;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
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
