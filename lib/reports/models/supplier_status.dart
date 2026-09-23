// lib/reports/models/supplier_status.dart
//
// What one supplier's involvement in one tender looks like from the
// supplier's own side, in the order the portal lists it: the tender appears,
// the supplier asks to take part, the request is approved or rejected, then
// payment, then the bid itself.
//
// The review is a single decision here. Who inside SE turned a request back
// is SE's business, so the supplier only ever sees 'Request Rejected'.
//
// Declared as an enum rather than bare strings so a rename is a compile
// error rather than a card that silently counts zero. Records still carry
// the wire text, so every comparison goes through [fromWire].

enum SupplierStatus {
  published(wireValue: 'Published'),
  participationRequested(wireValue: 'Participation Requested'),
  requestRejected(wireValue: 'Request Rejected'),
  requestApproved(wireValue: 'Request Approved'),
  pendingPayment(wireValue: 'Pending Payment'),
  paid(wireValue: 'Paid'),
  participated(wireValue: 'Participated'),
  noParticipate(wireValue: 'No Participate'),
  draft(wireValue: 'Draft'),
  submitted(wireValue: 'Submitted');

  const SupplierStatus({required this.wireValue});

  /// What the API sends and the record stores.
  final String wireValue;

  static SupplierStatus? fromWire(Object? value) {
    final text = value?.toString();
    for (final status in SupplierStatus.values) {
      if (status.wireValue == text) return status;
    }
    return null;
  }

  /// Every status, in the order above — the filter's option list.
  static List<String> get wireValues => [
    for (final status in SupplierStatus.values) status.wireValue,
  ];

  static Set<String> wiresOf(Set<SupplierStatus> statuses) => {
    for (final status in statuses) status.wireValue,
  };

  // ---- The groups the overview cards and the table work in ----

  /// Nothing has been decided yet: the tender is visible, or the supplier is
  /// still putting its request or bid together.
  static const Set<SupplierStatus> open = {
    published,
    participationRequested,
    draft,
    submitted,
  };

  /// The request was turned back. The supplier goes no further on this
  /// tender.
  static const Set<SupplierStatus> rejected = {requestRejected};

  /// The request cleared review. The supplier is through the gates and
  /// working towards a bid, whether or not the fee has been settled.
  static const Set<SupplierStatus> cleared = {
    requestApproved,
    pendingPayment,
    paid,
  };

  /// How it ended once the tender closed. [noParticipate] is set by the
  /// system rather than by anyone choosing it.
  static const Set<SupplierStatus> closedOut = {participated, noParticipate};

  /// Nothing more will happen on this tender. Together with [open] and
  /// [cleared] this partitions the lifecycle.
  static const Set<SupplierStatus> terminal = {...rejected, ...closedOut};
}
