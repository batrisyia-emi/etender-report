// lib/reports/models/erfc_status.dart
//
// The eRFC lifecycle, in funnel order: three approval gates that can each
// turn the RFC back, then the states it passes through on its way to being
// published.
//
// Declared as an enum rather than bare strings so a rename is a compile
// error rather than a card that silently counts zero. Records still carry
// the wire text, so every comparison goes through [fromWire].

enum ErfcStatus {
  draft(wireValue: 'Draft'),
  submitted(wireValue: 'Submitted'),
  firstVerified(wireValue: 'Verified by 1st Verifier'),
  rejectedByFirstVerifier(wireValue: 'Rejected by 1st Verifier'),
  secondVerified(wireValue: 'Verified by 2nd Verifier'),
  rejectedBySecondVerifier(wireValue: 'Rejected by 2nd Verifier'),
  endorsed(wireValue: 'Endorsed'),
  rejectedByEndorser(wireValue: 'Rejected by Endorser'),
  decline(wireValue: 'Decline'),
  cancelled(wireValue: 'Cancelled'),
  paperworkReceived(wireValue: 'Paperwork Received'),
  erfcCompleted(wireValue: 'eRFC Completed'),
  confirmedToPublish(wireValue: 'Confirmed to Publish'),
  closedBySystem(wireValue: 'Closed by System');

  const ErfcStatus({required this.wireValue});

  /// What the API sends and the record stores.
  final String wireValue;

  static ErfcStatus? fromWire(Object? value) {
    final text = value?.toString();
    for (final status in ErfcStatus.values) {
      if (status.wireValue == text) return status;
    }
    return null;
  }

  /// Every status, in funnel order — the filter's option list.
  static List<String> get wireValues => [
    for (final status in ErfcStatus.values) status.wireValue,
  ];

  static Set<String> wiresOf(Set<ErfcStatus> statuses) => {
    for (final status in statuses) status.wireValue,
  };

  // ---- The groups the overview cards and the metrics work in ----

  /// Still waiting on someone. Together with [terminal] this partitions the
  /// lifecycle, so a status belongs to exactly one of them.
  static const Set<ErfcStatus> inFlight = {
    draft,
    submitted,
    firstVerified,
    secondVerified,
  };

  /// Rejected at one of the three approval steps, or declined. The RFC goes
  /// no further.
  static const Set<ErfcStatus> rejected = {
    rejectedByFirstVerifier,
    rejectedBySecondVerifier,
    rejectedByEndorser,
    decline,
  };

  /// Endorsement cleared. The RFC keeps moving through the publishing steps
  /// past this point, but the approval chain itself is finished.
  static const Set<ErfcStatus> endorsedOrBeyond = {
    endorsed,
    paperworkReceived,
    erfcCompleted,
    confirmedToPublish,
    closedBySystem,
  };

  /// Statuses that stop the clock: the RFC is not waiting on anyone.
  static const Set<ErfcStatus> terminal = {
    ...endorsedOrBeyond,
    ...rejected,
    cancelled,
  };
}
