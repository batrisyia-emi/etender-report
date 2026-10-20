// lib/reports/procurement_lead_time/lead_time_rules.dart
//
// Every business rule the Procurement Lead Time report depends on, in one
// place. The calculator, the service and the widgets read from here and
// never repeat a number of their own, so a ruling from SE is a one-line
// change.
import 'package:etender_reports/reports/models/status/vtm_monitoring_status.dart';
import 'package:etender_reports/reports/procurement_lead_time/models/period_preset.dart';

/// Tender or Quotation, as the report splits them.
enum DocumentType {
  tender('Tender'),
  quotation('Quotation');

  const DocumentType(this.label);

  final String label;
}

/// One lead-time band, measured in working days. [max] is null for the
/// open-ended last band.
class LeadTimeBucket {
  const LeadTimeBucket({
    required this.key,
    required this.label,
    required this.min,
    this.max,
  });

  final String key;
  final String label;
  final int min;
  final int? max;

  bool contains(int workingDays) =>
      workingDays >= min && (max == null || workingDays <= max!);

  @override
  String toString() => label;
}

/// Excellent / Good / Below Expectations.
enum PerformanceRating {
  excellent('Excellent'),
  good('Good'),
  belowExpectations('Below Expectations');

  const PerformanceRating(this.label);

  final String label;
}

class LeadTimeRules {
  const LeadTimeRules._();

  /// The modes this report measures, and offers as Mode of Procurement:
  /// the five open-tender modes, whose eRFC Decision D ("Confirm to
  /// Proceed") starts the clock. The other eleven in Appendix A section 7
  /// are never published, so they have no published date and are left out.
  ///
  /// The same five the VTM Monitoring report covers, for the same reason,
  /// so both read from one definition: codes and labels as the form
  /// lists them (7.1 Tender/Quotation … 7.6 Schedule Rate/JHT).
  static const List<VtmProcurementMode> procurementModes =
      VtmProcurementMode.values;

  /// [procurementModes] by code, e.g. '7.1'.
  static final Set<String> openTenderModes = {
    for (final mode in procurementModes) mode.code,
  };

  static const LeadTimeBucket workingDays1To3 = LeadTimeBucket(
    key: 'working_days_1_3',
    label: '1–3 working days',
    min: 1,
    max: 3,
  );
  static const LeadTimeBucket workingDays4To7 = LeadTimeBucket(
    key: 'working_days_4_7',
    label: '4–7 working days',
    min: 4,
    max: 7,
  );
  static const LeadTimeBucket workingDaysOver7 = LeadTimeBucket(
    key: 'working_days_over_7',
    label: 'More than 7 working days',
    min: 8,
  );

  /// In column order.
  static const List<LeadTimeBucket> buckets = [
    workingDays1To3,
    workingDays4To7,
    workingDaysOver7,
  ];

  /// The band [workingDays] falls in.
  ///
  /// Zero lands in the first band. It happens when a tender is received and
  /// published on the same non-working day: Day 1 would be the next working
  /// day, which the publication has already beaten. That is the fastest
  /// possible outcome, not a missing one.
  static LeadTimeBucket bucketFor(int workingDays) {
    if (workingDays < workingDays1To3.min) return workingDays1To3;
    return buckets.firstWhere((bucket) => bucket.contains(workingDays));
  }

  // ---- Performance rating ---------------------------------------------
  //
  // PENDING SE CONFIRMATION: thresholds as proposed, not yet agreed.

  /// Excellent when at least this share is published within 3 working
  /// days.
  static const double excellentWithin3WorkingDaysPercent = 95;

  /// Good when at least this share is published within 7 working days
  /// (the 1–3 and 4–7 bands together).
  static const double goodWithin7WorkingDaysPercent = 90;

  /// Rated on the counts, not on the rounded percentages, so 94.996% is not
  /// promoted to Excellent by its own display rounding.
  static PerformanceRating rate({
    required int within3WorkingDays,
    required int within7WorkingDays,
    required int total,
  }) {
    if (total == 0) return PerformanceRating.belowExpectations;
    if (within3WorkingDays * 100 >=
        excellentWithin3WorkingDaysPercent * total) {
      return PerformanceRating.excellent;
    }
    if (within7WorkingDays * 100 >= goodWithin7WorkingDaysPercent * total) {
      return PerformanceRating.good;
    }
    return PerformanceRating.belowExpectations;
  }

  // ---- Reporting period -----------------------------------------------

  /// The month the financial year starts (1 = January). Quarters and Year
  /// to date count from here: 4 makes Q1 April–June and the year start on
  /// 1 April.
  ///
  /// PENDING SE CONFIRMATION.
  static const int fyStartMonth = 1;

  /// What the report opens on, already searched.
  static const PeriodPreset defaultPeriod = PeriodPreset.lastMonth;

  // ---- Document type --------------------------------------------------
  //
  // From the Tender/Quotation number prefix (Appendix F items 23/24).
  // PENDING SE CONFIRMATION: Zone Quotations (Z.) are counted as Quotations
  // for now. Moving them is a change to this map only.

  static const Map<String, DocumentType> documentTypeByPrefix = {
    'T.': DocumentType.tender,
    'Q.': DocumentType.quotation,
    'Z.': DocumentType.quotation,
  };

  /// Null for a number with no recognised prefix.
  static DocumentType? documentTypeFor(String tenderNo) {
    final number = tenderNo.trim().toUpperCase();
    for (final MapEntry(key: prefix, value: type)
        in documentTypeByPrefix.entries) {
      if (number.startsWith(prefix)) return type;
    }
    return null;
  }
}
