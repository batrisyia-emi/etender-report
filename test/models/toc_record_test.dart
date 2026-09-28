// test/models/toc_record_test.dart
import 'package:etender_reports/reports/models/records/toc_opening_record.dart';
import 'package:etender_reports/reports/models/toc_status.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> member({
  String role = 'Chairman',
  String staffId = 'SE10231',
  String name = 'Officer Alpha',
  String? appendixI = '2026-09-25T09:10:00',
  String? appendixJ = '2026-09-25T09:12:00',
  String? appendixG,
}) => {
  'role': role,
  'staffId': staffId,
  'name': name,
  'designation': 'Senior Manager',
  'department': 'Procurement',
  'division': 'Procurement Division',
  'email': 'alpha@example.invalid',
  'appendixIAckAt': appendixI,
  'appendixJAckAt': appendixJ,
  'appendixGAckAt': appendixG,
};

TocOpeningRecord build({
  List<Map<String, dynamic>>? committee,
  List<Map<String, dynamic>> replacements = const [],
  List<String> otpIssuedDates = const [],
  Map<String, dynamic> extra = const {},
}) => TocOpeningRecord.fromJson({
  'tenderNo': 'T.10001',
  'documentType': 'Tender',
  'projectTitle': 'Supply and Delivery of 11kV XLPE ABC Cable',
  'erfcNo': 'ERFC/2026/00000012',
  'closingDateTime': '2026-09-28T12:00:00',
  'openingDateTime': '2026-09-28T12:00:00',
  'isExtended': false,
  'committee': committee ?? [member()],
  'appointedAt': '2026-09-24T15:00:00',
  'replacements': replacements,
  'memoRefNo': 'SE/P/UVTM/TN/FY26/TOC0041',
  'memoSentAt': '2026-09-24T16:20:00',
  'otpIssuedDates': otpIssuedDates,
  'openedAt': null,
  'suppliersSubmittedCount': 0,
  'appendixGSubmittedBy': null,
  'appendixGSubmittedAt': null,
  'appendixPSubmittedBy': null,
  'appendixPSubmittedAt': null,
  ...extra,
});

List<Map<String, dynamic>> fullCommittee({
  bool member1Signed = true,
  bool member2Signed = true,
}) => [
  member(),
  member(
    role: 'Member 1',
    staffId: 'SE11877',
    name: 'Officer Bravo',
    appendixJ: member1Signed ? '2026-09-25T10:04:00' : null,
  ),
  member(
    role: 'Member 2',
    staffId: 'SE12045',
    name: 'Officer Charlie',
    appendixI: member2Signed ? '2026-09-25T11:00:00' : null,
  ),
];

