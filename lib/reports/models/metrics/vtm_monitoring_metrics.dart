// lib/reports/models/metrics/vtm_monitoring_metrics.dart
//
// The figures behind the VTM Tender/Quotation Monitoring report: aging, the
// summary counts, and the exceptions worth chasing.
//
// Kept out of the widgets so the arithmetic can be read in one place and
// tested without building a page.
import 'package:etender_reports/reports/models/records/vtm_monitoring_record.dart';
import 'package:etender_reports/reports/models/status/vtm_monitoring_status.dart';

/// How long an Appendix F may sit before the report calls it slow.
///
/// Not from the blueprint: nothing there sets a limit on preparation. The
/// eRFC report uses the same idea with its own threshold.
const int kVtmSlowDays = 21;

/// Days from eRFC endorsement to today, or to the floating date once the
/// document is published.
///
/// Two different questions behind one number. For anything in flight it is
/// "how long has this been waiting", which has to count to today or it
/// stops meaning anything. For a published document it is "how long did
/// this take", which is fixed the moment it floats.
///
/// Null when there is no endorsement date to count from. Never negative.
int? vtmAgingDays(VtmMonitoringRecord record, {DateTime? asOf}) {
  final endorsed = record.endorsedDate;
  if (endorsed == null) return null;

  // A published record with no floating date is a data problem, not a
  // reason to show nothing: fall back to counting to today.
  final end = record.isPublished
      ? (record.floatingDate ?? asOf ?? DateTime.now())
      : (asOf ?? DateTime.now());

  final from = DateTime(endorsed.year, endorsed.month, endorsed.day);
  final to = DateTime(end.year, end.month, end.day);
  final days = to.difference(from).inDays;
  return days < 0 ? 0 : days;
}

/// Still moving and older than [kVtmSlowDays]. A published document is
/// never slow — it is finished, however long it took.
bool vtmIsSlow(VtmMonitoringRecord record, {DateTime? asOf}) {
  if (record.isPublished) return false;
  final days = vtmAgingDays(record, asOf: asOf);
  return days != null && days > kVtmSlowDays;
}

// ---- Summary -------------------------------------------------------------

int vtmCountWithStatus(List<VtmMonitoringRecord> records, VtmStatus status) =>
    records.where((r) => r.statusValue == status).length;

/// Sent back by either gate, and so waiting on the preparer.
int vtmRejectedCount(List<VtmMonitoringRecord> records) =>
    records.where((r) => r.isRejected).length;

/// Moving forward: neither rejected nor floated.
int vtmInProgressCount(List<VtmMonitoringRecord> records) =>
    records.where((r) => r.statusValue?.isInProgress ?? false).length;

int vtmPublishedCount(List<VtmMonitoringRecord> records) =>
    records.where((r) => r.isPublished).length;

int vtmSlowCount(List<VtmMonitoringRecord> records, {DateTime? asOf}) =>
    records.where((r) => vtmIsSlow(r, asOf: asOf)).length;

/// How long the documents that made it to floating actually took, on
/// average. Null when none have floated.
///
/// Published records only, deliberately: mixing in the ones still waiting
/// would report a lead time nobody has achieved.
double? vtmAveragePublishedAging(
  List<VtmMonitoringRecord> records, {
  DateTime? asOf,
}) {
  final completed = <int>[
    for (final record in records)
      if (record.isPublished) ?vtmAgingDays(record, asOf: asOf),
  ];
  if (completed.isEmpty) return null;
  return completed.reduce((a, b) => a + b) / completed.length;
}

/// Counts by document type, for the byDocumentType summary.
Map<String, int> vtmDocumentTypeCounts(List<VtmMonitoringRecord> records) {
  final counts = <String, int>{};
  for (final record in records) {
    counts[record.documentType] = (counts[record.documentType] ?? 0) + 1;
  }
  return counts;
}

// ---- Exceptions ----------------------------------------------------------

/// How loudly a finding asks to be dealt with.
enum VtmFlagSeverity { high, medium }

/// Something on one record that needs attention.
class VtmFlag {
  const VtmFlag({
    required this.record,
    required this.label,
    required this.severity,
    required this.detail,
  });

  final VtmMonitoringRecord record;
  final String label;
  final VtmFlagSeverity severity;

  /// Why this record tripped the flag, in the report's own words.
  final String detail;
}

/// Every finding across [records], highest severity first.
List<VtmFlag> vtmFlags(List<VtmMonitoringRecord> records, {DateTime? asOf}) {
  final flags = <VtmFlag>[];

  for (final record in records) {
    // Sent back, with nothing said about why. The remark is the whole
    // point of a rejection: without it the preparer cannot act.
    if (record.isRejectedWithoutReason) {
      flags.add(
        VtmFlag(
          record: record,
          label: 'Rejected with no reason given',
          severity: VtmFlagSeverity.high,
          detail: '${record.statusLabel} with no remarks for the preparer',
        ),
      );
    }

    // Waiting far longer than anything else in the set.
    if (vtmIsSlow(record, asOf: asOf)) {
      final days = vtmAgingDays(record, asOf: asOf) ?? 0;
      flags.add(
        VtmFlag(
          record: record,
          label: 'Sitting more than $kVtmSlowDays days',
          severity: record.isRejected
              ? VtmFlagSeverity.high
              : VtmFlagSeverity.medium,
          detail: record.isRejected
              ? 'Rejected and untouched for $days days'
              : '$days days since eRFC endorsement, still ${record.statusLabel}',
        ),
      );
    }

    // Approved but never floated. The one step left, and the document is
    // doing nothing until it is taken.
    if (record.statusValue == VtmStatus.approvedByManager) {
      final days = vtmAgingDays(record, asOf: asOf) ?? 0;
      flags.add(
        VtmFlag(
          record: record,
          label: 'Approved, not floated',
          severity: VtmFlagSeverity.medium,
          detail: 'Approved and waiting to be floated, $days days in',
        ),
      );
    }

    // A published document with no number, or a number with no float: both
    // mean the record and its own status disagree.
    if (record.isPublished && record.tenderQuotationNo == null) {
      flags.add(
        VtmFlag(
          record: record,
          label: 'Published with no tender number',
          severity: VtmFlagSeverity.medium,
          detail: 'Floated without a tender or quotation number assigned',
        ),
      );
    }
  }

  flags.sort((a, b) => a.severity.index.compareTo(b.severity.index));
  return flags;
}
