// test/models/tender_record_test.dart
import 'package:etender_reports/reports/models/records/tender_record.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime asOf = DateTime(2026, 9, 8);

TenderRecord build({
  String status = 'Published',
  String? requested = '2026-08-01T09:00:00',
  String? floating = '2026-08-12T08:00:00',
  String? closing = '2026-09-12T17:00:00',
}) => TenderRecord.fromJson({
  'referenceNo': 'REF-2026-089',
  'tenderNo': 'SESB/T/2026/012',
  'title': 'Substation Maintenance Sabah West',
  'tenderCategory': 'Works',
  'division': 'Distribution',
  'department': 'Asset Management',
  'unit': 'Substation Unit',
  'value': 250000.0,
  'modeOfProcurement': 'Open Tender',
  'envelopeType': '2 Envelope',
  'itemType': 'Non-Stock Item',
  'requestedDate': requested,
  'endorsedDate': '2026-08-08T10:15:00',
  'floatingDate': floating,
  'closingDate': closing,
  'status': status,
  'isRetender': false,
  'retenderCount': 0,
  'erfcId': 'ERFC/2026/00009021',
  'createdBy': 'Officer A',
  'lastUpdate': '2026-09-05T15:20:00',
  'lastUpdatedBy': 'Officer A',
});

void main() {
  group('closing', () {
    test('counts the days remaining', () {
      expect(build().daysToClosing(asOf: asOf), 4);
    });

    test('a passed closing date returns null, not a negative', () {
      final record = build(closing: '2026-08-15T17:00:00');
      expect(record.daysToClosing(asOf: asOf), isNull);
    });

    test('a tender with no closing date has no days to closing', () {
      expect(build(closing: null).daysToClosing(asOf: asOf), isNull);
    });

    test('the closing-soon window edge', () {
      final record = build(closing: '2026-09-15T09:00:00');
      expect(record.daysToClosing(asOf: asOf), kClosingSoonDays);
    });
  });

  test('days to market needs both dates', () {
    // 1 Aug 09:00 to 12 Aug 08:00 is 10 whole days.
    expect(build().daysToMarket, 10);
    expect(build(floating: null).daysToMarket, isNull);
  });

  test('survives a round trip through json', () {
    final record = build(status: 'Closed');
    expect(TenderRecord.fromJson(record.toJson()), record);
  });

  test('the market-facing statuses each read back as their own flag', () {
    final published = build(status: 'Published');
    expect(
      [published.isPublished, published.isExtended, published.isClosed],
      [true, false, false],
    );

    final extended = build(status: 'Extended');
    expect(
      [extended.isPublished, extended.isExtended, extended.isClosed],
      [false, true, false],
    );

    final closed = build(status: 'Closed');
    expect(
      [closed.isPublished, closed.isExtended, closed.isClosed],
      [false, false, true],
    );
  });

  test('bidding is open while published or extended, not once Closed', () {
    expect(build(status: 'Published').isOpenForBidding, isTrue);
    expect(build(status: 'Extended').isOpenForBidding, isTrue);
    expect(build(status: 'Closed').isOpenForBidding, isFalse);
  });

  test('text outside the lifecycle reads as no status at all', () {
    final unknown = build(status: 'Approved');
    expect(unknown.lifecycleStatus, isNull);
    expect(
      [unknown.isPublished, unknown.isExtended, unknown.isClosed],
      [false, false, false],
    );
    expect(unknown.isOpenForBidding, isFalse);
  });
}
