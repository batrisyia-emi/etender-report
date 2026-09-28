// lib/reports/models/status/erfc_status.dart
//
// The eRFC lifecycle, in funnel order: three approval gates, each of which
// can reject or decline, then the states it passes through on its way to
// being published.
//
// Rejected and Declined are recorded separately at every gate. Both stop the
// RFC there, so the report counts them together on its cards — but the
// vocabulary keeps them apart, because "sent back" and "refused" are not the
// same answer and only the wire text says which happened.
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
  declinedByFirstVerifier(wireValue: 'Declined by 1st Verifier'),
  declinedBySecondVerifier(wireValue: 'Declined by 2nd Verifier'),
  declinedByEndorser(wireValue: 'Declined by Endorser'),
  cancelled(wireValue: 'Cancelled'),
  paperworkReceived(wireValue: 'Paperwork Received'),
  erfcCompleted(wireValue: 'eRFC Completed'),
  confirmToProceed(wireValue: 'Confirm to Proceed'),
  deletedBySystem(wireValue: 'Deleted by System');

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

  /// Sent back at one of the three approval gates.
  static const Set<ErfcStatus> rejected = {
    rejectedByFirstVerifier,
    rejectedBySecondVerifier,
    rejectedByEndorser,
  };

  /// Refused at one of the three approval gates.
  ///
  /// Kept apart from [rejected] because the two are different answers, even
  /// though the RFC stops either way and the cards count them together.
  static const Set<ErfcStatus> declined = {
    declinedByFirstVerifier,
    declinedBySecondVerifier,
    declinedByEndorser,
  };

  /// Stopped at a gate, however it was worded. What the report counts.
  static const Set<ErfcStatus> rejectedOrDeclined = {...rejected, ...declined};

  /// Endorsement cleared. The RFC keeps moving through the publishing steps
  /// past this point, but the approval chain itself is finished.
  static const Set<ErfcStatus> endorsedOrBeyond = {
    endorsed,
    paperworkReceived,
    erfcCompleted,
    confirmToProceed,
    deletedBySystem,
  };

  /// Statuses that stop the clock: the RFC is not waiting on anyone.
  static const Set<ErfcStatus> terminal = {
    ...endorsedOrBeyond,
    ...rejectedOrDeclined,
    cancelled,
  };
}
