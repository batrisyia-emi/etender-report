// test/filters/toc_filters_test.dart
import 'package:etender_reports/reports/models/records/toc_opening_record.dart';
import 'package:etender_reports/reports/models/toc_filters.dart';
import 'package:etender_reports/reports/models/toc_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> member(String role, String staffId, String name) => {
  'role': role,
  'staffId': staffId,
  'name': name,
  'designation': 'Executive',
  'department': 'Procurement',
  'division': 'Procurement Division',
  'email': 'officer@example.invalid',
  'appendixIAckAt': '2026-09-23T09:10:00',
  'appendixJAckAt': '2026-09-23T09:12:00',
  'appendixGAckAt': null,
};

final List<Map<String, dynamic>> committee = [
  member('Chairman', 'SE10231', 'Officer Alpha'),
  member('Member 1', 'SE11877', 'Officer Bravo'),
  member('Member 2', 'SE12045', 'Officer Charlie'),
];

TocOpeningRecord build({
  String tenderNo = 'T.10001',
  String documentType = 'Tender',
  String envelopeType = '1 Envelope',
  String status = 'Opening Completed',
  List<Map<String, dynamic>>? members,
  String? closing = '2026-09-28T12:00:00',
  String? appendixP,
}) => TocOpeningRecord.fromJson({
  'tenderNo': tenderNo,
  'documentType': documentType,
  'projectTitle': 'Supply and Delivery of 11kV XLPE ABC Cable',
  'erfcNo': 'ERFC/2026/00000012',
  'envelopeType': envelopeType,
  'status': status,
  'closingDateTime': closing,
  'openingDateTime': closing,
  'isExtended': false,
  'committee': members ?? committee,
  'appointedAt': '2026-09-24T15:00:00',
  'replacements': const [],
  'memoRefNo': 'SE/P/UVTM/TN/FY26/TOC0041',
  'memoSentAt': '2026-09-24T16:20:00',
  'otpIssuedDates': const [],
  'openedAt': null,
  'suppliersSubmittedCount': 0,
  'appendixGSubmittedBy': null,
  'appendixGSubmittedAt': null,
  'appendixPSubmittedBy': appendixP == null ? null : 'Officer Kilo',
  'appendixPSubmittedAt': appendixP,
});

