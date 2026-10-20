// lib/reports/procurement_lead_time/models/lead_time_query.dart
import 'package:equatable/equatable.dart';
import 'package:etender_reports/reports/procurement_lead_time/lead_time_rules.dart';
import 'package:etender_reports/reports/procurement_lead_time/models/period_preset.dart';
import 'package:etender_reports/reports/procurement_lead_time/services/period_resolver.dart';

export 'package:etender_reports/reports/procurement_lead_time/models/period_preset.dart';

/// The Mode of Procurement dropdown.
enum DocumentTypeFilter {
  tender('Tender', [DocumentType.tender]),
  quotation('Quotation', [DocumentType.quotation]),
  all('All', [DocumentType.tender, DocumentType.quotation]);

  const DocumentTypeFilter(this.label, this.types);

  final String label;

  /// The document types this choice covers, in the order their summaries
  /// are shown.
  final List<DocumentType> types;

  bool includes(DocumentType? type) => type != null && types.contains(type);

  /// How the result header names the selection.
  String get description => this == all ? 'Tender and Quotation' : label;
}

/// A search that has passed [validateLeadTimeDates]. Dates are published
/// dates, both ends inclusive.
class LeadTimeQuery extends Equatable {
  const LeadTimeQuery({
    required this.publishedFrom,
    required this.publishedTo,
    this.type = DocumentTypeFilter.tender,
    this.procurementMode,
    this.preset = PeriodPreset.custom,
  });

  /// [preset]'s dates as of [today]. Not for [PeriodPreset.custom], which
  /// has no dates of its own.
  factory LeadTimeQuery.forPreset(
    PeriodPreset preset, {
    required DateTime today,
    DocumentTypeFilter type = DocumentTypeFilter.tender,
    String? procurementMode,
  }) {
    final range = PeriodResolver.resolve(preset, today: today);
    if (range == null) {
      throw ArgumentError.value(preset, 'preset', 'has no dates of its own');
    }
    return LeadTimeQuery(
      publishedFrom: range.start,
      publishedTo: range.end,
      type: type,
      procurementMode: procurementMode,
      preset: preset,
    );
  }

  final DateTime publishedFrom;
  final DateTime publishedTo;
  final DocumentTypeFilter type;

  /// One mode's code, e.g. '7.2', or null for all of
  /// [LeadTimeRules.procurementModes].
  final String? procurementMode;

  /// How the result header names [procurementMode]; null for all modes.
  String? get procurementModeDescription {
    for (final mode in LeadTimeRules.procurementModes) {
      if (mode.code == procurementMode) return '${mode.code} ${mode.label}';
    }
    return procurementMode;
  }

  /// Which period produced the dates, for the result header. Custom when
  /// they were entered by hand.
  final PeriodPreset preset;

  @override
  List<Object?> get props => [
    publishedFrom,
    publishedTo,
    type,
    procurementMode,
    preset,
  ];
}

/// Inline messages for the two date fields; null where the field is fine.
typedef LeadTimeDateErrors = ({String? from, String? to});

/// Both dates are required and From must not be after To. Compared as
/// calendar dates, so the same day twice is a valid one-day search.
LeadTimeDateErrors validateLeadTimeDates(DateTime? from, DateTime? to) {
  String? fromError;
  String? toError;
  if (from == null) fromError = 'Published Date From is required';
  if (to == null) toError = 'Published Date To is required';
  if (from != null && to != null) {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    if (start.isAfter(end)) {
      toError = 'Published Date To must be on or after Published Date From';
    }
  }
  return (from: fromError, to: toError);
}

extension LeadTimeDateErrorsValid on LeadTimeDateErrors {
  bool get isValid => from == null && to == null;
}
