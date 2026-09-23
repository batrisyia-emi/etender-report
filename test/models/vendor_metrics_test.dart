// test/models/vendor_metrics_test.dart
//
// The vendor funnel narrows at every step: invited -> participated ->
// purchased -> submitted. These pin the subset relationships the cards
// divide by, so a footer can never report more than its denominator.
import 'package:etender_reports/data/mock/report_mock_data.dart';
import 'package:etender_reports/reports/models/vendor_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> record({
  required bool purchased,
  required String submissionStatus,
}) => {
  'vendorName': 'Test Vendor Sdn Bhd',
  'tenderNo': 'SESB/T/2026/012',
  'invitationStatus': 'Sent',
  'documentPurchased': purchased,
  'participationStatus': 'Participated',
  'submissionStatus': submissionStatus,
};

void main() {
  group('counting', () {
    test('purchases and bids are counted independently', () {
      final records = [
        record(purchased: true, submissionStatus: 'Submitted'),
        record(purchased: true, submissionStatus: 'Not Submitted'),
        record(purchased: false, submissionStatus: 'Submitted'),
      ];

      expect(vendorPurchasedCount(records), 2);
      expect(vendorSubmittedCount(records), 2);
    });

    test('a late bid still counts as a submission', () {
      final records = [record(purchased: true, submissionStatus: 'Late')];
      expect(vendorSubmittedCount(records), 1);
    });
  });

  group('sample data funnel', () {
    final records = ReportMockData.vendorParticipationRecords;

    // A vendor only unlocks the document by clicking participate, so a
    // purchase without participation is not a state the system can reach.
    test('nobody buys the document without participating', () {
      final bought = records.where((r) => r['documentPurchased'] == true);

      expect(bought, isNotEmpty);
      expect(
        bought.where((r) => r['participationStatus'] != 'Participated'),
        isEmpty,
      );
    });

    test('every bid comes from a vendor holding the document', () {
      expect(
        records
            .where((r) => vendorHasSubmitted(r))
            .where((r) => r['documentPurchased'] != true),
        isEmpty,
      );
    });

    test('each step of the funnel is narrower than the one before it', () {
      final participated = vendorParticipatedCount(records);

      expect(participated, lessThanOrEqualTo(vendorInvitedCount(records)));
      expect(vendorPurchasedCount(records), lessThanOrEqualTo(participated));
      expect(
        vendorSubmittedCount(records),
        lessThanOrEqualTo(vendorPurchasedCount(records)),
      );
    });
  });
}
