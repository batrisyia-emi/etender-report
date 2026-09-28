// test/models/vtm_monitoring_test.dart
import 'package:etender_reports/data/mock/vtm_monitoring_records.dart';
import 'package:etender_reports/reports/models/filters/vtm_monitoring_filters.dart';
import 'package:etender_reports/reports/models/metrics/vtm_monitoring_metrics.dart';
import 'package:etender_reports/reports/models/records/vtm_monitoring_record.dart';
import 'package:etender_reports/reports/models/status/vtm_monitoring_status.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixed so aging never depends on when the suite runs.
final DateTime asOf = DateTime(2026, 9, 28);

VtmMonitoringRecord build({
  String erfcNo = 'ERFC/2026/00000041',
  String? tenderQuotationNo,
  String documentType = 'Tender',
  String mode = '7.1',
  String division = 'Distribution Division',
  String status = 'DRAFT',
  double estimatedValue = 480000,
  double documentPrice = 50,
  String? endorsed = '2026-09-22',
  String? submitted,
  String? verified,
  String? approved,
  String? floating,
  String? remarks,
}) => VtmMonitoringRecord.fromJson({
  'erfcNo': erfcNo,
  'tenderQuotationNo': tenderQuotationNo,
  'projectTitle': 'Supply and Delivery of 11kV Ring Main Units',
  'documentType': documentType,
  'tenderType': '1S',
  'modeOfProcurement': mode,
  'division': division,
  'department': 'Asset Management',
  'estimatedValue': estimatedValue,
  'documentPrice': documentPrice,
  'status': status,
  'preparedBy': const {
    'userId': 'SE10231',
    'name': 'Admin Supervisor',
    'role': 'Admin Supervisor',
  },
  'verifiedBy': null,
  'approvedBy': null,
  'endorsedDate': endorsed,
  'submittedDate': submitted,
  'verifiedDate': verified,
  'approvedDate': approved,
  'floatingDate': floating,
  'closingDate': null,
  'rejectionRemarks': remarks,
});

