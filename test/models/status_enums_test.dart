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
      expect(TenderStatus.wireValues, ['Published', 'Extended', 'Closed']);
    });

    test('open and closed partition the lifecycle', () {
      expect(TenderStatus.openForBidding, isNot(contains(TenderStatus.closed)));
      expect({
        ...TenderStatus.openForBidding,
        TenderStatus.closed,
      }, TenderStatus.values.toSet());
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
      expect(ErfcStatus.wireValues.last, 'Closed by System');
      expect(ErfcStatus.wireValues, hasLength(14));
    });

    test('in-flight and terminal partition the lifecycle', () {
      expect(ErfcStatus.inFlight.intersection(ErfcStatus.terminal), isEmpty);
      expect({
        ...ErfcStatus.inFlight,
        ...ErfcStatus.terminal,
      }, ErfcStatus.values.toSet());
    });

    test('endorsed and rejected are both terminal and disjoint', () {
      expect(ErfcStatus.terminal, containsAll(ErfcStatus.endorsedOrBeyond));
      expect(ErfcStatus.terminal, containsAll(ErfcStatus.rejected));
      expect(
        ErfcStatus.endorsedOrBeyond.intersection(ErfcStatus.rejected),
        isEmpty,
      );
    });

    test('endorsed covers the states past endorsement, not just Endorsed', () {
      expect(ErfcStatus.wiresOf(ErfcStatus.endorsedOrBeyond), {
        'Endorsed',
        'Paperwork Received',
        'eRFC Completed',
        'Confirmed to Publish',
        'Closed by System',
      });
    });
  });
}
