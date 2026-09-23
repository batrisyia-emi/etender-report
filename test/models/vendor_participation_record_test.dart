// test/models/vendor_participation_record_test.dart
import 'package:etender_reports/reports/models/records/vendor_participation_record.dart';
import 'package:flutter_test/flutter_test.dart';

VendorParticipationRecord build({
  String invitation = 'Sent',
  Object purchased = true,
  String submission = 'Submitted',
  String? submittedAt = '2026-09-10T14:30:00',
  String participation = 'Bumiputera',
}) => VendorParticipationRecord.fromJson({
  'referenceNo': 'REF-2026-089',
  'tenderNo': 'SESB/T/2026/012',
  'title': 'Substation Maintenance Sabah West',
  'tenderCategory': 'Works',
  'division': 'Distribution',
  'vendorName': 'Vendor W Sdn Bhd',
  'invitationStatus': invitation,
  'documentPurchased': purchased,
  'submissionStatus': submission,
  'submissionDateTime': submittedAt,
  'participationType': participation,
  'certificationType': 'KKM-BEKALAN',
});

void main() {
  test('late bids still count as participation', () {
    expect(build(submission: 'Submitted').hasSubmitted, isTrue);
    expect(build(submission: 'Late').hasSubmitted, isTrue);
    expect(build(submission: 'Not Submitted').hasSubmitted, isFalse);
  });

  test('wasLate separates late from on-time bids', () {
    expect(build(submission: 'Late').wasLate, isTrue);
    expect(build(submission: 'Submitted').wasLate, isFalse);
  });

  test('a non-submitter has no submission timestamp', () {
    final record = build(submission: 'Not Submitted', submittedAt: null);
    expect(record.submissionDateTime, isNull);
    expect(record.hasSubmitted, isFalse);
  });

  test('purchase label matches the filter values', () {
    expect(build(purchased: true).purchaseLabel, 'Yes');
    expect(build(purchased: false).purchaseLabel, 'No');
  });

  test('a boolean sent as a string is still a boolean', () {
    expect(build(purchased: 'true').documentPurchased, isTrue);
    expect(build(purchased: 'false').documentPurchased, isFalse);
  });

  test('survives a round trip through json', () {
    final record = build();
    expect(VendorParticipationRecord.fromJson(record.toJson()), record);
  });
}
