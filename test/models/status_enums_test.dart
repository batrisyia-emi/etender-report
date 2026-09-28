// test/models/status_enums_test.dart
//
// The enums are the source of truth for every status comparison in the app.
// These tests pin the wire text and the groups, so a rename that would have
// silently zeroed a card fails here instead.
import 'package:etender_reports/data/mock/report_mock_data.dart';
import 'package:etender_reports/reports/models/erfc_status.dart';
import 'package:etender_reports/reports/models/tender_status.dart';
import 'package:flutter_test/flutter_test.dart';

Set<String> statusesIn(List<Map<String, dynamic>> records) =>
    records.map((r) => r['status'].toString()).toSet();

void main() {
  group('TenderStatus', () {
    test('every status in the data resolves to an enum value', () {
      for (final status in statusesIn(ReportMockData.tenderRecords)) {
        expect(
          TenderStatus.fromWire(status),
          isNotNull,
          reason: '$status is in the data but not in TenderStatus',
        );
      }
    });

    test('unknown text resolves to null rather than throwing', () {
      expect(TenderStatus.fromWire('Nonsense'), isNull);
      expect(TenderStatus.fromWire(null), isNull);
    });

    test('the lifecycle reads in funnel order', () {
      expect(TenderStatus.wireValues, [
        'Published',
        'Extended',
        'Closed',
        'Completed',
      ]);
    });

    test('open for bidding and past closing partition the lifecycle', () {
      expect(
        TenderStatus.openForBidding.intersection(TenderStatus.pastClosing),
        isEmpty,
      );
      expect({
        ...TenderStatus.openForBidding,
        ...TenderStatus.pastClosing,
      }, TenderStatus.values.toSet());
    });

    test('Completed is past closing but is not Closed', () {
      // Closed means bidding stopped; Completed means nothing further is
      // expected. Counting them as one would hide work still in hand.
      expect(
        TenderStatus.pastClosing,
        containsAll([TenderStatus.closed, TenderStatus.completed]),
      );
      expect(
        TenderStatus.openForBidding,
        isNot(contains(TenderStatus.completed)),
      );
    });

    test('wiresOf returns the text the records are keyed by', () {
      expect(TenderStatus.wiresOf(TenderStatus.openForBidding), {
        'Published',
        'Extended',
      });
    });
  });

  group('ErfcStatus', () {
    test('every status in the data resolves to an enum value', () {
      for (final status in statusesIn(ReportMockData.erfcRecords)) {
        expect(
          ErfcStatus.fromWire(status),
          isNotNull,
          reason: '$status is in the data but not in ErfcStatus',
        );
      }
    });

    test('the lifecycle reads in funnel order', () {
      expect(ErfcStatus.wireValues.first, 'Draft');
      expect(ErfcStatus.wireValues.last, 'Deleted by System');
      expect(ErfcStatus.wireValues, hasLength(16));
    });

    test('every status the enum names appears in the sample data', () {
      // The filter offers all sixteen, so all sixteen should show
      // something rather than an empty table.
      final inData = statusesIn(ReportMockData.erfcRecords).toSet();
      for (final status in ErfcStatus.values) {
        expect(
          inData,
          contains(status.wireValue),
          reason: 'no sample record reads as ${status.wireValue}',
        );
      }
    });

    test('in-flight and terminal partition the lifecycle', () {
      expect(ErfcStatus.inFlight.intersection(ErfcStatus.terminal), isEmpty);
      expect({
        ...ErfcStatus.inFlight,
        ...ErfcStatus.terminal,
      }, ErfcStatus.values.toSet());
    });

    test('endorsed and refused are both terminal and disjoint', () {
      expect(ErfcStatus.terminal, containsAll(ErfcStatus.endorsedOrBeyond));
      expect(ErfcStatus.terminal, containsAll(ErfcStatus.rejectedOrDeclined));
      expect(
        ErfcStatus.endorsedOrBeyond.intersection(ErfcStatus.rejectedOrDeclined),
        isEmpty,
      );
    });

    test('rejected and declined are kept apart, three of each', () {
      // Sent back and refused are different answers; the cards count them
      // together but the vocabulary does not merge them.
      expect(ErfcStatus.rejected, hasLength(3));
      expect(ErfcStatus.declined, hasLength(3));
      expect(ErfcStatus.rejected.intersection(ErfcStatus.declined), isEmpty);
      expect(ErfcStatus.rejectedOrDeclined, hasLength(6));
    });

    test('each gate can both reject and decline', () {
      for (final gate in ['1st Verifier', '2nd Verifier', 'Endorser']) {
        expect(ErfcStatus.wireValues, contains('Rejected by $gate'));
        expect(ErfcStatus.wireValues, contains('Declined by $gate'));
      }
    });

    test('endorsed covers the states past endorsement, not just Endorsed', () {
      expect(ErfcStatus.wiresOf(ErfcStatus.endorsedOrBeyond), {
        'Endorsed',
        'Paperwork Received',
        'eRFC Completed',
        'Confirm to Proceed',
        'Deleted by System',
      });
    });
  });
}
