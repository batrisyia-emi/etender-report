// test/models/toc_metrics_test.dart
import 'package:etender_reports/reports/models/metrics/toc_metrics.dart';
import 'package:etender_reports/reports/models/records/toc_opening_record.dart';
import 'package:etender_reports/reports/models/status/toc_status.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixed so aging and the day-based flags never depend on when the suite
/// runs.
final DateTime asOf = DateTime(2026, 9, 24, 9);

Map<String, dynamic> member({
  String role = 'Chairman',
  String staffId = 'SE10231',
  String name = 'Officer Alpha',
  String division = 'Procurement Division',
}) => {
  'role': role,
  'staffId': staffId,
  'name': name,
  'designation': 'Senior Manager',
  'department': 'Procurement',
  'division': division,
  'email': 'officer@example.invalid',
  'appendixIAckAt': '2026-09-23T09:10:00',
  'appendixJAckAt': '2026-09-23T09:12:00',
  'appendixGAckAt': null,
};

List<Map<String, dynamic>> committeeOf() => [
  member(),
  member(role: 'Member 1', staffId: 'SE11877', name: 'Officer Bravo'),
  member(role: 'Member 2', staffId: 'SE12045', name: 'Officer Charlie'),
];

/// The same three people with Bravo in the chair instead of Alpha.
final List<Map<String, dynamic>> bravoChairs = [
  member(staffId: 'SE11877', name: 'Officer Bravo'),
  member(role: 'Member 1'),
  member(role: 'Member 2', staffId: 'SE12045', name: 'Officer Charlie'),
];

TocOpeningRecord build({
  String tenderNo = 'T.10001',
  String envelopeType = '1 Envelope',
  String status = 'Open',
  List<Map<String, dynamic>> committee = const [],
  String? closing = '2026-09-20T12:00:00',
  String? opening = '2026-09-20T12:00:00',
  bool isExtended = false,
  String? appendixG,
  String? appendixP,
}) => TocOpeningRecord.fromJson({
  'tenderNo': tenderNo,
  'documentType': 'Tender',
  'projectTitle': 'Supply and Delivery of 11kV XLPE ABC Cable',
  'erfcNo': 'ERFC/2026/00000012',
  'envelopeType': envelopeType,
  'status': status,
  'closingDateTime': closing,
  'openingDateTime': opening,
  'isExtended': isExtended,
  'committee': committee,
  'appointedAt': committee.isEmpty ? null : '2026-09-18T15:00:00',
  'replacements': const [],
  'memoRefNo': committee.isEmpty ? null : 'SE/P/UVTM/TN/FY26/TOC0041',
  'memoSentAt': committee.isEmpty ? null : '2026-09-18T16:00:00',
  'otpIssuedDates': const [],
  'openedAt': null,
  'suppliersSubmittedCount': 0,
  'appendixGSubmittedBy': appendixG == null ? null : 'Officer Alpha',
  'appendixGSubmittedAt': appendixG,
  'appendixPSubmittedBy': appendixP == null ? null : 'Officer Kilo',
  'appendixPSubmittedAt': appendixP,
});