void main() {
  group('parsing', () {
    test('reads every field, and an absent step stays null', () {
      final record = build(submitted: '2026-09-24T10:42:00');
      expect(record.erfcNo, 'ERFC/2026/00000041');
      expect(record.estimatedValue, 480000);
      expect(record.submittedDate, DateTime(2026, 9, 24, 10, 42));
      expect(record.verifiedDate, isNull);
      expect(record.tenderQuotationNo, isNull);
      expect(record.preparedBy?.name, 'Admin Supervisor');
      expect(record.verifiedBy, isNull);
    });

    test('the status code resolves to its label and its owner', () {
      final record = build(status: 'VERIFIED_BY_EXEC');
      expect(record.statusValue, VtmStatus.verifiedByExec);
      expect(record.statusLabel, 'Verified by VTM Executive');
      expect(record.statusValue!.actor, contains('Executive'));
    });

    test('an unrecognised code shows itself rather than a blank', () {
      expect(build(status: 'SENT_TO_LEGAL').statusLabel, 'SENT_TO_LEGAL');
      expect(build(status: 'SENT_TO_LEGAL').statusValue, isNull);
    });

    test('a procurement code outside the five shows itself', () {
      // 7.4 is Direct Negotiation, which is never floated — its arrival
      // here is a finding, not something to hide behind a blank cell.
      expect(build(mode: '7.4a').modeLabel, '7.4a');
      expect(build(mode: '7.6').modeLabel, 'Schedule Rate/JHT');
    });

    test('a malformed actor degrades to null rather than throwing', () {
      final record = VtmMonitoringRecord.fromJson(const {
        'erfcNo': 'ERFC/1',
        'preparedBy': 'Admin Supervisor',
      });
      expect(record.preparedBy, isNull);
    });

    test('survives a round trip through json', () {
      final record = build(
        status: 'PUBLISHED',
        tenderQuotationNo: 'T.10021',
        floating: '2026-09-01',
      );
      expect(VtmMonitoringRecord.fromJson(record.toJson()), record);
    });
  });

  group('the status has a shape', () {
    test('order follows the enum and starts at one', () {
      expect(VtmStatus.draft.order, 1);
      expect(VtmStatus.published.order, 7);
      expect(VtmStatus.values, hasLength(7));
    });

    test('only Published is terminal', () {
      for (final status in VtmStatus.values) {
        expect(status.isTerminal, status == VtmStatus.published);
      }
      expect(VtmStatus.published.nextStatuses, isEmpty);
    });

    test('both rejections return to Submitted, not to Draft', () {
      // The document goes back to its preparer for correction; it is not
      // started again.
      for (final rejection in [
        VtmStatus.rejectedByExec,
        VtmStatus.rejectedByManager,
      ]) {
        expect(rejection.nextStatuses, {VtmStatus.submitted});
        expect(rejection.isRejected, isTrue);
        expect(rejection.isInProgress, isFalse);
      }
    });

    test('every non-terminal status leads somewhere', () {
      for (final status in VtmStatus.values) {
        if (status.isTerminal) continue;
        expect(
          status.nextStatuses,
          isNotEmpty,
          reason: '${status.code} is a dead end',
        );
      }
    });

    test('every status is reachable from Draft', () {
      // Walk the graph; anything unreachable is a state nothing can enter.
      final seen = <VtmStatus>{VtmStatus.draft};
      final queue = [VtmStatus.draft];
      while (queue.isNotEmpty) {
        for (final next in queue.removeAt(0).nextStatuses) {
          if (seen.add(next)) queue.add(next);
        }
      }
      expect(seen, VtmStatus.values.toSet());
    });

    test('in progress is everything neither rejected nor floated', () {
      final inProgress = VtmStatus.values.where((s) => s.isInProgress);
      expect(inProgress, hasLength(4));
      expect(inProgress, isNot(contains(VtmStatus.published)));
    });

    test('codes round-trip and carry a label', () {
      for (final status in VtmStatus.values) {
        expect(VtmStatus.fromCode(status.code), status);
        expect(status.label, isNotEmpty);
        expect(status.actor, isNotEmpty);
        expect(status.description, isNotEmpty);
      }
    });
  });

  group('aging', () {
    test('counts endorsement to today while it is in flight', () {
      expect(vtmAgingDays(build(endorsed: '2026-09-22'), asOf: asOf), 6);
    });

    test('counts endorsement to floating once published', () {
      // The question changes with the status: how long has this waited
      // becomes how long did this take, and that stops moving.
      final published = build(
        status: 'PUBLISHED',
        endorsed: '2026-08-12',
        floating: '2026-09-01',
      );
      expect(vtmAgingDays(published, asOf: asOf), 20);
      // Still 20 a month later, because it is finished.
      expect(vtmAgingDays(published, asOf: DateTime(2026, 11, 1)), 20);
    });

    test('a published record with no floating date falls back to today', () {
      final odd = build(status: 'PUBLISHED', endorsed: '2026-09-22');
      expect(vtmAgingDays(odd, asOf: asOf), 6);
    });

    test('no endorsement date means no aging', () {
      expect(vtmAgingDays(build(endorsed: null), asOf: asOf), isNull);
    });

    test('slow is past the threshold and still moving', () {
      final old = build(endorsed: '2026-08-20');
      expect(vtmAgingDays(old, asOf: asOf), greaterThan(kVtmSlowDays));
      expect(vtmIsSlow(old, asOf: asOf), isTrue);

      // A published document is never slow: it is finished, however long
      // it took.
      final slowButDone = build(
        status: 'PUBLISHED',
        endorsed: '2026-01-01',
        floating: '2026-08-01',
      );
      expect(vtmIsSlow(slowButDone, asOf: asOf), isFalse);
    });
  });

  group('summary', () {
    final records = [
      build(erfcNo: 'E/1', status: 'DRAFT', estimatedValue: 100),
      build(erfcNo: 'E/2', status: 'REJECTED_BY_EXEC', estimatedValue: 200),
      build(erfcNo: 'E/3', status: 'APPROVED_BY_MANAGER', estimatedValue: 300),
      build(
        erfcNo: 'E/4',
        status: 'PUBLISHED',
        estimatedValue: 400,
        endorsed: '2026-08-12',
        floating: '2026-09-01',
        tenderQuotationNo: 'T.1',
      ),
    ];

    test('counts the groups the cards show', () {
      expect(vtmInProgressCount(records), 2);
      expect(vtmRejectedCount(records), 1);
      expect(vtmPublishedCount(records), 1);
    });

    test('value in flight excludes what has floated', () {
      expect(vtmTotalValue(records), 1000);
      expect(vtmInProgressValue(records), 600);
    });

    test('average lead time uses published records only', () {
      expect(vtmAveragePublishedAging(records, asOf: asOf), 20.0);
      expect(vtmAveragePublishedAging([records.first], asOf: asOf), isNull);
    });

    test('status and document type counts key by what was sent', () {
      expect(vtmStatusCounts(records)['DRAFT'], 1);
      expect(vtmDocumentTypeCounts(records)['Tender'], 4);
    });
  });

  group('flags', () {
    test('a rejection with no reason is urgent', () {
      final record = build(status: 'REJECTED_BY_EXEC');
      final flags = vtmFlags([record], asOf: asOf);
      expect(flags.first.label, 'Rejected with no reason given');
      expect(flags.first.severity, VtmFlagSeverity.high);
    });

    test('a rejection with a reason is not flagged for it', () {
      final record = build(
        status: 'REJECTED_BY_EXEC',
        remarks: 'Kod Bidang does not match the scope.',
      );
      expect(
        vtmFlags([record], asOf: asOf).map((f) => f.label),
        isNot(contains('Rejected with no reason given')),
      );
    });

    test('a rejection left sitting is urgent, other waits are not', () {
      final rejected = build(
        status: 'REJECTED_BY_EXEC',
        endorsed: '2026-08-01',
        remarks: 'Please correct.',
      );
      final waiting = build(status: 'SUBMITTED', endorsed: '2026-08-01');

      expect(
        vtmFlags([rejected], asOf: asOf).single.severity,
        VtmFlagSeverity.high,
      );
      expect(
        vtmFlags([waiting], asOf: asOf).single.severity,
        VtmFlagSeverity.medium,
      );
    });

    test('approved but not floated is raised', () {
      final record = build(status: 'APPROVED_BY_MANAGER');
      expect(
        vtmFlags([record], asOf: asOf).map((f) => f.label),
        contains('Approved, not floated'),
      );
    });

    test('published with no number is raised', () {
      final record = build(
        status: 'PUBLISHED',
        endorsed: '2026-09-22',
        floating: '2026-09-25',
      );
      expect(
        vtmFlags([record], asOf: asOf).map((f) => f.label),
        contains('Published with no tender number'),
      );
    });

    test('a clean record raises nothing', () {
      final record = build(
        status: 'PUBLISHED',
        tenderQuotationNo: 'T.10021',
        endorsed: '2026-09-22',
        floating: '2026-09-25',
      );
      expect(vtmFlags([record], asOf: asOf), isEmpty);
    });

    test('urgent flags sort above the ones that can wait', () {
      final urgent = build(erfcNo: 'E/1', status: 'REJECTED_BY_EXEC');
      final medium = build(erfcNo: 'E/2', status: 'APPROVED_BY_MANAGER');
      final flags = vtmFlags([medium, urgent], asOf: asOf);
      expect(flags.first.severity, VtmFlagSeverity.high);
      expect(flags.last.severity, VtmFlagSeverity.medium);
    });
  });

  group('filters', () {
    test('the two numbers are searched separately', () {
      const byErfc = VtmMonitoringFilters(erfcNoQuery: '00000041');
      expect(byErfc.matches(build()), isTrue);

      // A row with no tender number matches no tender-number search, which
      // is why the eRFC number is the one that leads the panel.
      const byTender = VtmMonitoringFilters(tenderNoQuery: 'T.10');
      expect(byTender.matches(build()), isFalse);
      expect(byTender.matches(build(tenderQuotationNo: 'T.10021')), isTrue);
    });

    test('status filters on the code, not the label', () {
      final filters = VtmMonitoringFilters(
        statuses: VtmStatus.codesOf({VtmStatus.rejectedByExec}),
      );
      expect(filters.matches(build(status: 'REJECTED_BY_EXEC')), isTrue);
      expect(filters.matches(build()), isFalse);
    });

    test('mode, division and document type each narrow on their own', () {
      expect(
        const VtmMonitoringFilters(modeOfProcurement: '7.2').matches(build()),
        isFalse,
      );
      expect(
        const VtmMonitoringFilters(division: 'Transmission Division')
            .matches(build()),
        isFalse,
      );
      expect(
        const VtmMonitoringFilters(documentType: 'Quotation').matches(build()),
        isFalse,
      );
    });

    test('toggling a status group twice clears it', () {
      const filters = VtmMonitoringFilters();
      final rejected = VtmStatus.codesOf({VtmStatus.rejectedByExec});
      expect(filters.toggleStatuses(rejected).statuses, rejected);
      expect(
        filters.toggleStatuses(rejected).toggleStatuses(rejected).statuses,
        isEmpty,
      );
    });

    test('copyWith clears a nullable field rather than ignoring null', () {
      const filters = VtmMonitoringFilters(modeOfProcurement: '7.1');
      expect(
        filters.copyWith(modeOfProcurement: null).modeOfProcurement,
        isNull,
      );
      expect(filters.copyWith(erfcNoQuery: 'x').modeOfProcurement, '7.1');
    });

    test('isEmpty is true only with nothing set', () {
      expect(const VtmMonitoringFilters().isEmpty, isTrue);
      expect(const VtmMonitoringFilters(division: 'X').isEmpty, isFalse);
    });

    test('the filter offers the seven statuses and five modes', () {
      expect(VtmMonitoringFilters.statusOptions, hasLength(7));
      expect(VtmMonitoringFilters.modeOptions, [
        '7.1',
        '7.2',
        '7.3',
        '7.5',
        '7.6',
      ]);
    });
  });

  group('the sample set', () {
    for (final day in [
      DateTime(2026, 9, 28),
      DateTime(2026, 1, 1),
      DateTime(2026, 12, 31),
      DateTime(2028, 2, 29),
    ]) {
      test('read on ${day.year}-${day.month}-${day.day}', () {
        final records = [
          for (final json in buildVtmMonitoringRecords(asOf: day))
            VtmMonitoringRecord.fromJson(json),
        ];
        expect(records, hasLength(8));

        // One row per status, as the spec's byStatus summary says.
        for (final status in VtmStatus.values) {
          expect(
            vtmCountWithStatus(records, status),
            greaterThan(0),
            reason: 'nothing reads as ${status.code}',
          );
        }
        expect(vtmDocumentTypeCounts(records), {'Tender': 5, 'Quotation': 3});
      });
    }

    test('only approved or published rows carry a tender number', () {
      for (final json in buildVtmMonitoringRecords(asOf: asOf)) {
        final record = VtmMonitoringRecord.fromJson(json);
        if (record.tenderQuotationNo == null) continue;
        expect(
          record.statusValue,
          anyOf(VtmStatus.approvedByManager, VtmStatus.published),
          reason: '${record.erfcNo} has a number before it was approved',
        );
      }
    });

    test('every rejected row says why', () {
      for (final json in buildVtmMonitoringRecords(asOf: asOf)) {
        final record = VtmMonitoringRecord.fromJson(json);
        if (!record.isRejected) continue;
        expect(
          record.rejectionRemarks,
          isNotNull,
          reason: '${record.erfcNo} was rejected with no reason',
        );
      }
    });

    test('the step trail never runs backwards', () {
      // Endorsed, submitted, verified, approved, floated — each step can be
      // missing, but none may predate the one before it.
      for (final json in buildVtmMonitoringRecords(asOf: asOf)) {
        final record = VtmMonitoringRecord.fromJson(json);
        final trail = <DateTime>[
          ?record.endorsedDate,
          ?record.submittedDate,
          ?record.verifiedDate,
          ?record.approvedDate,
          ?record.floatingDate,
        ];
        for (var i = 1; i < trail.length; i++) {
          expect(
            trail[i].isBefore(trail[i - 1]),
            isFalse,
            reason: '${record.erfcNo} step ${i + 1} predates step $i',
          );
        }
      }
    });

    test('every mode in the sample is one the filter offers', () {
      for (final json in buildVtmMonitoringRecords(asOf: asOf)) {
        final record = VtmMonitoringRecord.fromJson(json);
        expect(
          VtmProcurementMode.fromCode(record.modeOfProcurement),
          isNotNull,
          reason: '${record.erfcNo} uses mode ${record.modeOfProcurement}',
        );
      }
    });
  });
}