void main() {
  group('tender number', () {
    test('matches a fragment, ignoring case', () {
      const filters = TocFilters(tenderNoQuery: 't.100');
      expect(filters.matches(build()), isTrue);
      expect(filters.matches(build(tenderNo: 'Q.20417')), isFalse);
    });

    test('matches the amendment suffix', () {
      const filters = TocFilters(tenderNoQuery: '(2S)');
      expect(filters.matches(build(tenderNo: 'T.10002(2S)')), isTrue);
    });
  });

  group('committee member', () {
    test('matches any seat by name', () {
      // Member 2, not the chairman: the filter has to walk the whole list.
      const filters = TocFilters(memberQuery: 'charlie');
      expect(filters.matches(build()), isTrue);
    });

    test('matches by staff ID as well as by name', () {
      const filters = TocFilters(memberQuery: 'SE11877');
      expect(filters.matches(build()), isTrue);
    });

    test('does not match someone who is not on the committee', () {
      const filters = TocFilters(memberQuery: 'Officer Hotel');
      expect(filters.matches(build()), isFalse);
    });

    test('an unappointed record matches no member search', () {
      const filters = TocFilters(memberQuery: 'alpha');
      expect(filters.matches(build(members: const [])), isFalse);
    });
  });

  group('document type', () {
    test('null means both', () {
      const filters = TocFilters();
      expect(filters.matches(build()), isTrue);
      expect(filters.matches(build(documentType: 'Quotation')), isTrue);
    });

    test('narrows to one type', () {
      const filters = TocFilters(documentType: 'Quotation');
      expect(filters.matches(build()), isFalse);
      expect(filters.matches(build(documentType: 'Quotation')), isTrue);
    });
  });

  group('status', () {
    test('empty means every status', () {
      const filters = TocFilters();
      expect(filters.matches(build()), isTrue);
    });

    test('matches the status the server sent', () {
      final completed = TocFilters(
        statuses: TocStatus.wiresOf({TocStatus.openingCompleted}),
      );
      expect(completed.matches(build()), isTrue);
      expect(completed.matches(build(status: 'Open')), isFalse);

      final open = TocFilters(statuses: TocStatus.wiresOf({TocStatus.open}));
      expect(open.matches(build(status: 'Open')), isTrue);
    });

    test('envelope type narrows independently of status', () {
      const twoEnvelope = TocFilters(envelopeType: '2 Envelope');
      expect(twoEnvelope.matches(build(envelopeType: '2 Envelope')), isTrue);
      expect(twoEnvelope.matches(build()), isFalse);
    });

    test('the filter offers all eight statuses, in process order', () {
      expect(TocFilters.statusOptions, [
        'Open',
        'Committee Appointed',
        'Opening in Progress',
        'Technical Opened',
        'Commercial Sealed',
        'Commercial Opened',
        'Tender Opened',
        'Opening Completed',
      ]);
      expect(TocFilters.envelopeTypeOptions, ['1 Envelope', '2 Envelope']);
    });
  });

  group('closing date range', () {
    final range = DateTimeRange(
      start: DateTime(2026, 9, 25),
      end: DateTime(2026, 9, 30),
    );

    test('includes both end days in full', () {
      final filters = TocFilters(closingDateRange: range);
      expect(filters.matches(build(closing: '2026-09-25T08:00:00')), isTrue);
      expect(filters.matches(build(closing: '2026-09-30T23:59:00')), isTrue);
    });

    test('excludes dates outside it', () {
      final filters = TocFilters(closingDateRange: range);
      expect(filters.matches(build(closing: '2026-09-24T12:00:00')), isFalse);
      expect(filters.matches(build(closing: '2026-10-01T12:00:00')), isFalse);
    });

    test('a record with no closing date falls out of any range', () {
      final filters = TocFilters(closingDateRange: range);
      expect(filters.matches(build(closing: null)), isFalse);
    });
  });

  group('toggleStatuses', () {
    final ready = TocStatus.wiresOf({TocStatus.openingCompleted});

    test('applies the group when something else is selected', () {
      const filters = TocFilters();
      expect(filters.toggleStatuses(ready).statuses, ready);
    });

    test('clears the group when it is already the selection', () {
      final filters = TocFilters(statuses: ready);
      expect(filters.toggleStatuses(ready).statuses, isEmpty);
    });

    test('replaces a different selection rather than merging', () {
      final filters = TocFilters(statuses: TocStatus.wiresOf({TocStatus.open}));
      expect(filters.toggleStatuses(ready).statuses, ready);
    });
  });

  group('copyWith', () {
    test('clears the nullable fields rather than ignoring null', () {
      final filters = TocFilters(
        documentType: 'Tender',
        closingDateRange: DateTimeRange(
          start: DateTime(2026, 9, 1),
          end: DateTime(2026, 9, 30),
        ),
      );

      final cleared = filters.copyWith(
        documentType: null,
        closingDateRange: null,
      );
      expect(cleared.documentType, isNull);
      expect(cleared.closingDateRange, isNull);
    });

    test('leaves untouched fields alone', () {
      const filters = TocFilters(
        tenderNoQuery: 'T.100',
        documentType: 'Tender',
      );
      expect(filters.copyWith(memberQuery: 'alpha').documentType, 'Tender');
      expect(filters.copyWith(memberQuery: 'alpha').tenderNoQuery, 'T.100');
    });
  });

  test('isEmpty is true only with nothing set', () {
    expect(const TocFilters().isEmpty, isTrue);
    expect(const TocFilters(tenderNoQuery: 'T').isEmpty, isFalse);
    expect(const TocFilters(memberQuery: 'a').isEmpty, isFalse);
    expect(const TocFilters(documentType: 'Tender').isEmpty, isFalse);
    expect(TocFilters(statuses: {'Opening Completed'}).isEmpty, isFalse);
  });
}
