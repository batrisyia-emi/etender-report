// lib/reports/models/toc_status.dart
//
// Where a tender has reached in its opening, per Blueprint v1.3 sections
// 3.6 / 8.3 / 8.4.
//
// Eight stages, and which of them can occur depends on how the tender takes
// its bids. A one-envelope tender is opened once. A two-envelope tender has
// its technical envelope opened first, its commercial envelope left sealed
// until the technical evaluation is done, and then opened in turn — so
// three of these stages belong to two-envelope tenders alone, and one
// belongs to one-envelope tenders alone.
//
// Unlike the earlier committee-readiness vocabulary this replaces, the
// status is **sent by the server**, not derived here. Nothing a frontend
// can read means "Commercial Sealed": that is VTM's decision about a
// physical envelope, and any timestamp the app could infer it from would be
// the server having decided it already.

/// Which envelope arrangements a status can occur under.
enum TocEnvelopeScope {
  /// Happens whichever way the tender takes its bids.
  both,

  /// One-envelope tenders only: technical and price arrive together, so the
  /// tender is opened once.
  oneEnvelopeOnly,

  /// Two-envelope tenders only: the two envelopes are opened separately.
  twoEnvelopeOnly,
}

enum TocStatus {
  /// Published and taking bids. No committee yet.
  open(wireValue: 'Open', scope: TocEnvelopeScope.both),

  /// Three members named.
  committeeAppointed(
    wireValue: 'Committee Appointed',
    scope: TocEnvelopeScope.both,
  ),

  /// The opening session has started.
  openingInProgress(
    wireValue: 'Opening in Progress',
    scope: TocEnvelopeScope.both,
  ),

  /// Two envelope: the technical envelope has been opened.
  technicalOpened(
    wireValue: 'Technical Opened',
    scope: TocEnvelopeScope.twoEnvelopeOnly,
  ),

  /// Two envelope: the commercial envelope is held sealed while the
  /// technical evaluation runs.
  commercialSealed(
    wireValue: 'Commercial Sealed',
    scope: TocEnvelopeScope.twoEnvelopeOnly,
  ),

  /// Two envelope: the commercial envelope has been opened in turn.
  commercialOpened(
    wireValue: 'Commercial Opened',
    scope: TocEnvelopeScope.twoEnvelopeOnly,
  ),

  /// One envelope: the single envelope has been opened.
  tenderOpened(
    wireValue: 'Tender Opened',
    scope: TocEnvelopeScope.oneEnvelopeOnly,
  ),

  /// Nothing further is expected of the opening.
  openingCompleted(
    wireValue: 'Opening Completed',
    scope: TocEnvelopeScope.both,
  );

  const TocStatus({required this.wireValue, required this.scope});

  /// What the endpoint sends, the filter stores and the chip displays.
  final String wireValue;

  final TocEnvelopeScope scope;

  static TocStatus? fromWire(Object? value) {
    final text = value?.toString();
    for (final status in TocStatus.values) {
      if (status.wireValue == text) return status;
    }
    return null;
  }

  /// Every status, in the order an opening moves through them — the
  /// filter's option list, and the order sorting by status walks.
  static List<String> get wireValues => [
    for (final status in TocStatus.values) status.wireValue,
  ];

  static Set<String> wiresOf(Set<TocStatus> statuses) => {
    for (final status in statuses) status.wireValue,
  };

  /// Whether this status can occur on a tender taking bids [envelopeType]
  /// way. See [TocEnvelopeType].
  ///
  /// An unrecognised envelope type allows everything: the app should not
  /// call a row wrong because it did not recognise the arrangement.
  bool appliesTo(String envelopeType) {
    final envelope = TocEnvelopeType.fromWire(envelopeType);
    if (envelope == null) return true;
    return switch (scope) {
      TocEnvelopeScope.both => true,
      TocEnvelopeScope.oneEnvelopeOnly =>
        envelope == TocEnvelopeType.oneEnvelope,
      TocEnvelopeScope.twoEnvelopeOnly =>
        envelope == TocEnvelopeType.twoEnvelope,
    };
  }

  /// The statuses a tender taking bids [envelopeType] way can reach.
  static List<TocStatus> forEnvelope(String envelopeType) => [
    for (final status in TocStatus.values)
      if (status.appliesTo(envelopeType)) status,
  ];

  /// The opening has started but not finished — the stages worth chasing.
  bool get isUnderWay =>
      index > TocStatus.committeeAppointed.index &&
      this != TocStatus.openingCompleted;
}

/// How a tender takes its bids.
///
/// The same two values the Tender Summary report uses — see `kEnvelopeTypes`
/// in tender_attributes.dart, which is the single source for the wording.
enum TocEnvelopeType {
  oneEnvelope(wireValue: '1 Envelope'),
  twoEnvelope(wireValue: '2 Envelope');

  const TocEnvelopeType({required this.wireValue});

  final String wireValue;

  static TocEnvelopeType? fromWire(Object? value) {
    final text = value?.toString();
    for (final type in TocEnvelopeType.values) {
      if (type.wireValue == text) return type;
    }
    return null;
  }

  static List<String> get wireValues => [
    for (final type in TocEnvelopeType.values) type.wireValue,
  ];
}

/// The three seats on a committee, in the order the memo lists them.
enum TocRole {
  chairman(wireValue: 'Chairman'),
  member1(wireValue: 'Member 1'),
  member2(wireValue: 'Member 2');

  const TocRole({required this.wireValue});

  final String wireValue;

  static TocRole? fromWire(Object? value) {
    final text = value?.toString();
    for (final role in TocRole.values) {
      if (role.wireValue == text) return role;
    }
    return null;
  }
}

/// Tender or quotation. The two follow the same opening process but are
/// appointed by different VTM roles and use different memo references.
enum TocDocumentType {
  tender(wireValue: 'Tender'),
  quotation(wireValue: 'Quotation');

  const TocDocumentType({required this.wireValue});

  final String wireValue;

  static TocDocumentType? fromWire(Object? value) {
    final text = value?.toString();
    for (final type in TocDocumentType.values) {
      if (type.wireValue == text) return type;
    }
    return null;
  }

  static List<String> get wireValues => [
    for (final type in TocDocumentType.values) type.wireValue,
  ];
}
