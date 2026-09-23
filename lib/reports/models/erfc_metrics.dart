// lib/reports/models/erfc_metrics.dart
import 'package:etender_reports/reports/models/erfc_status.dart';
import 'package:etender_reports/reports/models/record_matching.dart';

/// An in-flight RFC older than this is flagged overdue.
const int kErfcOverdueDays = 14;

// The wire forms of the groups on [ErfcStatus], for the record maps the
// app actually passes around. The enum is the source of truth; rename a
// status there and every one of these follows.
final Set<String> kErfcRejectedStatuses = ErfcStatus.wiresOf(
  ErfcStatus.rejected,
);
final Set<String> kErfcEndorsedStatuses = ErfcStatus.wiresOf(
  ErfcStatus.endorsedOrBeyond,
);
final Set<String> kErfcInFlightStatuses = ErfcStatus.wiresOf(
  ErfcStatus.inFlight,
);
final Set<String> kErfcTerminalStatuses = ErfcStatus.wiresOf(
  ErfcStatus.terminal,
);

bool erfcIsTerminal(Map<String, dynamic> record) =>
    kErfcTerminalStatuses.contains(record['status']?.toString());

/// Days since submission.
///
/// Still moving for an in-flight RFC. For a finished one it freezes at the
/// endorsement date, or at the verified date when the RFC was rejected,
/// declined or cancelled before endorsement.
int? erfcAgingDays(Map<String, dynamic> record, {DateTime? asOf}) {
  final submitted = parseRecordDate(record['submissionDate']);
  if (submitted == null) return null;

  final endorsed = parseRecordDate(record['endorsedDate']);
  // The latest verification reached, so a rejection after 2nd Verified
  // freezes at the later date rather than the first.
  final verified =
      parseRecordDate(record['verified2Date']) ??
      parseRecordDate(record['verified1Date']);
  final frozenAt = endorsed ?? (erfcIsTerminal(record) ? verified : null);
  final end = frozenAt ?? asOf ?? DateTime.now();

  final days = end.difference(submitted).inDays;
  return days < 0 ? 0 : days;
}

/// Only in-flight RFCs can be overdue: a rejected one is not waiting on
/// anybody, however old it is.
bool erfcIsOverdue(Map<String, dynamic> record, {DateTime? asOf}) {
  if (erfcIsTerminal(record)) return false;
  final aging = erfcAgingDays(record, asOf: asOf);
  return aging != null && aging > kErfcOverdueDays;
}

/// Submission to endorsement, averaged over endorsed RFCs only — the ones
/// that actually completed the cycle. Null when none have.
double? erfcAverageProcessingDays(List<Map<String, dynamic>> records) {
  final durations = <int>[];
  for (final record in records) {
    if (!kErfcEndorsedStatuses.contains(record['status']?.toString())) {
      continue;
    }
    final submitted = parseRecordDate(record['submissionDate']);
    final endorsed = parseRecordDate(record['endorsedDate']);
    if (submitted == null || endorsed == null) continue;
    durations.add(endorsed.difference(submitted).inDays);
  }
  if (durations.isEmpty) return null;
  return durations.reduce((a, b) => a + b) / durations.length;
}

/// Same measure, split by division, for the management summary.
Map<String, double> erfcAverageProcessingDaysByDivision(
  List<Map<String, dynamic>> records,
) {
  final grouped = <String, List<int>>{};
  for (final record in records) {
    if (!kErfcEndorsedStatuses.contains(record['status']?.toString())) {
      continue;
    }
    final submitted = parseRecordDate(record['submissionDate']);
    final endorsed = parseRecordDate(record['endorsedDate']);
    if (submitted == null || endorsed == null) continue;
    final division = record['division']?.toString() ?? 'Unknown';
    grouped
        .putIfAbsent(division, () => <int>[])
        .add(endorsed.difference(submitted).inDays);
  }

  return {
    for (final entry in grouped.entries)
      entry.key: entry.value.reduce((a, b) => a + b) / entry.value.length,
  };
}

/// Ringgit value sitting in the RFC pipeline.
double erfcPipelineValue(List<Map<String, dynamic>> records) => records.fold(
  0,
  (total, record) =>
      total + (double.tryParse(record['value']?.toString() ?? '') ?? 0),
);

int erfcCountWithStatus(
  List<Map<String, dynamic>> records,
  Set<String> statuses,
) => records.where((r) => statuses.contains(r['status']?.toString())).length;

/// Age of the oldest RFC still waiting on someone.
int? erfcOldestInFlightDays(
  List<Map<String, dynamic>> records, {
  DateTime? asOf,
}) {
  final ages = records
      .where((record) => !erfcIsTerminal(record))
      .map((record) => erfcAgingDays(record, asOf: asOf))
      .whereType<int>()
      .toList();
  if (ages.isEmpty) return null;
  return ages.reduce((a, b) => a > b ? a : b);
}
