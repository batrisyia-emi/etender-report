// lib/reports/models/metrics/tender_security_metrics.dart
//
// The figures behind the Tender Security report: what each row's state is,
// and the five summary figures across a set of them.
//
// Kept out of the widgets so the arithmetic can be read in one place and
// tested without building a page.
import 'package:etender_reports/reports/models/attributes/tender_security_attributes.dart';
import 'package:etender_reports/reports/models/records/tender_security_record.dart';

/// How close to expiry counts as "expiring soon".
///
/// An assumption, not a rule. Recommendation R2 asks for expired securities
/// to be highlighted and says plainly that the blueprint sets no threshold;
/// this is the warning window in front of that. The blueprint's own 14 / 7 /
/// 5 / 3 day reminders are a different thing — they count down to the tender
/// closing date and are sent by the notification engine, not by this
/// screen.
const int kTenderSecurityExpiringSoonDays = 14;

/// Whole days from today to expiry. Negative once it has lapsed, null when
/// there is no expiry date to count to.
int? tenderSecurityDaysToExpiry(TenderSecurityRecord record, {DateTime? asOf}) {
  final expiry = record.expiryDate;
  if (expiry == null) return null;

  final now = asOf ?? DateTime.now();
  final from = DateTime(now.year, now.month, now.day);
  final to = DateTime(expiry.year, expiry.month, expiry.day);
  return to.difference(from).inDays;
}

/// The money is back with the tenderer, so nothing else about the row
/// matters any more. Every other state below is conditioned on this.
bool tenderSecurityIsRefunded(TenderSecurityRecord record) =>
    record.refundDate != null;

/// VTM has decided the tenderer lost but has not returned the security.
///
/// Undecided does not count: only an explicit `YES` owes a refund.
bool tenderSecurityIsPendingRefund(TenderSecurityRecord record) =>
    record.outcome == UnsuccessfulTenderer.yes && record.refundDate == null;

/// Lapsed while still held. The state the report exists to surface: an
/// expired instrument still on file secures nothing.
bool tenderSecurityIsExpired(TenderSecurityRecord record, {DateTime? asOf}) {
  if (tenderSecurityIsRefunded(record)) return false;
  final days = tenderSecurityDaysToExpiry(record, asOf: asOf);
  return days != null && days < 0;
}

/// Still valid, but not for much longer.
bool tenderSecurityIsExpiringSoon(
  TenderSecurityRecord record, {
  DateTime? asOf,
}) {
  if (tenderSecurityIsRefunded(record)) return false;
  final days = tenderSecurityDaysToExpiry(record, asOf: asOf);
  return days != null && days >= 0 && days <= kTenderSecurityExpiringSoonDays;
}

// ---- Summary -------------------------------------------------------------

/// Every security in the set, refunded or not.
double tenderSecurityTotal(List<TenderSecurityRecord> records) =>
    records.fold(0, (sum, record) => sum + record.amount);

/// What SESB is actually holding: the total less anything already returned.
double tenderSecurityHeld(List<TenderSecurityRecord> records) => records
    .where((record) => !tenderSecurityIsRefunded(record))
    .fold(0, (sum, record) => sum + record.amount);

int tenderSecurityExpiringSoonCount(
  List<TenderSecurityRecord> records, {
  DateTime? asOf,
}) => records.where((r) => tenderSecurityIsExpiringSoon(r, asOf: asOf)).length;

int tenderSecurityExpiredCount(
  List<TenderSecurityRecord> records, {
  DateTime? asOf,
}) => records.where((r) => tenderSecurityIsExpired(r, asOf: asOf)).length;

int tenderSecurityPendingRefundCount(List<TenderSecurityRecord> records) =>
    records.where(tenderSecurityIsPendingRefund).length;

int tenderSecurityRefundedCount(List<TenderSecurityRecord> records) =>
    records.where(tenderSecurityIsRefunded).length;

/// Still to be chased: the original instrument has not reached VTM.
int tenderSecurityOriginalNotReceivedCount(
  List<TenderSecurityRecord> records,
) => records.where((r) => !r.originalCopyReceived).length;

/// Not yet passed to Revenue Assurance / Contract Services.
int tenderSecurityNotSubmittedCount(List<TenderSecurityRecord> records) =>
    records.where((r) => !r.isSubmittedToRevenueAssurance).length;
