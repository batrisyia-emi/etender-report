// lib/reports/procurement_lead_time/widgets/lead_time_rating_badge.dart
import 'package:etender_reports/reports/procurement_lead_time/lead_time_rules.dart';
import 'package:etender_reports/reports/widgets/shared/status_chip.dart';
import 'package:flutter/material.dart';

/// A performance rating as a badge. The card, the summary table and the
/// result header all draw it through here, so a rating is the same colour
/// wherever it appears.
class LeadTimeRatingBadge extends StatelessWidget {
  const LeadTimeRatingBadge({super.key, required this.rating, this.label});

  final PerformanceRating rating;

  /// Defaults to the rating's own name, e.g. 'Good'.
  final String? label;

  /// Badge colours, all from the theme's colour scheme.
  static ChipColors colorsFor(ColorScheme scheme, PerformanceRating rating) =>
      switch (rating) {
        PerformanceRating.excellent => (
          text: scheme.onPrimary,
          background: scheme.primary,
        ),
        PerformanceRating.good => (
          text: scheme.onPrimaryContainer,
          background: scheme.primaryContainer,
        ),
        PerformanceRating.belowExpectations => (
          text: scheme.onErrorContainer,
          background: scheme.errorContainer,
        ),
      };

  @override
  Widget build(BuildContext context) {
    return StatusChip(
      label: label ?? rating.label,
      colors: colorsFor(Theme.of(context).colorScheme, rating),
    );
  }
}
