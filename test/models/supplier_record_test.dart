// test/models/supplier_record_test.dart
import 'package:etender_reports/reports/models/records/supplier_record.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime asOf = DateTime(2026, 9, 8);

SupplierRecord build({
  String status = 'Paid',
  String? published = '2026-08-01T08:00:00',
  String? request = '2026-08-04T09:00:00',
  String? decision = '2026-08-09T15:00:00',
  String? payment = '2026-08-10T10:00:00',
  String? closing = '2026-09-12T17:00:00',
  String? submission,
  double documentFee = 200.0,
  double bidAmount = 0,
}) => SupplierRecord.fromJson({
  'supplierName': 'Vendor N Sdn Bhd',
  'supplierId': 'VEN/2000/000004',
  'referenceNo': 'REF-2026-089',
  'tenderNo': 'SESB/T/2026/012',
  'title': 'Substation Maintenance Sabah West',
  'tenderCategory': 'Service',
  'division': 'Distribution',
  'modeOfProcurement': 'Tender/Quotation',
  'openTo': 'Registered Suppliers',
  'certificationType': 'CIDB-KONTRAKTOR KERJA & PERKHIDMATAN',
  'status': status,
  'publishedDate': published,
  'requestDate': request,
  'decisionDate': decision,
  'paymentDate': payment,
  'closingDate': closing,
  'submissionDateTime': submission,
  'documentFee': documentFee,
  'bidAmount': bidAmount,
});

void main() {
  test('survives a round trip through json', () {
    final record = build(
      status: 'Participated',
      submission: '2026-09-10T14:30:00',
      bidAmount: 242500.0,
    );
    expect(SupplierRecord.fromJson(record.toJson()), record);
  });

  group('status flags', () {
    test('a rejected request reads as rejected and as terminal', () {
      final record = build(status: 'Request Rejected');

      expect(record.isRejected, isTrue);
      expect(record.isTerminal, isTrue);
      expect(record.isCleared, isFalse);
    });

    test('cleared covers approved through paid, and none are terminal', () {
      for (final status in ['Request Approved', 'Pending Payment', 'Paid']) {
        final record = build(status: status);
        expect(record.isCleared, isTrue, reason: status);
        expect(record.isTerminal, isFalse, reason: status);
      }
    });

    test('only Pending Payment is awaiting payment', () {
      expect(build(status: 'Pending Payment').isAwaitingPayment, isTrue);
      expect(build(status: 'Paid').isAwaitingPayment, isFalse);
      expect(build(status: 'Request Approved').isAwaitingPayment, isFalse);
    });

    test('the two closing outcomes are distinct and both terminal', () {
      final participated = build(status: 'Participated');
      expect(participated.hasParticipated, isTrue);
      expect(participated.missedParticipation, isFalse);
      expect(participated.isTerminal, isTrue);

      final missed = build(status: 'No Participate');
      expect(missed.hasParticipated, isFalse);
      expect(missed.missedParticipation, isTrue);
      expect(missed.isTerminal, isTrue);
    });

    test('text outside the lifecycle reads as no status at all', () {
      final unknown = build(status: 'Shortlisted');
      expect(unknown.lifecycleStatus, isNull);
      expect(unknown.isRejected, isFalse);
      expect(unknown.isCleared, isFalse);
      expect(unknown.isTerminal, isFalse);
    });
  });

  group('days to decision', () {
    test('counts request to decision', () {
      expect(build().daysToDecision, 5);
    });

    test('is null while the request is still under review', () {
      expect(build(decision: null).daysToDecision, isNull);
    });

    test('is null when no request was made', () {
      expect(build(request: null, decision: null).daysToDecision, isNull);
    });

    test('a decision dated before the request floors at zero', () {
      final record = build(
        request: '2026-08-10T09:00:00',
        decision: '2026-08-04T09:00:00',
      );
      expect(record.daysToDecision, 0);
    });
  });

  group('days to closing', () {
    test('counts the days remaining', () {
      expect(build().daysToClosing(asOf: asOf), 4);
    });

    test('a passed closing date returns null, not a negative', () {
      expect(
        build(closing: '2026-08-15T17:00:00').daysToClosing(asOf: asOf),
        isNull,
      );
    });

    test('a record with no closing date has none to count', () {
      expect(build(closing: null).daysToClosing(asOf: asOf), isNull);
    });
  });
}
