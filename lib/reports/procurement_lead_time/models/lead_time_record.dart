// lib/reports/procurement_lead_time/models/lead_time_record.dart
import 'package:equatable/equatable.dart';
import 'package:etender_reports/reports/procurement_lead_time/lead_time_rules.dart';

/// One published tender or quotation as the repository supplies it: the two
/// timestamps the lead time runs between, plus what identifies it.
///
/// Working days are not part of this. They depend on the holiday table, so
/// [LeadTimeService] works them out and wraps the record in a
/// [MeasuredLeadTime].
class LeadTimeRecord extends Equatable {
  const LeadTimeRecord({
    required this.tenderNo,
    required this.projectTitle,
    required this.procurementMode,
    required this.erfcNo,
    required this.division,
    required this.vtmReceivedDate,
    required this.publishedDate,
  });

  /// For a source that sends every 'Published' timestamp (VTM Process 1.6).
  /// Only the first counts as the published date: re-publishing after an
  /// addendum does not restart or extend the lead time.
  factory LeadTimeRecord.fromPublishHistory({
    required String tenderNo,
    required String projectTitle,
    required String procurementMode,
    required String erfcNo,
    required String division,
    required DateTime vtmReceivedDate,
    required Iterable<DateTime> publishedDates,
  }) {
    if (publishedDates.isEmpty) {
      throw ArgumentError.value(
        publishedDates,
        'publishedDates',
        '$tenderNo has never been published, so it has no published date',
      );
    }
    return LeadTimeRecord(
      tenderNo: tenderNo,
      projectTitle: projectTitle,
      procurementMode: procurementMode,
      erfcNo: erfcNo,
      division: division,
      vtmReceivedDate: vtmReceivedDate,
      publishedDate: publishedDates.reduce((a, b) => a.isBefore(b) ? a : b),
    );
  }

  final String tenderNo;

  /// eRFC Section B-1.
  final String projectTitle;

  /// e.g. '7.1'.
  final String procurementMode;
  final String erfcNo;
  final String division;

  /// When the Requestor clicked 'Confirm to Proceed' (eRFC Decision D).
  final DateTime vtmReceivedDate;

  /// The first 'Published' timestamp.
  final DateTime publishedDate;

  /// From the number prefix; null when the prefix is not recognised.
  DocumentType? get documentType => LeadTimeRules.documentTypeFor(tenderNo);

  @override
  List<Object?> get props => [
    tenderNo,
    projectTitle,
    procurementMode,
    erfcNo,
    division,
    vtmReceivedDate,
    publishedDate,
  ];
}

/// A record with its lead time worked out.
class MeasuredLeadTime extends Equatable {
  const MeasuredLeadTime({
    required this.record,
    required this.documentType,
    required this.workingDays,
  });

  final LeadTimeRecord record;
  final DocumentType documentType;
  final int workingDays;

  LeadTimeBucket get bucket => LeadTimeRules.bucketFor(workingDays);

  @override
  List<Object?> get props => [record, documentType, workingDays];
}