void main() {
  group('the status comes from the server', () {
    test('it is read, not derived', () {
      // A record with no committee at all can still carry a late stage:
      // the app reports what it was told rather than second-guessing it.
      final record = build(
        status: 'Commercial Opened',
        envelopeType: '2 Envelope',
      );
      expect(record.statusValue, TocStatus.commercialOpened);
      expect(tocStatusOf(record), TocStatus.commercialOpened);
    });

    test('an unrecognised status is null rather than a wrong guess', () {
      expect(build(status: 'Something Else').statusValue, isNull);
      expect(build(status: '').statusValue, isNull);
    });

    test('every status round-trips through its wire value', () {
      for (final status in TocStatus.values) {
        expect(TocStatus.fromWire(status.wireValue), status);
      }
    });

    test('the eight are in the order an opening moves through them', () {
      expect(TocStatus.wireValues, [
        'Open',
        'Committee Appointed',
        'Opening in Progress',
        'Technical Opened',
        'Commercial Sealed',
        'Commercial Opened',
        'Tender Opened',
        'Opening Completed',
      ]);
    });
  });

  group('envelope arrangements', () {
    test('three stages belong to two-envelope tenders alone', () {
      for (final status in [
        TocStatus.technicalOpened,
        TocStatus.commercialSealed,
        TocStatus.commercialOpened,
      ]) {
        expect(status.appliesTo('2 Envelope'), isTrue);
        expect(status.appliesTo('1 Envelope'), isFalse);
      }
    });

    test('one stage belongs to one-envelope tenders alone', () {
      expect(TocStatus.tenderOpened.appliesTo('1 Envelope'), isTrue);
      expect(TocStatus.tenderOpened.appliesTo('2 Envelope'), isFalse);
    });

    test('the other four happen either way', () {
      for (final status in [
        TocStatus.open,
        TocStatus.committeeAppointed,
        TocStatus.openingInProgress,
        TocStatus.openingCompleted,
      ]) {
        expect(status.appliesTo('1 Envelope'), isTrue);
        expect(status.appliesTo('2 Envelope'), isTrue);
      }
    });

    test('forEnvelope lists what each arrangement can reach', () {
      expect(TocStatus.forEnvelope('1 Envelope'), hasLength(5));
      expect(TocStatus.forEnvelope('2 Envelope'), hasLength(7));
      expect(
        TocStatus.forEnvelope('1 Envelope'),
        isNot(contains(TocStatus.commercialSealed)),
      );
      expect(
        TocStatus.forEnvelope('2 Envelope'),
        isNot(contains(TocStatus.tenderOpened)),
      );
    });

    test('an unknown arrangement allows everything', () {
      // Better to show the row than to call it wrong because the app did
      // not recognise the envelope type.
      for (final status in TocStatus.values) {
        expect(status.appliesTo('3 Envelope'), isTrue);
      }
    });

    test('a mismatch is detected, a legal pairing is not', () {
      expect(
        build(
          envelopeType: '1 Envelope',
          status: 'Commercial Sealed',
        ).hasEnvelopeMismatch,
        isTrue,
      );
      expect(
        build(
          envelopeType: '2 Envelope',
          status: 'Tender Opened',
        ).hasEnvelopeMismatch,
        isTrue,
      );
      expect(
        build(
          envelopeType: '2 Envelope',
          status: 'Commercial Sealed',
        ).hasEnvelopeMismatch,
        isFalse,
      );
      // An unrecognised status is not a mismatch; it is just unrecognised.
      expect(build(status: 'Something Else').hasEnvelopeMismatch, isFalse);
    });
  });

  group('tocAgingDays', () {
    test('counts closing to Appendix P once it is in', () {
      expect(
        tocAgingDays(build(appendixP: '2026-09-25T09:00:00'), asOf: asOf),
        4,
      );
    });

    test('counts closing to now while it is still open', () {
      expect(tocAgingDays(build(), asOf: asOf), 3);
    });

    test('a record closing in the future has not started ageing', () {
      expect(
        tocAgingDays(build(closing: '2026-10-05T12:00:00'), asOf: asOf),
        0,
      );
    });

    test('no closing date means no aging', () {
      expect(tocAgingDays(build(closing: null), asOf: asOf), isNull);
    });
  });

  group('summary counts', () {
    test('tocCountWithStatus counts the status as sent', () {
      final records = [
        build(status: 'Open'),
        build(tenderNo: 'T.2', status: 'Open'),
        build(tenderNo: 'T.3', status: 'Opening Completed'),
      ];
      expect(tocCountWithStatus(records, TocStatus.open), 2);
      expect(tocCountWithStatus(records, TocStatus.openingCompleted), 1);
      expect(tocCountWithStatus(records, TocStatus.technicalOpened), 0);
    });

    test('tocCountWithStatuses counts a group', () {
      final records = [
        build(status: 'Technical Opened', envelopeType: '2 Envelope'),
        build(
          tenderNo: 'T.2',
          status: 'Commercial Sealed',
          envelopeType: '2 Envelope',
        ),
        build(tenderNo: 'T.3', status: 'Open'),
      ];
      expect(
        tocCountWithStatuses(records, {
          TocStatus.technicalOpened,
          TocStatus.commercialSealed,
        }),
        2,
      );
    });

    test('isUnderWay is the five stages between appointed and done', () {
      final underWay = TocStatus.values.where((s) => s.isUnderWay).toList();
      expect(underWay, hasLength(5));
      expect(underWay, isNot(contains(TocStatus.open)));
      expect(underWay, isNot(contains(TocStatus.committeeAppointed)));
      expect(underWay, isNot(contains(TocStatus.openingCompleted)));
    });

    test('tocAverageAging averages closed-out records only', () {
      final records = [
        build(appendixP: '2026-09-22T09:00:00'), // 1 whole day
        build(tenderNo: 'T.10002', appendixP: '2026-09-26T09:00:00'), // 5
        build(tenderNo: 'T.10003'), // still open, excluded
      ];
      expect(tocAverageAging(records, asOf: asOf), 3.0);
    });

    test('tocAverageAging is null when nothing has completed', () {
      expect(tocAverageAging([build()], asOf: asOf), isNull);
    });

    test('tocClosedOutCount counts Appendix P, not the status', () {
      final records = [
        build(appendixP: '2026-09-22T09:00:00', status: 'Opening Completed'),
        build(tenderNo: 'T.2', status: 'Opening Completed'),
      ];
      expect(tocClosedOutCount(records), 1);
      expect(tocCountWithStatus(records, TocStatus.openingCompleted), 2);
    });

    test('tocEnvelopeMismatchCount counts the contradictions', () {
      final records = [
        build(envelopeType: '1 Envelope', status: 'Commercial Sealed'),
        build(tenderNo: 'T.2', envelopeType: '1 Envelope', status: 'Open'),
      ];
      expect(tocEnvelopeMismatchCount(records), 1);
    });
  });

  group('tocExceptionFlags', () {
    test('raises no committee when the closing date is almost here', () {
      final record = build(closing: '2026-09-26T12:00:00', opening: null);
      final flags = tocExceptionFlags([record], asOf: asOf);
      expect(flags, hasLength(1));
      expect(flags.single.label, 'No committee, closing soon');
      expect(flags.single.severity, TocFlagSeverity.high);
      expect(flags.single.remedy, TocRemedy.appointCommittee);
    });

    test('stays quiet when the closing date is far out', () {
      expect(
        tocExceptionFlags([
          build(closing: '2026-10-30T12:00:00', opening: null),
        ], asOf: asOf),
        isEmpty,
      );
    });

    test('raises opening day when the opening has not started', () {
      final appointed = build(
        status: 'Committee Appointed',
        committee: committeeOf(),
        closing: '2026-09-24T12:00:00',
        opening: '2026-09-24T12:00:00',
      );
      final flags = tocExceptionFlags([appointed], asOf: asOf);
      expect(flags.single.label, 'Opening day, not started');
      expect(flags.single.remedy, TocRemedy.startOpening);

      // With no committee it is the committee that is missing, so the
      // remedy changes even though the flag is the same.
      final unappointed = build(
        closing: '2026-09-24T12:00:00',
        opening: '2026-09-24T12:00:00',
      );
      expect(
        tocExceptionFlags(
          [unappointed],
          asOf: asOf,
        ).firstWhere((f) => f.label == 'Opening day, not started').remedy,
        TocRemedy.appointCommittee,
      );
    });

    test('an opening already under way on its day is not flagged', () {
      final started = build(
        status: 'Opening in Progress',
        committee: committeeOf(),
        closing: '2026-09-24T12:00:00',
        opening: '2026-09-24T12:00:00',
      );
      expect(tocExceptionFlags([started], asOf: asOf), isEmpty);
    });

    test('raises a committee cleared by an extension', () {
      final record = build(
        isExtended: true,
        closing: '2026-10-30T12:00:00',
        opening: null,
      );
      final flags = tocExceptionFlags([record], asOf: asOf);
      expect(flags.single.label, 'Committee cleared by extension');
      expect(flags.single.severity, TocFlagSeverity.medium);
    });

    test('raises a status the envelope arrangement cannot reach', () {
      final record = build(
        envelopeType: '1 Envelope',
        status: 'Commercial Sealed',
        committee: committeeOf(),
        closing: '2026-10-30T12:00:00',
        opening: null,
      );
      final flags = tocExceptionFlags([record], asOf: asOf);
      expect(flags.single.label, 'Status does not match envelope type');
      expect(flags.single.remedy, TocRemedy.openRecord);
      expect(flags.single.detail, contains('Commercial Sealed'));
      expect(flags.single.detail, contains('1 envelope'));
    });

    test('raises Appendix P overdue, but not on the day after G', () {
      final overdue = build(
        status: 'Commercial Opened',
        envelopeType: '2 Envelope',
        committee: committeeOf(),
        appendixG: '2026-09-20T16:30:00',
      );
      expect(
        tocExceptionFlags([overdue], asOf: asOf).single.label,
        'Appendix P overdue',
      );

      final justSubmitted = build(
        status: 'Commercial Opened',
        envelopeType: '2 Envelope',
        committee: committeeOf(),
        appendixG: '2026-09-23T16:30:00',
      );
      expect(tocExceptionFlags([justSubmitted], asOf: asOf), isEmpty);
    });

    test('Appendix P is not chased while the commercial envelope is held', () {
      // Appendix G goes in at the technical opening; Appendix P closes the
      // opening day, which is not over until the commercial envelope has
      // been opened.
      for (final status in ['Technical Opened', 'Commercial Sealed']) {
        final holding = build(
          status: status,
          envelopeType: '2 Envelope',
          committee: committeeOf(),
          appendixG: '2026-09-20T16:30:00',
        );
        expect(
          tocExceptionFlags([holding], asOf: asOf),
          isEmpty,
          reason: '$status should not be chased for Appendix P',
        );
      }
    });

    test('urgent flags sort above the ones that can wait', () {
      final urgent = build(closing: '2026-09-26T12:00:00', opening: null);
      final medium = build(
        tenderNo: 'T.10002',
        isExtended: true,
        closing: '2026-10-30T12:00:00',
        opening: null,
      );
      final flags = tocExceptionFlags([medium, urgent], asOf: asOf);
      expect(flags.first.severity, TocFlagSeverity.high);
      expect(flags.last.severity, TocFlagSeverity.medium);
    });

    test('a completed opening raises nothing', () {
      final record = build(
        status: 'Opening Completed',
        committee: committeeOf(),
        appendixG: '2026-09-20T16:30:00',
        appendixP: '2026-09-21T09:00:00',
      );
      expect(tocExceptionFlags([record], asOf: asOf), isEmpty);
    });

    test('every remedy has a button label', () {
      for (final remedy in TocRemedy.values) {
        expect(remedy.label, isNotEmpty);
      }
    });
  });

  group('tocCommitteeWorkload', () {
    test('counts each person across every committee, busiest first', () {
      final records = [
        build(committee: committeeOf()),
        build(tenderNo: 'T.10002', committee: committeeOf()),
        build(tenderNo: 'T.10003', committee: bravoChairs),
      ];
      final workload = tocCommitteeWorkload(records, asOf: asOf);
      final bravo = workload.firstWhere((p) => p.staffId == 'SE11877');

      expect(bravo.asChairman, 1);
      expect(bravo.asMember, 2);
      expect(bravo.total, 3);
      expect(workload.first.total, 3);
    });

    test('counts only openings still ahead as upcoming', () {
      final records = [
        build(committee: committeeOf(), opening: '2026-09-20T12:00:00'),
        build(
          tenderNo: 'T.10002',
          committee: committeeOf(),
          opening: '2026-09-30T12:00:00',
        ),
      ];
      final alpha = tocCommitteeWorkload(
        records,
        asOf: asOf,
      ).firstWhere((p) => p.staffId == 'SE10231');
      expect(alpha.total, 2);
      expect(alpha.upcomingOpenings, 1);
    });

    test('is empty when nothing has been appointed', () {
      expect(tocCommitteeWorkload([build()], asOf: asOf), isEmpty);
    });
  });
}
