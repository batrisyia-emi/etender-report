// lib/reports/widgets/erfc/erfc_processing_time_panel.dart
import 'package:etender_reports/shared/app_colors.dart';
import 'package:flutter/material.dart';

import 'package:etender_reports/reports/models/erfc_metrics.dart';
import 'package:etender_reports/reports/widgets/shared/report_panel.dart';

/// Average processing time by division — report spec 6.2, Aging Metrics.
///
/// Measures submission to endorsement over endorsed RFCs only, so a division
/// with nothing endorsed yet shows as "no completed RFCs" rather than as a
/// misleading zero.
class ErfcProcessingTimePanel extends StatelessWidget {
  const ErfcProcessingTimePanel({super.key, required this.records});

  final List<Map<String, dynamic>> records;

  /// Bars are drawn relative to the slowest division, not to an absolute
  /// scale, so the comparison stays readable whatever the numbers are.
  static const double _barHeight = 8;

  @override
  Widget build(BuildContext context) {
    final averages = erfcAverageProcessingDaysByDivision(records);

    // Endorsed RFCs per division, so a 4-day average from one RFC is not
    // read as confidently as one from twenty.
    final counts = <String, int>{};
    for (final record in records) {
      if (!kErfcEndorsedStatuses.contains(record['status']?.toString())) {
        continue;
      }
      final division = record['division']?.toString() ?? 'Unknown';
      counts[division] = (counts[division] ?? 0) + 1;
    }

    final divisions = averages.keys.toList()
      ..sort((a, b) => averages[b]!.compareTo(averages[a]!));
    final slowest = divisions.isEmpty ? 0.0 : averages[divisions.first]!;

    final overall = erfcAverageProcessingDays(records);

    return ReportPanel(
      title: 'Average Processing Time by Division',
      trailing: Text(
        overall == null
            ? 'No endorsed RFCs'
            : 'Overall ${overall.toStringAsFixed(1)} days',
        style: const TextStyle(
          color: AppColors.accent,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: divisions.isEmpty
            ? const Text(
                'No RFCs in the current selection have been endorsed, so '
                'there is nothing to average yet.',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final division in divisions)
                    _DivisionRow(
                      division: division,
                      days: averages[division]!,
                      endorsedCount: counts[division] ?? 0,
                      fraction: slowest <= 0
                          ? 0
                          : averages[division]! / slowest,
                      barHeight: _barHeight,
                    ),
                ],
              ),
      ),
    );
  }
}

class _DivisionRow extends StatelessWidget {
  const _DivisionRow({
    required this.division,
    required this.days,
    required this.endorsedCount,
    required this.fraction,
    required this.barHeight,
  });

  final String division;
  final double days;
  final int endorsedCount;
  final double fraction;
  final double barHeight;

  /// Green up to a week, amber to a fortnight, red beyond.
  Color get _barColour {
    if (days <= 7) return const Color(0xFF15803D);
    if (days <= 14) return const Color(0xFFB45309);
    return const Color(0xFFB91C1C);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 170,
            child: Text(
              division,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.heading,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(height: barHeight, color: AppColors.fill),
                  FractionallySizedBox(
                    widthFactor: fraction.clamp(0.02, 1),
                    child: Container(height: barHeight, color: _barColour),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 74,
            child: Text(
              '${days.toStringAsFixed(1)} days',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: _barColour,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 78,
            child: Text(
              endorsedCount == 1 ? '1 RFC' : '$endorsedCount RFCs',
              textAlign: TextAlign.right,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
