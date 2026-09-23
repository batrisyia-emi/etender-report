// lib/reports/models/vendor_metrics.dart

/// Late submissions still count as participation — the vendor did bid.
bool vendorHasSubmitted(Map<String, dynamic> record) =>
    record['submissionStatus'] == 'Submitted' ||
    record['submissionStatus'] == 'Late';

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
