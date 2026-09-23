// lib/reports/models/supplier_metrics.dart
//
// The figures the supplier report's cards work in, over the untyped record
// maps the app passes around.
import 'package:etender_reports/reports/models/record_matching.dart';
import 'package:etender_reports/reports/models/supplier_status.dart';

// The wire forms of the groups on [SupplierStatus]. The enum is the source
// of truth; rename a status there and every one of these follows.
final Set<String> kSupplierOpenStatuses = SupplierStatus.wiresOf(
  SupplierStatus.open,
);
final Set<String> kSupplierRejectedStatuses = SupplierStatus.wiresOf(
  SupplierStatus.rejected,
);
final Set<String> kSupplierClearedStatuses = SupplierStatus.wiresOf(
  SupplierStatus.cleared,
);
final Set<String> kSupplierTerminalStatuses = SupplierStatus.wiresOf(
  SupplierStatus.terminal,
);
final Set<String> kSupplierPendingPaymentStatuses = SupplierStatus.wiresOf({
  SupplierStatus.pendingPayment,
});
final Set<String> kSupplierParticipatedStatuses = SupplierStatus.wiresOf({
  SupplierStatus.participated,
});
final Set<String> kSupplierNoParticipateStatuses = SupplierStatus.wiresOf({
  SupplierStatus.noParticipate,
});

double _valueOf(Map<String, dynamic> record, String key) =>
    double.tryParse(record[key]?.toString() ?? '') ?? 0;

String? _statusOf(Map<String, dynamic> record) => record['status']?.toString();

int supplierCountWithStatus(
  List<Map<String, dynamic>> records,
  Set<String> statuses,
) => records.where((r) => statuses.contains(_statusOf(r))).length;

bool supplierIsTerminal(Map<String, dynamic> record) =>
    kSupplierTerminalStatuses.contains(_statusOf(record));

bool supplierIsAwaitingPayment(Map<String, dynamic> record) =>
    kSupplierPendingPaymentStatuses.contains(_statusOf(record));

/// What the supplier has bid across the matching records. Only a submitted
/// bid carries an amount, so nothing else contributes.
double supplierTotalBidValue(List<Map<String, dynamic>> records) =>
    records.fold<double>(0, (total, r) => total + _valueOf(r, 'bidAmount'));

/// Fees owed on everything still sitting at Pending Payment.
double supplierFeesOutstanding(List<Map<String, dynamic>> records) => records
    .where(supplierIsAwaitingPayment)
    .fold<double>(0, (total, r) => total + _valueOf(r, 'documentFee'));

/// Of the tenders that ran their course, the share the supplier actually
/// bid on. Null until at least one has closed, so the card reads "-" rather
/// than a misleading 0%.
double? supplierParticipationRate(List<Map<String, dynamic>> records) {
  final participated = supplierCountWithStatus(
    records,
    kSupplierParticipatedStatuses,
  );
  final missed = supplierCountWithStatus(
    records,
    kSupplierNoParticipateStatuses,
  );
  final closed = participated + missed;
  if (closed == 0) return null;
  return participated / closed * 100;
}

/// Request to decision. Null while the request is still under review, or
/// before it was made at all.
int? supplierDecisionDays(Map<String, dynamic> record) {
  final requested = parseRecordDate(record['requestDate']);
  final decided = parseRecordDate(record['decisionDate']);
  if (requested == null || decided == null) return null;
  final days = decided.difference(requested).inDays;
  return days < 0 ? 0 : days;
}

/// Request to decision, averaged over the requests that got one. Null when
/// none have.
double? supplierAverageDecisionDays(List<Map<String, dynamic>> records) {
  final durations = <int>[
    for (final record in records) ?supplierDecisionDays(record),
  ];
  if (durations.isEmpty) return null;
  return durations.reduce((a, b) => a + b) / durations.length;
}

/// Days until a tender still open for this supplier closes. Null once the
/// date has passed, or when the supplier is already out of the running.
int? supplierDaysToClosing(Map<String, dynamic> record, {DateTime? asOf}) {
  if (supplierIsTerminal(record)) return null;
  final closing = parseRecordDate(record['closingDate']);
  if (closing == null) return null;
  final now = asOf ?? DateTime.now();
  if (closing.isBefore(now)) return null;
  return closing.difference(now).inDays;
}

/// A tender closing within this many days that the supplier has not bid on
/// yet counts as urgent.
const int kSupplierClosingSoonDays = 7;

bool supplierIsClosingSoon(Map<String, dynamic> record, {DateTime? asOf}) {
  final days = supplierDaysToClosing(record, asOf: asOf);
  return days != null && days <= kSupplierClosingSoonDays;
}
