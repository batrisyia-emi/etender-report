// lib/reports/models/toc_metrics.dart
//
// The figures behind the TOC report: the derived status, aging, the
// summary counts, the exception flags and the committee workload.
//
// Kept out of the widgets so the arithmetic can be read in one place and
// tested without building a page.
import 'package:etender_reports/reports/models/records/toc_opening_record.dart';
import 'package:etender_reports/reports/models/toc_status.dart';

/// How close to its closing date a tender has to be before an absent
/// committee is flagged. The blueprint does not set one — see the open
/// question in docs/toc-report.md.
const int kTocClosingSoonDays = 3;

/// How long after Appendix G the closing Appendix P is expected.
const int kTocAppendixPDueDays = 1;

/// The status the server sent, or null when it sent something this app
/// does not recognise.
///
/// A thin wrapper, kept so callers read the same way they did when this was
/// derived. The report no longer computes the stage: see [TocStatus].
TocStatus? tocStatusOf(TocOpeningRecord record) => record.statusValue;

/// Days from closing to Appendix P, or to [asOf] while it is still open.
///
/// Null when there is no closing date to count from. Never negative: a
/// record closed in the future has not started ageing.
int? tocAgingDays(TocOpeningRecord record, {DateTime? asOf}) {
  final closing = record.closingDateTime;
  if (closing == null) return null;

  final end = record.appendixPSubmittedAt ?? asOf ?? DateTime.now();
  final days = end.difference(closing).inDays;
  return days < 0 ? 0 : days;
}

// ---- Summary cards -------------------------------------------------------

int tocCountWithStatus(List<TocOpeningRecord> records, TocStatus status) =>
    records.where((r) => r.statusValue == status).length;

/// How many are in any of [statuses] — the grouped summary cards.
int tocCountWithStatuses(
  List<TocOpeningRecord> records,
  Set<TocStatus> statuses,
) => records.where((r) => statuses.contains(r.statusValue)).length;

/// Openings whose status cannot occur under their envelope arrangement.
int tocEnvelopeMismatchCount(List<TocOpeningRecord> records) =>
    records.where((r) => r.hasEnvelopeMismatch).length;

/// Openings closed out with Appendix P.
///
/// Counted from the record rather than from the status, because the status
/// stops at committee readiness and says nothing about the opening day.
int tocClosedOutCount(List<TocOpeningRecord> records) =>
    records.where((r) => r.appendixPSubmittedAt != null).length;

/// Mean aging over the openings that actually finished the cycle. Null when
/// none have.
double? tocAverageAging(List<TocOpeningRecord> records, {DateTime? asOf}) {
  final closedOut = <int>[
    for (final record in records)
      if (record.appendixPSubmittedAt != null)
        ?tocAgingDays(record, asOf: asOf),
  ];
  if (closedOut.isEmpty) return null;
  return closedOut.reduce((a, b) => a + b) / closedOut.length;
}

// ---- Exception flags -----------------------------------------------------

/// "1 day" rather than "1 days".
String _days(int count) => count == 1 ? '1 day' : '$count days';

/// How loudly a flag asks to be dealt with.
enum TocFlagSeverity { high, medium }

/// What to do about a flag.
///
/// A flag that says only what is wrong leaves the reader to work out where
/// to go next, so each one names its remedy and the panel puts a button on
/// it. Each value maps to one method on `ReportActions`.
enum TocRemedy {
  /// Name three members — or a fresh three, after an extension cleared the
  /// last set.
  appointCommittee(label: 'Appoint committee'),

  /// Begin the opening session for a tender whose day has come.
  startOpening(label: 'Start opening'),

  /// Nothing specific to do from here — open the record and look.
  openRecord(label: 'Open record'),

  /// File the Appendix P that closes out the opening day.
  fileAppendixP(label: 'File Appendix P');

  const TocRemedy({required this.label});

  /// What the button says.
  final String label;
}

/// Something that needs attention on one record.
class TocExceptionFlag {
  const TocExceptionFlag({
    required this.record,
    required this.label,
    required this.severity,
    required this.detail,
    required this.remedy,
  });

  final TocOpeningRecord record;
  final String label;
  final TocFlagSeverity severity;

  /// The one thing that clears this flag.
  final TocRemedy remedy;

