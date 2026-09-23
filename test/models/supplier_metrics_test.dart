// test/models/supplier_metrics_test.dart
import 'package:etender_reports/reports/models/supplier_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime asOf = DateTime(2026, 9, 8);

Map<String, dynamic> record({
  required String status,
  String? request,
  String? decision,
  String? payment,
  String? closing = '2026-09-12T17:00:00',
  double documentFee = 200.0,
  double bidAmount = 0,
}) => {
  'supplierName': 'Vendor N Sdn Bhd',
  'tenderNo': 'SESB/T/2026/012',
  'status': status,
  'requestDate': request,
  'decisionDate': decision,
  'paymentDate': payment,
  'closingDate': closing,
  'documentFee': documentFee,
  'bidAmount': bidAmount,
};

void main() {
  group('participation rate', () {
    test('is the share of closed tenders that got a bid', () {
      final records = [
        record(status: 'Participated'),
        record(status: 'Participated'),
        record(status: 'Participated'),
        record(status: 'No Participate'),
      ];
      expect(supplierParticipationRate(records), 75.0);
    });

    test('ignores everything that has not closed yet', () {
      final records = [
        record(status: 'Participated'),
        record(status: 'No Participate'),
        // None of these have run their course, so none count either way.
        record(status: 'Published'),
        record(status: 'Pending Payment'),
        record(status: 'Request Rejected'),
      ];
      expect(supplierParticipationRate(records), 50.0);
    });

    test('is null rather than zero before anything closes', () {
      final records = [
        record(status: 'Published'),
        record(status: 'Request Approved'),
      ];
      expect(supplierParticipationRate(records), isNull);
    });
  });

  group('fees', () {
    test('outstanding counts only what is still pending', () {
      final records = [
        record(status: 'Pending Payment', documentFee: 500),
        record(status: 'Pending Payment', documentFee: 50),
        record(status: 'Paid', payment: '2026-08-10T10:00:00'),
      ];
      expect(supplierFeesOutstanding(records), 550.0);
    });
  });

  test('total bid value adds up every bid on the matching rows', () {
    final records = [
      record(status: 'Participated', bidAmount: 242500),
      record(status: 'Submitted', bidAmount: 86500),
      record(status: 'Published'),
    ];
    expect(supplierTotalBidValue(records), 329000.0);
  });

  group('average decision days', () {
    test('averages only the requests that got a decision', () {
      final records = [
        record(
          status: 'Request Approved',
          request: '2026-08-01T09:00:00',
          decision: '2026-08-05T09:00:00',
        ),
        record(
          status: 'Request Rejected',
          request: '2026-08-01T09:00:00',
          decision: '2026-08-09T09:00:00',
        ),
        // Still under review: excluded rather than counted as zero.
        record(
          status: 'Participation Requested',
          request: '2026-08-01T09:00:00',
        ),
      ];
      expect(supplierAverageDecisionDays(records), 6.0);
    });

    test('is null when nothing has been decided', () {
      final records = [record(status: 'Published')];
      expect(supplierAverageDecisionDays(records), isNull);
    });
  });

  group('closing soon', () {
    test('counts an open record inside the window', () {
      final subject = record(status: 'Request Approved');
      expect(supplierDaysToClosing(subject, asOf: asOf), 4);
      expect(supplierIsClosingSoon(subject, asOf: asOf), isTrue);
    });

    test('a terminal record is never closing soon, whatever the date', () {
      // The supplier is out of the running, so the deadline is not theirs
      // to worry about.
      const statuses = ['Participated', 'No Participate', 'Request Rejected'];
      for (final status in statuses) {
        final subject = record(status: status);
        expect(
          supplierDaysToClosing(subject, asOf: asOf),
          isNull,
          reason: status,
        );
        expect(
          supplierIsClosingSoon(subject, asOf: asOf),
          isFalse,
          reason: status,
        );
      }
    });

    test('a passed deadline stops counting', () {
      final subject = record(status: 'Paid', closing: '2026-08-15T17:00:00');
      expect(supplierDaysToClosing(subject, asOf: asOf), isNull);
      expect(supplierIsClosingSoon(subject, asOf: asOf), isFalse);
    });
  });

  test('terminal matches the statuses that stop the clock', () {
    expect(supplierIsTerminal(record(status: 'Participated')), isTrue);
    expect(supplierIsTerminal(record(status: 'No Participate')), isTrue);
    expect(supplierIsTerminal(record(status: 'Request Rejected')), isTrue);
    expect(supplierIsTerminal(record(status: 'Pending Payment')), isFalse);
    expect(supplierIsTerminal(record(status: 'Published')), isFalse);
  });
}
