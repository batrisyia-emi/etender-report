// lib/reports/procurement_lead_time/models/lead_time_summary.dart
import 'package:equatable/equatable.dart';
import 'package:etender_reports/reports/procurement_lead_time/lead_time_rules.dart';
import 'package:etender_reports/reports/procurement_lead_time/models/lead_time_record.dart';

/// The summary table, KPI cards and drill-down rows for one document type.
class LeadTimeSummary extends Equatable {
  const LeadTimeSummary({
    required this.documentType,
    required this.items,
    required this.counts,
    required this.percentages,
    required this.rating,
  });

  final DocumentType documentType;

  /// Every measured record of this type, slowest first.
  final List<MeasuredLeadTime> items;

  /// Keyed by [LeadTimeBucket.key]; every bucket is present.
  final Map<String, int> counts;

  /// Keyed by [LeadTimeBucket.key], already rounded to two decimals. They
  /// add up to exactly 100.00 when there is anything to count, and are all
  /// 0.00 when there is not.
  final Map<String, double> percentages;

  final PerformanceRating rating;

  int get total => items.length;

  int countIn(LeadTimeBucket bucket) => counts[bucket.key] ?? 0;

  double percentIn(LeadTimeBucket bucket) => percentages[bucket.key] ?? 0;

  double get totalPercent => total == 0 ? 0 : 100;

  double get within3WorkingDaysPercent =>
      percentIn(LeadTimeRules.workingDays1To3);

  /// The two rounded band percentages added, so the card always agrees with
  /// the table.
  double get within7WorkingDaysPercent => _round2(
    percentIn(LeadTimeRules.workingDays1To3) +
        percentIn(LeadTimeRules.workingDays4To7),
  );

  /// Slowest first, as the drill-down lists them.
  List<MeasuredLeadTime> itemsIn(LeadTimeBucket bucket) => [
    for (final item in items)
      if (item.bucket.key == bucket.key) item,
  ];

  static double _round2(double value) => (value * 100).round() / 100;

  @override
  List<Object?> get props => [documentType, items, counts, percentages, rating];
}
