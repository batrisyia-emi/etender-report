import 'package:etender_reports/reports/procurement_lead_time/lead_time_rules.dart';
import 'package:etender_reports/reports/procurement_lead_time/models/lead_time_query.dart';
import 'package:etender_reports/reports/procurement_lead_time/models/lead_time_record.dart';
import 'package:etender_reports/reports/procurement_lead_time/services/lead_time_service.dart';
import 'package:etender_reports/reports/procurement_lead_time/services/working_day_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

/// A measured tender with [workingDays], skipping the calculator.
MeasuredLeadTime _measured(
  int workingDays, {
  DocumentType type = DocumentType.tender,
  int index = 0,
}) {
  final record = LeadTimeRecord(
    tenderNo: '${type == DocumentType.tender ? 'T' : 'Q'}.${10000 + index}',
    projectTitle: 'Project $index',
    procurementMode: '7.1',
    erfcNo: 'ERFC/2026/$index',
    division: 'Distribution',
    vtmReceivedDate: DateTime(2026, 11, 2),
    publishedDate: DateTime(2026, 11, 2),
  );
  return MeasuredLeadTime(
    record: record,
    documentType: type,
    workingDays: workingDays,
  );
}

/// [fast] in 1–3 working days, [medium] in 4–7, [slow] over 7.
List<MeasuredLeadTime> _spread({int fast = 0, int medium = 0, int slow = 0}) {
  var index = 0;
  return [
    for (var i = 0; i < fast; i++) _measured(2, index: index++),
    for (var i = 0; i < medium; i++) _measured(5, index: index++),
    for (var i = 0; i < slow; i++) _measured(10, index: index++),
  ];
}

