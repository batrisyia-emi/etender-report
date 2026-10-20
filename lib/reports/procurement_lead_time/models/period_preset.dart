// lib/reports/procurement_lead_time/models/period_preset.dart

/// The quick periods offered above the published date fields.
///
/// The dates each one covers are worked out by `PeriodResolver`; quarters
/// and year to date follow `LeadTimeRules.fyStartMonth`.
enum PeriodPreset {
  lastMonth('Last month'),
  thisMonth('This month', isToDate: true),
  lastQuarter('Last quarter'),
  thisQuarter('This quarter', isToDate: true),
  yearToDate('Year to date', isToDate: true),
  last12Months('Last 12 months'),

  /// Whatever dates the user entered by hand.
  custom('Custom');

  const PeriodPreset(this.label, {this.isToDate = false});

  final String label;

  /// True for a period still in progress, which runs only to today. Its
  /// figures will change as more tenders are published, so the result is
  /// flagged as not final.
  final bool isToDate;
}
