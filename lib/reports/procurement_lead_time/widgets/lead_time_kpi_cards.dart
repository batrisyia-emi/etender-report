// lib/reports/procurement_lead_time/widgets/lead_time_kpi_cards.dart
import 'package:etender_reports/reports/procurement_lead_time/lead_time_rules.dart';
import 'package:etender_reports/reports/procurement_lead_time/models/lead_time_summary.dart';
import 'package:etender_reports/reports/procurement_lead_time/widgets/lead_time_rating_badge.dart';
import 'package:etender_reports/reports/widgets/shared/kpi_card.dart';
import 'package:etender_reports/reports/widgets/shared/status_chip.dart';
import 'package:flutter/material.dart';

/// Within 3 working days, Within 7 working days and the performance
/// rating, for one summary.
class LeadTimeKpiCards extends StatelessWidget {
  const LeadTimeKpiCards({
    super.key,
    required this.summary,
    this.stacked = false,
  });

  final LeadTimeSummary summary;

  /// One card above another, rating last, for a column beside the rating
  /// explanation, sharing out whatever height that column has. Otherwise
  /// all three share a row.
  final bool stacked;

  static const double _cardWidth = 220;
  static const double _cardSpacing = 12;

  static String _target(PerformanceRating rating) {
    final excellent = LeadTimeRules.excellentWithin3WorkingDaysPercent
        .toStringAsFixed(0);
    final good = LeadTimeRules.goodWithin7WorkingDaysPercent.toStringAsFixed(0);
    return switch (rating) {
      PerformanceRating.excellent => '≥ $excellent% within 3 working days',
      PerformanceRating.good => '≥ $good% within 7 working days',
      PerformanceRating.belowExpectations => '< $good% within 7 working days',
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rating = summary.rating;
    final badge = LeadTimeRatingBadge.colorsFor(scheme, rating);
    final empty = summary.total == 0;
    final within3 = summary.countIn(LeadTimeRules.workingDays1To3);
    final within7 = within3 + summary.countIn(LeadTimeRules.workingDays4To7);

    final cards = [
      KpiCard(
        header: 'WITHIN 3 WORKING DAYS (%)',
        value: summary.within3WorkingDaysPercent.toStringAsFixed(2),
        icon: Icons.bolt_outlined,
        iconTint: scheme.primaryContainer,
        iconColor: scheme.onPrimaryContainer,
        footer: KpiFooterText(
          '$within3 of ${summary.total} published in 1–3 working days',
        ),
      ),
      KpiCard(
        header: 'WITHIN 7 WORKING DAYS (%)',
        value: summary.within7WorkingDaysPercent.toStringAsFixed(2),
        icon: Icons.schedule_outlined,
        iconTint: scheme.secondaryContainer,
        iconColor: scheme.onSecondaryContainer,
        footer: KpiFooterText(
          '$within7 of ${summary.total} published in 1–7 working days',
        ),
      ),
      KpiCard(
        header: 'PERFORMANCE RATING',
        value: empty ? '—' : rating.label,
        icon: Icons.emoji_events_outlined,
        iconTint: badge.background,
        iconColor: badge.text,
        footer: empty
            ? const KpiFooterText('Nothing published to rate')
            : Align(
                alignment: Alignment.centerLeft,
                // Thresholds are pending SE confirmation; the badge shows
                // which one this result met so the rating can be checked.
                child: StatusChip(label: _target(rating), colors: badge),
              ),
      ),
    ];

    // Each card takes an equal share of the height it is given, so the
    // column ends level with whatever sits beside it. It must be given a
    // height: LeadTimeSummarySection wraps it in an IntrinsicHeight.
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < cards.length; index++) ...[
            if (index > 0) const SizedBox(height: _cardSpacing),
            Expanded(child: cards[index]),
          ],
        ],
      );
    }

    // All three in a row, or one per row: never two and then one beside
    // an empty slot.
    return LayoutBuilder(
      builder: (context, constraints) {
        final fitsInOneRow =
            constraints.maxWidth >=
            _cardWidth * cards.length + _cardSpacing * (cards.length - 1);
        return KpiCardRow(
          spacing: _cardSpacing,
          minCardWidth: fitsInOneRow ? _cardWidth : constraints.maxWidth,
          cards: cards,
        );
      },
    );
  }
}
