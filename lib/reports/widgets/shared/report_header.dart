// lib/reports/widgets/shared/report_header.dart
//
// One band at the top of every report: what it is, what was asked for, and
// how much answered.
//
// Deliberately one or two lines. The first version gave this 198px — a
// title strip, a repeated issuer line, and three labelled rows — above a
// filter panel that already takes height before any data appears. A report
// header earns its space by carrying the criteria, not by being a cover
// page, so everything that was not a fact got cut.
import 'package:etender_reports/reports/models/filters/report_criteria.dart';
import 'package:etender_reports/shared/app_colors.dart';
import 'package:etender_reports/shared/utils/formatters.dart';
import 'package:flutter/material.dart';

class ReportHeader extends StatelessWidget {
  const ReportHeader({
    super.key,
    required this.title,
    required this.criteria,
    required this.shownCount,
    required this.totalCount,
    this.unit = 'records',
    this.generatedAt,
  });

  final String title;

  /// The filters in force, already reduced to the ones actually set.
  final List<ReportCriterion> criteria;

  /// Rows after filtering, and rows the report holds in total.
  final int shownCount;
  final int totalCount;

  /// What a row is called, e.g. 'tenders', 'openings', 'documents'.
  final String unit;

  /// Defaults to now. Injectable so a test can pin it.
  final DateTime? generatedAt;

  /// "18 of 42 tenders" only when some were excluded; otherwise "42
  /// tenders", because "42 of 42" makes a reader look for the difference.
  String get _countText => shownCount == totalCount
      ? '$totalCount $unit'
      : '$shownCount of $totalCount $unit';

  @override
  Widget build(BuildContext context) {
    final generated = generatedAt ?? DateTime.now();
    final filtered = criteria.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title left, the two facts about this run right. Wraps rather
          // than ellipsising, so the count is never the thing that is lost.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 4,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.heading,
                ),
              ),
              Text(
                '$_countText  ·  ${formatLastUpdate(generated.toIso8601String())}',
                style: TextStyle(
                  fontSize: 11.5,
                  color: shownCount == 0 && totalCount > 0
                      ? Colors.orange.shade900
                      : AppColors.muted,
                ),
              ),
            ],
          ),
          if (filtered) ...[
            const SizedBox(height: 8),
            _CriteriaChips(criteria: criteria),
          ],
          // Only when the filters are the reason there is nothing to see.
          // An empty table cannot tell "no data" from "filtered to nothing".
          if (shownCount == 0 && totalCount > 0) ...[
            const SizedBox(height: 6),
            Text(
              'No record matches these criteria.',
              style: TextStyle(fontSize: 11.5, color: Colors.orange.shade900),
            ),
          ],
        ],
      ),
    );
  }
}

/// Each criterion as a chip, so a long list wraps instead of running off.
class _CriteriaChips extends StatelessWidget {
  const _CriteriaChips({required this.criteria});

  final List<ReportCriterion> criteria;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final criterion in criteria)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.fill,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(4),
            ),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 11, color: AppColors.heading),
                children: [
                  TextSpan(
                    text: '${criterion.label}: ',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  TextSpan(
                    text: criterion.value,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
