// test/filters/erfc_filters_test.dart
import 'package:etender_reports/reports/models/report_filters.dart';
import 'package:flutter_test/flutter_test.dart';

/// Submitted 1 Aug and still in flight, so it is comfortably overdue
/// against any realistic "today".
Map<String, dynamic> record({
  String status = 'Submitted',
  String unit = 'Substation Unit',
  String? submitted = '2026-08-01T09:00:00',
  String? endorsed,
}) => {
  'rfcNumber': 'ERFC/2026/00009021',
  'division': 'Distribution',
  'department': 'Asset Management',
  'unit': unit,
  'modeOfProcurement': 'Tender (Two Envelope)',
  'value': 250000.0,
  'submissionDate': submitted,
  'verifiedDate': null,
  'endorsedDate': endorsed,
  'status': status,
  'createdBy': 'Officer A',
};

void main() {
  test('unit filter narrows by unit', () {
    const filters = ErfcFilters(units: {'Metering Unit'});
    expect(filters.matches(record()), isFalse);
    expect(filters.matches(record(unit: 'Metering Unit')), isTrue);
  });

  test('search covers the unit as well as the RFC number', () {
    expect(
      const ErfcFilters(searchQuery: 'substation').matches(record()),
      isTrue,
    );
    expect(
      const ErfcFilters(searchQuery: '00009021').matches(record()),
      isTrue,
    );
  });

  group('overdue only', () {
    test('keeps an in-flight RFC past the threshold', () {
      expect(const ErfcFilters(overdueOnly: true).matches(record()), isTrue);
    });

    test('drops an endorsed RFC however old it is', () {
      final endorsed = record(
        status: 'Endorsed',
        endorsed: '2026-08-08T10:15:00',
      );
      expect(const ErfcFilters(overdueOnly: true).matches(endorsed), isFalse);
    });

    test('drops a rejected RFC: it is not waiting on anyone', () {
      final rejected = record(status: 'Rejected by 2nd Verifier');
      expect(const ErfcFilters(overdueOnly: true).matches(rejected), isFalse);
    });

    test('off by default, so nothing is hidden unless asked', () {
      final endorsed = record(
        status: 'Endorsed',
        endorsed: '2026-08-08T10:15:00',
      );
      expect(const ErfcFilters().matches(endorsed), isTrue);
    });
  });
}