  /// Why this record tripped the flag, in the report's own words.
  final String detail;
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Every flag raised across [records], highest severity first.
List<TocExceptionFlag> tocExceptionFlags(
  List<TocOpeningRecord> records, {
  DateTime? asOf,
}) {
  final now = asOf ?? DateTime.now();
  final flags = <TocExceptionFlag>[];

  for (final record in records) {
    final status = record.statusValue;
    final closing = record.closingDateTime;

    // Still open for bidding with the closing date almost here and nobody
    // named to open it.
    if (status == TocStatus.open && closing != null) {
      final daysToClosing = closing.difference(now).inDays;
      if (daysToClosing >= 0 && daysToClosing <= kTocClosingSoonDays) {
        flags.add(
          TocExceptionFlag(
            record: record,
            label: 'No committee, closing soon',
            severity: TocFlagSeverity.high,
            remedy: TocRemedy.appointCommittee,
            detail: daysToClosing == 0
                ? 'Closes today with no committee appointed'
                : 'Closes in ${_days(daysToClosing)} with no committee '
                      'appointed',
          ),
        );
      }
    }

    // Opening day is here and the opening has not started.
    final opening = record.openingDateTime;
    if (opening != null &&
        _isSameDay(opening, now) &&
        (status == TocStatus.open || status == TocStatus.committeeAppointed)) {
      flags.add(
        TocExceptionFlag(
          record: record,
          label: 'Opening day, not started',
          severity: TocFlagSeverity.high,
          remedy: record.hasCommittee
              ? TocRemedy.startOpening
              : TocRemedy.appointCommittee,
          detail: record.hasCommittee
              ? 'Committee is named but the opening has not begun'
              : 'Opens today with no committee appointed',
        ),
      );
    }

    // The server sent a stage this tender's envelope arrangement cannot
    // reach — a two-envelope stage on a one-envelope tender, or the
    // reverse. Shown rather than corrected: the disagreement is the
    // finding.
    if (record.hasEnvelopeMismatch) {
      flags.add(
        TocExceptionFlag(
          record: record,
          label: 'Status does not match envelope type',
          severity: TocFlagSeverity.medium,
          remedy: TocRemedy.openRecord,
          detail:
              '"${record.status}" cannot happen on a '
              '${record.envelopeType.toLowerCase()} tender',
        ),
      );
    }

    // An extension wiped the committee and nobody has re-appointed one.
    if (record.isExtended && record.committee.isEmpty) {
      flags.add(
        TocExceptionFlag(
          record: record,
          label: 'Committee cleared by extension',
          severity: TocFlagSeverity.medium,
          remedy: TocRemedy.appointCommittee,
          detail: 'Extended after appointment; a new committee is needed',
        ),
      );
    }

    // Appendix G in, Appendix P still outstanding.
    //
    // Not while a two-envelope tender is still holding its commercial
    // envelope: Appendix P closes the opening day, and that day is not over
    // until the commercial envelope has been opened. Appendix G goes in at
    // the technical opening, so without this the report would chase a
    // closing document for an opening still in progress.
    final awaitingCommercial =
        status == TocStatus.technicalOpened ||
        status == TocStatus.commercialSealed;
    final appendixG = record.appendixGSubmittedAt;
    if (appendixG != null &&
        record.appendixPSubmittedAt == null &&
        !awaitingCommercial) {
      final since = now.difference(appendixG).inDays;
      if (since > kTocAppendixPDueDays) {
        flags.add(
          TocExceptionFlag(
            record: record,
            label: 'Appendix P overdue',
            severity: TocFlagSeverity.medium,
            remedy: TocRemedy.fileAppendixP,
            detail: 'Appendix G submitted ${_days(since)} ago',
          ),
        );
      }
    }
  }

  flags.sort((a, b) => a.severity.index.compareTo(b.severity.index));
  return flags;
}

// ---- Committee workload --------------------------------------------------

/// One person's load across every committee they sit on.
///
/// The blueprint places no limit on how many committees a person may join,
/// which is exactly why this is worth showing.
class TocMemberWorkload {
  const TocMemberWorkload({
    required this.staffId,
    required this.name,
    required this.department,
    required this.division,
    required this.asChairman,
    required this.asMember,
    required this.upcomingOpenings,
  });

  final String staffId;
  final String name;
  final String department;
  final String division;
  final int asChairman;
  final int asMember;

  /// Openings still ahead, so a heavy week is visible before it happens.
  final int upcomingOpenings;

  int get total => asChairman + asMember;
}

/// Every person sitting on a committee in [records], busiest first.
List<TocMemberWorkload> tocCommitteeWorkload(
  List<TocOpeningRecord> records, {
  DateTime? asOf,
}) {
  final now = asOf ?? DateTime.now();
  final chairman = <String, int>{};
  final member = <String, int>{};
  final upcoming = <String, int>{};
  final seen = <String, TocMember>{};

  for (final record in records) {
    for (final person in record.committee) {
      final id = person.staffId;
      seen[id] = person;
      if (person.roleValue == TocRole.chairman) {
        chairman[id] = (chairman[id] ?? 0) + 1;
      } else {
        member[id] = (member[id] ?? 0) + 1;
      }
      final opening = record.openingDateTime;
      if (opening != null && opening.isAfter(now)) {
        upcoming[id] = (upcoming[id] ?? 0) + 1;
      }
    }
  }

  final workload =
      [
        for (final entry in seen.entries)
          TocMemberWorkload(
            staffId: entry.key,
            name: entry.value.name,
            department: entry.value.department,
            division: entry.value.division,
            asChairman: chairman[entry.key] ?? 0,
            asMember: member[entry.key] ?? 0,
            upcomingOpenings: upcoming[entry.key] ?? 0,
          ),
      ]..sort((a, b) {
        final byTotal = b.total.compareTo(a.total);
        return byTotal != 0 ? byTotal : a.name.compareTo(b.name);
      });

  return workload;
}
