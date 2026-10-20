// lib/reports/procurement_lead_time/services/lead_time_service.dart
import 'package:etender_reports/reports/procurement_lead_time/lead_time_rules.dart';
import 'package:etender_reports/reports/procurement_lead_time/models/lead_time_record.dart';
import 'package:etender_reports/reports/procurement_lead_time/models/lead_time_summary.dart';
import 'package:etender_reports/reports/procurement_lead_time/services/working_day_calculator.dart';

/// Turns repository records into the report's numbers. Pure: no I/O, no
/// widgets, so every rule here is unit-testable.
class LeadTimeService {
  const LeadTimeService(this._calculator);

  final WorkingDayCalculator _calculator;

  /// Works out each record's working days.
  ///
  /// Drops records outside the open-tender modes, which have no VTM
  /// received date in the report's sense, and records whose number carries
  /// no recognised Tender/Quotation prefix.
  List<MeasuredLeadTime> measure(Iterable<LeadTimeRecord> records) {
    return [
      for (final record in records)
        if (LeadTimeRules.openTenderModes.contains(record.procurementMode))
          if (record.documentType case final type?)
            MeasuredLeadTime(
              record: record,
              documentType: type,
              workingDays: _calculator.count(
                record.vtmReceivedDate,
                record.publishedDate,
              ),
            ),
    ];
  }

  /// The summary for [type], from records already measured.
  static LeadTimeSummary summarise(
    DocumentType type,
    Iterable<MeasuredLeadTime> measured,
  ) {
    final items = [
      for (final item in measured)
        if (item.documentType == type) item,
    ]..sort(_slowestFirst);

    final counts = {
      for (final bucket in LeadTimeRules.buckets)
        bucket.key: items.where((item) => item.bucket.key == bucket.key).length,
    };

    final within3 = counts[LeadTimeRules.workingDays1To3.key]!;
    final within7 = within3 + counts[LeadTimeRules.workingDays4To7.key]!;

    return LeadTimeSummary(
      documentType: type,
      items: items,
      counts: counts,
      percentages: percentagesOf(counts, items.length),
      rating: LeadTimeRules.rate(
        within3WorkingDays: within3,
        within7WorkingDays: within7,
        total: items.length,
      ),
    );
  }

  /// Each count as a share of [total], to two decimals, adding up to
  /// exactly 100.00.
  ///
  /// Rounding each share on its own would not: three equal bands come out
  /// 33.33 × 3 = 99.99. So this works in hundredths of a percent, floors
  /// every share, and hands the hundredths left over to the shares with
  /// the largest remainders (largest remainder method). All 0.00 when
  /// [total] is 0.
  static Map<String, double> percentagesOf(Map<String, int> counts, int total) {
    if (total == 0) return {for (final key in counts.keys) key: 0};

    const scale = 10000; // 100% in hundredths of a percent
    final floors = {
      for (final MapEntry(:key, :value) in counts.entries)
        key: value * scale ~/ total,
    };
    final remainders = {
      for (final MapEntry(:key, :value) in counts.entries)
        key: value * scale % total,
    };

    var leftOver = scale - floors.values.fold(0, (sum, v) => sum + v);
    // Stable sort, so ties go to the earlier band.
    final byRemainder = counts.keys.toList()
      ..sort((a, b) => remainders[b]!.compareTo(remainders[a]!));
    for (final key in byRemainder) {
      if (leftOver == 0) break;
      floors[key] = floors[key]! + 1;
      leftOver--;
    }

    return {
      for (final MapEntry(:key, :value) in floors.entries) key: value / 100,
    };
  }

  /// Working days descending; ties by tender number, so the order is
  /// stable between searches.
  static int _slowestFirst(MeasuredLeadTime a, MeasuredLeadTime b) {
    final byDays = b.workingDays.compareTo(a.workingDays);
    return byDays != 0
        ? byDays
        : a.record.tenderNo.compareTo(b.record.tenderNo);
  }
}
