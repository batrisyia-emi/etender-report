// test/models/erfc_record_test.dart
import 'package:etender_reports/reports/models/records/erfc_record.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixed so aging never depends on when the suite runs.
final DateTime asOf = DateTime(2026, 9, 8);

ErfcRecord build({
  String status = 'Submitted',
  String? submitted = '2026-08-01T09:00:00',
  String? verified1,
  String? verified2,
  String? endorsed,
}) => ErfcRecord.fromJson({
  'rfcNumber': 'ERFC/2026/00009021',
  'division': 'Distribution',
  'department': 'Asset Management',
  'unit': 'Substation Unit',
  'modeOfProcurement': 'Tender (Two Envelope)',
  'value': 250000.0,
  'submissionDate': submitted,
  'verified1Date': verified1,
  'verified2Date': verified2,
  'endorsedDate': endorsed,
  'status': status,
  'createdBy': 'Officer A',
});

void main() {
  group('parsing', () {
    test('reads every field, and null dates stay null', () {
      final record = build(
        verified1: '2026-08-03T10:00:00',
        verified2: '2026-08-05T14:30:00',
      );

      expect(record.rfcNumber, 'ERFC/2026/00009021');
      expect(record.value, 250000.0);
      expect(record.verified1Date, DateTime(2026, 8, 3, 10));
      expect(record.verified2Date, DateTime(2026, 8, 5, 14, 30));
      // The derived getter is the latest gate reached.
      expect(record.verifiedDate, DateTime(2026, 8, 5, 14, 30));
      expect(record.endorsedDate, isNull);
    });

    test('a numeric value sent as a string still parses', () {
      final record = ErfcRecord.fromJson({'value': '250000.00'});
      expect(record.value, 250000.0);
    });

    test('missing fields fall back rather than throwing', () {
      final record = ErfcRecord.fromJson({});

      expect(record.rfcNumber, '');
      expect(record.value, 0);
      expect(record.submissionDate, isNull);
      expect(record.agingDays(asOf: asOf), isNull);
    });

    test('survives a round trip through json', () {
      final record = build(
        status: 'Endorsed',
        verified1: '2026-08-05T14:30:00',
        endorsed: '2026-08-08T10:15:00',
      );
      expect(ErfcRecord.fromJson(record.toJson()), record);
    });
  });

  group('aging', () {
    test('an in-flight RFC counts to today', () {
      // 1 Aug 09:00 to 8 Sep 00:00 is 37 whole days; inDays truncates.
      expect(build().agingDays(asOf: asOf), 37);
    });

    test('an endorsed RFC freezes at endorsement', () {
      final record = build(status: 'Endorsed', endorsed: '2026-08-08T10:15:00');
      expect(record.agingDays(asOf: asOf), 7);
    });

    test('a rejected RFC freezes at the latest gate it reached', () {
      final record = build(
        status: 'Rejected by 2nd Verifier',
        verified1: '2026-08-04T09:15:00',
        verified2: '2026-08-06T09:15:00',
      );
      expect(record.agingDays(asOf: asOf), 5);
    });

    test('a terminal RFC with no verification still stops at today', () {
      // Nothing recorded the closure, so today is the best available end.
      final record = build(status: 'Cancelled');
      expect(record.agingDays(asOf: asOf), 37);
    });

    test('never returns a negative age', () {
      final record = build(submitted: '2026-09-20T09:00:00');
      expect(record.agingDays(asOf: asOf), 0);
    });
  });

  group('aging against the overdue threshold', () {
    test('exactly at the threshold', () {
      final record = build(submitted: '2026-08-24T09:00:00');
      expect(record.agingDays(asOf: asOf), kErfcOverdueDays);
    });

    test('one day past the threshold', () {
      final record = build(submitted: '2026-08-23T09:00:00');
      expect(record.agingDays(asOf: asOf), kErfcOverdueDays + 1);
    });
  });

  group('processing days', () {
    test('measured only for endorsed RFCs', () {
      final endorsed = build(
        status: 'Endorsed',
        endorsed: '2026-08-08T10:15:00',
      );
      expect(endorsed.processingDays, 7);
      expect(build().processingDays, isNull);
    });
  });

  test('divisionAndDepartment falls back when there is no department', () {
    expect(build().divisionAndDepartment, 'Distribution / Asset Management');
    final noDepartment = ErfcRecord.fromJson({'division': 'Distribution'});
    expect(noDepartment.divisionAndDepartment, 'Distribution');
  });
}
