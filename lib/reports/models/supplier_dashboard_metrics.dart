// lib/reports/models/supplier_dashboard_metrics.dart
//
// The figures behind the Supplier View dashboard. Kept out of the widgets so
// the panels only lay things out, and so the funnel arithmetic can be read
// in one place rather than inferred from five cards.
import 'package:etender_reports/reports/models/tender_status.dart';

/// How close to its expiry a document has to be before the portal starts
/// asking for a renewal.
const int kSupplierExpiryWarningDays = 60;

/// Inside this, asking becomes insisting: the template paints these red
/// and puts a "Renew now" on them.
const int kSupplierExpiryCriticalDays = 14;

/// Where a document stands, in the order the Documents tab ranks them.
enum SupplierDocumentStatus { critical, expiring, valid, missing }

/// Null for a document with no expiry at all, which is valid indefinitely.
int? supplierDaysToExpiry(Map<String, dynamic> document, DateTime now) {
  final expiry = DateTime.tryParse(document['expiryDate']?.toString() ?? '');
  return expiry?.difference(now).inDays;
}

bool supplierDocumentUploaded(Map<String, dynamic> document) =>
    document['uploadedDate'] != null;

SupplierDocumentStatus supplierDocumentStatus(
  Map<String, dynamic> document,
  DateTime now,
) {
  if (!supplierDocumentUploaded(document)) {
    return SupplierDocumentStatus.missing;
  }
  final days = supplierDaysToExpiry(document, now);
  return switch (days) {
    null => SupplierDocumentStatus.valid,
    _ when days <= kSupplierExpiryCriticalDays =>
      SupplierDocumentStatus.critical,
    _ when days <= kSupplierExpiryWarningDays =>
      SupplierDocumentStatus.expiring,
    _ => SupplierDocumentStatus.valid,
  };
}

int supplierDocumentsWith(
  List<Map<String, dynamic>> documents,
  DateTime now,
  SupplierDocumentStatus status,
) => documents.where((d) => supplierDocumentStatus(d, now) == status).length;

int supplierUploadedCount(List<Map<String, dynamic>> documents) =>
    documents.where(supplierDocumentUploaded).length;

/// The documents the portal is actively chasing: expiring or already
/// critical, soonest first. Missing ones are a separate problem and are
/// counted on their own.
List<Map<String, dynamic>> supplierDocumentsNeedingRenewal(
  List<Map<String, dynamic>> documents,
  DateTime now,
) {
  final due =
      documents
          .where(
            (d) =>
                supplierDocumentStatus(d, now) ==
                    SupplierDocumentStatus.critical ||
                supplierDocumentStatus(d, now) ==
                    SupplierDocumentStatus.expiring,
          )
          .toList()
        ..sort(
          (a, b) => (supplierDaysToExpiry(a, now) ?? 0).compareTo(
            supplierDaysToExpiry(b, now) ?? 0,
          ),
        );
  return due;
}

/// Uploaded documents, most recently filed first.
List<Map<String, dynamic>> supplierRecentUploads(
  List<Map<String, dynamic>> documents,
) {
  final uploaded = documents.where(supplierDocumentUploaded).toList()
    ..sort(
      (a, b) => (b['uploadedDate']?.toString() ?? '').compareTo(
        a['uploadedDate']?.toString() ?? '',
      ),
    );
  return uploaded;
}

/// What happens to a bid once it has been submitted.
///
/// [SupplierStatus] deliberately stops at 'Submitted' — the participation
/// report never looks past it — so the portal's own outcomes live here.
/// Declared as an enum so a rename is a compile error rather than a bar
/// that silently counts zero.
enum SupplierBidOutcome {
  underEvaluation(wireValue: 'Under Evaluation'),
  shortlisted(wireValue: 'Shortlisted'),
  awarded(wireValue: 'Awarded'),
  unsuccessful(wireValue: 'Unsuccessful');

  const SupplierBidOutcome({required this.wireValue});

  /// What the record stores.
  final String wireValue;

  static SupplierBidOutcome? fromWire(Object? value) {
    final text = value?.toString();
    for (final outcome in SupplierBidOutcome.values) {
      if (outcome.wireValue == text) return outcome;
    }
    return null;
  }

  /// Decided, so it counts towards the win rate. The other two are still
  /// in play and would drag the rate down for no reason.
  static const Set<SupplierBidOutcome> closed = {awarded, unsuccessful};
}

int supplierBidsWithOutcome(
  List<Map<String, dynamic>> bids,
  SupplierBidOutcome outcome,
) => bids
    .where((b) => SupplierBidOutcome.fromWire(b['outcome']) == outcome)
    .length;

/// Bids still waiting on a decision — neither won nor lost yet. The KPI
/// card calls these "awaiting decision".
int supplierBidsInPlay(List<Map<String, dynamic>> bids) => bids
    .where(
      (b) => !SupplierBidOutcome.closed.contains(
        SupplierBidOutcome.fromWire(b['outcome']),
      ),
    )
    .length;

/// Awarded over decided. Null while nothing has been decided, because 0%
/// would read as a losing streak the supplier has not actually had.
double? supplierWinRate(List<Map<String, dynamic>> bids) {
  final closed = bids.length - supplierBidsInPlay(bids);
  if (closed == 0) return null;
  return supplierBidsWithOutcome(bids, SupplierBidOutcome.awarded) / closed;
}

int supplierClosedBidCount(List<Map<String, dynamic>> bids) =>
    bids.length - supplierBidsInPlay(bids);

/// The tenders a supplier could still bid on: open for bidding and not yet
/// closed. [categories] narrows that to the ones it is registered for.
List<Map<String, dynamic>> supplierOpenTenders(
  List<Map<String, dynamic>> tenders,
  DateTime now, {
  Set<String>? categories,
}) {
  final open =
      tenders
          .where(
            (t) => TenderStatus.openForBidding.contains(
              TenderStatus.fromWire(t['status']),
            ),
          )
          .where(
            (t) =>
                categories == null ||
                categories.contains(t['tenderCategory']?.toString()),
          )
          .map(
            (t) => (
              record: t,
              closing: DateTime.tryParse(t['closingDate']?.toString() ?? ''),
            ),
          )
          .where((e) => e.closing != null && !e.closing!.isBefore(now))
          .toList()
        ..sort((a, b) => a.closing!.compareTo(b.closing!));

  return [for (final entry in open) entry.record];
}
