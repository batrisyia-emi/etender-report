// lib/reports/models/metrics/vendor_metrics.dart

/// The bid is in. The respond status no longer distinguishes a late
/// submission from an on-time one; compare submissionDateTime against the
/// tender's closing date if that matters again.
bool vendorHasSubmitted(Map<String, dynamic> record) =>
    record['submissionStatus'] == 'Submitted';

int vendorCountWhere(
  List<Map<String, dynamic>> records,
  bool Function(Map<String, dynamic>) test,
) => records.where(test).length;

int vendorInvitedCount(List<Map<String, dynamic>> records) =>
    vendorCountWhere(records, (r) => r['invitationStatus'] == 'Sent');

/// Vendors that took the invitation up, as opposed to turning it down.
int vendorParticipatedCount(List<Map<String, dynamic>> records) =>
    vendorCountWhere(
      records,
      (r) => r['participationStatus'] == 'Participated',
    );

int vendorPurchasedCount(List<Map<String, dynamic>> records) =>
    vendorCountWhere(records, (r) => r['documentPurchased'] == true);

int vendorSubmittedCount(List<Map<String, dynamic>> records) =>
    vendorCountWhere(records, vendorHasSubmitted);
