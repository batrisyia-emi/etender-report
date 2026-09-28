// lib/reports/models/tender_status.dart
//
// The tender/quotation lifecycle, in funnel order. A tender only appears
// once it reaches the market: published, then published with the closing
// date pushed out, then closed to bids, then finished with.
//
// Declared as an enum rather than bare strings so a rename is a compile
// error rather than a card that silently counts zero. Records still carry
// the wire text, so every comparison goes through [fromWire].

enum TenderStatus {
  published(wireValue: 'Published'),
  extended(wireValue: 'Extended'),
  closed(wireValue: 'Closed'),

  /// Closed and finished with — nothing further is expected of it.
  ///
  /// Distinct from [closed], which only means bidding has stopped: a closed
  /// tender is still being worked through.
  completed(wireValue: 'Completed');

  const TenderStatus({required this.wireValue});

  /// What the API sends and the record stores.
  final String wireValue;

  static TenderStatus? fromWire(Object? value) {
    final text = value?.toString();
    for (final status in TenderStatus.values) {
      if (status.wireValue == text) return status;
    }
    return null;
  }

  /// Every status, in funnel order — the filter's option list.
  static List<String> get wireValues => [
    for (final status in TenderStatus.values) status.wireValue,
  ];

  static Set<String> wiresOf(Set<TenderStatus> statuses) => {
    for (final status in statuses) status.wireValue,
  };

  // ---- The groups the overview cards and the table work in ----

  /// Still accepting bids, whether or not the closing date was pushed out.
  static const Set<TenderStatus> openForBidding = {published, extended};

  /// Past the closing date, whether or not the work is finished. Together
  /// with [openForBidding] this partitions the lifecycle.
  static const Set<TenderStatus> pastClosing = {closed, completed};
}