void main() {
  group('bucket boundaries', () {
    test('3 is 1–3, 4 and 7 are 4–7, 8 is more than 7', () {
      expect(LeadTimeRules.bucketFor(1), LeadTimeRules.workingDays1To3);
      expect(LeadTimeRules.bucketFor(3), LeadTimeRules.workingDays1To3);
      expect(LeadTimeRules.bucketFor(4), LeadTimeRules.workingDays4To7);
      expect(LeadTimeRules.bucketFor(7), LeadTimeRules.workingDays4To7);
      expect(LeadTimeRules.bucketFor(8), LeadTimeRules.workingDaysOver7);
    });
  });

  group('percentages', () {
    double sumOf(Map<String, double> percentages) =>
        (percentages.values.fold(0.0, (a, b) => a + b) * 100).round() / 100;

    test('sum to 100.00 for non-empty input', () {
      final summary = LeadTimeService.summarise(
        DocumentType.tender,
        _spread(fast: 13, medium: 4, slow: 3),
      );
      expect(summary.percentIn(LeadTimeRules.workingDays1To3), 65.00);
      expect(summary.percentIn(LeadTimeRules.workingDays4To7), 20.00);
      expect(summary.percentIn(LeadTimeRules.workingDaysOver7), 15.00);
      expect(sumOf(summary.percentages), 100.00);
      expect(summary.totalPercent, 100.00);
    });

    test('sum to 100.00 even when each share rounds down (1/3 each)', () {
      final summary = LeadTimeService.summarise(
        DocumentType.tender,
        _spread(fast: 1, medium: 1, slow: 1),
      );
      expect(sumOf(summary.percentages), 100.00);
      expect(summary.percentIn(LeadTimeRules.workingDays1To3), 33.34);
      expect(summary.percentIn(LeadTimeRules.workingDays4To7), 33.33);
    });

    test('all 0.00 for empty input', () {
      final summary = LeadTimeService.summarise(DocumentType.tender, const []);
      expect(summary.total, 0);
      for (final bucket in LeadTimeRules.buckets) {
        expect(summary.countIn(bucket), 0);
        expect(summary.percentIn(bucket), 0.00);
      }
      expect(summary.totalPercent, 0.00);
      expect(summary.within3WorkingDaysPercent, 0.00);
      expect(summary.within7WorkingDaysPercent, 0.00);
    });
  });

  group('rating', () {
    test('19/20 within 3 working days is Excellent', () {
      final summary = LeadTimeService.summarise(
        DocumentType.tender,
        _spread(fast: 19, slow: 1),
      );
      expect(summary.rating, PerformanceRating.excellent);
    });

    test(
      '18/20 within 3 working days and 19/20 within 7 working days is Good',
      () {
        final summary = LeadTimeService.summarise(
          DocumentType.tender,
          _spread(fast: 18, medium: 1, slow: 1),
        );
        expect(summary.rating, PerformanceRating.good);
      },
    );

    test('15/20 within 7 working days is Below Expectations', () {
      final summary = LeadTimeService.summarise(
        DocumentType.tender,
        _spread(fast: 10, medium: 5, slow: 5),
      );
      expect(summary.rating, PerformanceRating.belowExpectations);
    });
  });

  group('first published date', () {
    test('only the first Published date is the published date', () {
      final record = LeadTimeRecord.fromPublishHistory(
        tenderNo: 'T.10001',
        projectTitle: 'Re-published after addendum',
        procurementMode: '7.1',
        erfcNo: 'ERFC/2026/1',
        division: 'Distribution',
        vtmReceivedDate: DateTime(2026, 11, 2, 9),
        // Out of order on purpose: the source may not sort them.
        publishedDates: [
          DateTime(2026, 11, 12, 10),
          DateTime(2026, 11, 4, 15),
          DateTime(2026, 11, 9, 11),
        ],
      );
      expect(record.publishedDate, DateTime(2026, 11, 4, 15));

      final measured = LeadTimeService(WorkingDayCalculator())
          .measure([record]);
      expect(measured.single.workingDays, 3);
      expect(measured.single.bucket, LeadTimeRules.workingDays1To3);
    });
  });

  group('measure', () {
    LeadTimeRecord record(String tenderNo, String mode) => LeadTimeRecord(
      tenderNo: tenderNo,
      projectTitle: tenderNo,
      procurementMode: mode,
      erfcNo: 'ERFC',
      division: 'Distribution',
      vtmReceivedDate: DateTime(2026, 11, 2),
      publishedDate: DateTime(2026, 11, 5),
    );

    test('maps T./Q./Z. prefixes and drops non open-tender modes', () {
      final measured = LeadTimeService(WorkingDayCalculator()).measure([
        record('T.1', '7.1'),
        record('Q.2', '7.5'),
        record('Z.3', '7.6'),
        record('T.4', '7.4'), // not an open-tender mode
        record('X.5', '7.1'), // unknown prefix
      ]);
      expect(
        [for (final m in measured) (m.record.tenderNo, m.documentType)],
        [
          ('T.1', DocumentType.tender),
          ('Q.2', DocumentType.quotation),
          ('Z.3', DocumentType.quotation),
        ],
      );
      expect(measured.first.workingDays, 4);
    });

    test('summary lists items slowest first', () {
      final summary = LeadTimeService.summarise(DocumentType.tender, [
        _measured(2, index: 1),
        _measured(9, index: 2),
        _measured(5, index: 3),
      ]);
      expect([for (final i in summary.items) i.workingDays], [9, 5, 2]);
    });
  });

  group('date validation', () {
    test('both dates required', () {
      final errors = validateLeadTimeDates(null, null);
      expect(errors.from, isNotNull);
      expect(errors.to, isNotNull);
      expect(errors.isValid, isFalse);
    });

    test('From after To is rejected; same day is fine', () {
      expect(
        validateLeadTimeDates(
          DateTime(2026, 11, 5),
          DateTime(2026, 11, 4),
        ).isValid,
        isFalse,
      );
      expect(
        validateLeadTimeDates(
          DateTime(2026, 11, 4, 18),
          DateTime(2026, 11, 4, 9),
        ).isValid,
        isTrue,
      );
    });
  });
}