void main() {
  group('parsing', () {
    test('reads the header, and null timestamps stay null', () {
      final record = build();

      expect(record.tenderNo, 'T.10001');
      expect(record.documentTypeValue, TocDocumentType.tender);
      expect(record.erfcNo, 'ERFC/2026/00000012');
      expect(record.closingDateTime, DateTime(2026, 9, 28, 12));
      expect(record.memoRefNo, 'SE/P/UVTM/TN/FY26/TOC0041');
      expect(record.openedAt, isNull);
      expect(record.appendixGSubmittedAt, isNull);
    });

    test('reads the nested committee, including the role enum', () {
      final record = build(committee: fullCommittee());

      expect(record.committee, hasLength(3));
      expect(record.memberAt(TocRole.chairman)?.name, 'Officer Alpha');
      expect(record.memberAt(TocRole.member1)?.staffId, 'SE11877');
      expect(record.memberAt(TocRole.member2)?.name, 'Officer Charlie');
    });

    test('an unfilled seat reads as null rather than throwing', () {
      expect(build().memberAt(TocRole.member2), isNull);
    });

    test('otpIssuedDates parses a list of dates, skipping unusable ones', () {
      final record = build(
        otpIssuedDates: const ['2026-09-28T11:50:00', 'not a date'],
      );

      expect(record.otpIssuedDates, [DateTime(2026, 9, 28, 11, 50)]);
    });

    test('replacements carry their mandatory remarks', () {
      final record = build(
        replacements: const [
          {
            'role': 'Member 1',
            'replacedName': 'Officer Bravo',
            'newName': 'Officer Delta',
            'remarks': 'On medical leave',
            'replacedAt': '2026-09-26T08:00:00',
            'replacedBy': 'Officer Kilo',
          },
        ],
      );

      expect(record.replacements.single.remarks, 'On medical leave');
      expect(record.replacements.single.replacedAt, DateTime(2026, 9, 26, 8));
    });

    test('a malformed committee degrades to empty instead of throwing', () {
      final record = TocOpeningRecord.fromJson({
        'tenderNo': 'T.10001',
        'committee': 'not a list',
      });

      expect(record.committee, isEmpty);
      expect(record.hasCommittee, isFalse);
    });
  });

  // The whole point of this record. See docs/toc-report.md.
  group('confidentiality', () {
    test('bid data sent by a server is dropped, never surfaced', () {
      final record = build(
        extra: const {
          'hargaTawaran': 4850000.0,
          'jadualHarga': [1, 2, 3],
          'tempohSiap': '18 months',
          'tempohSahLaku': '90 days',
          'otpValue': '483917',
        },
      );

      // Round-tripping is the check that matters: whatever the server sent,
      // nothing price-shaped survives into what the app holds.
      final json = record.toJson();
      expect(json.keys, isNot(contains('hargaTawaran')));
      expect(json.keys, isNot(contains('jadualHarga')));
      expect(json.keys, isNot(contains('tempohSiap')));
      expect(json.keys, isNot(contains('tempohSahLaku')));
      expect(json.keys, isNot(contains('otpValue')));
      expect(json.values.whereType<num>(), everyElement(isNot(4850000.0)));
    });

    test('Appendix G is who and when only', () {
      final record = build(
        extra: const {
          'appendixGSubmittedBy': 'Officer Alpha',
          'appendixGSubmittedAt': '2026-09-28T16:30:00',
          'appendixGContents': 'Bidder A: RM 4,850,000',
        },
      );

      expect(record.appendixGSubmittedBy, 'Officer Alpha');
      expect(record.appendixGSubmittedAt, DateTime(2026, 9, 28, 16, 30));
      expect(record.toJson().keys, isNot(contains('appendixGContents')));
    });
  });

  group('committee state', () {
    test('three seats is a committee; anything else is not', () {
      expect(build(committee: fullCommittee()).hasCommittee, isTrue);
      expect(build().hasCommittee, isFalse);
      expect(build(committee: const []).hasCommittee, isFalse);
    });
  });

  group('envelope and status', () {
    test('both are read straight from the wire', () {
      final record = build(
        extra: const {
          'envelopeType': '2 Envelope',
          'status': 'Commercial Sealed',
        },
      );
      expect(record.envelopeTypeValue, TocEnvelopeType.twoEnvelope);
      expect(record.statusValue, TocStatus.commercialSealed);
      expect(record.hasEnvelopeMismatch, isFalse);
    });

    test('a two-envelope stage on a one-envelope tender is a mismatch', () {
      final record = build(
        extra: const {
          'envelopeType': '1 Envelope',
          'status': 'Commercial Sealed',
        },
      );
      expect(record.hasEnvelopeMismatch, isTrue);
    });
  });

  test('toJson round-trips back to an equal record', () {
    final record = build(
      committee: fullCommittee(),
      otpIssuedDates: const ['2026-09-28T11:50:00'],
      replacements: const [
        {
          'role': 'Member 1',
          'replacedName': 'Officer Bravo',
          'newName': 'Officer Delta',
          'remarks': 'On medical leave',
          'replacedAt': '2026-09-26T08:00:00',
          'replacedBy': 'Officer Kilo',
        },
      ],
    );

    expect(TocOpeningRecord.fromJson(record.toJson()), record);
  });
}
