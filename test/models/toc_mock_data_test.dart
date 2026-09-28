// test/models/toc_mock_data_test.dart
//
// The sample set is a demo as much as a fixture: it is what someone sees
// when they open the report. These pin the things it is meant to show, at
// any date, because its dates are relative to the day it is read.
import 'package:etender_reports/data/mock/toc_records.dart';
import 'package:etender_reports/reports/models/metrics/toc_metrics.dart';
import 'package:etender_reports/reports/models/records/toc_opening_record.dart';
import 'package:etender_reports/reports/models/status/toc_status.dart';
import 'package:flutter_test/flutter_test.dart';

List<TocOpeningRecord> sampleAt(DateTime day) => [
  for (final json in buildTocRecords(asOf: day))
    TocOpeningRecord.fromJson(json),
];

/// A spread of days, including ones that catch month and year rollover and
/// a leap day, since every date is `base.day + offset`.
final List<DateTime> days = [
  DateTime(2026, 9, 28),
  DateTime(2026, 1, 1),
  DateTime(2026, 1, 31),
  DateTime(2026, 3, 1),
  DateTime(2026, 12, 31),
  DateTime(2028, 2, 29),
];

void main() {
  for (final day in days) {
    final label = '${day.year}-${day.month}-${day.day}';

    group('read on $label', () {
      late List<TocOpeningRecord> records;

      setUp(() => records = sampleAt(day));

      test('parses every record', () {
        expect(records, hasLength(9));
        for (final record in records) {
          expect(record.tenderNo, isNotEmpty);
          expect(record.closingDateTime, isNotNull);
        }
      });

      test('every status is represented', () {
        for (final status in TocStatus.values) {
          expect(
            tocCountWithStatus(records, status),
            greaterThan(0),
            reason: 'nothing reads as ${status.wireValue}',
          );
        }
      });

      test('all four exception flags fire', () {
        final labels = tocExceptionFlags(
          records,
          asOf: day,
        ).map((flag) => flag.label).toSet();

        expect(
          labels,
          containsAll(<String>[
            'No committee, closing soon',
            'Opening day, not started',
            'Committee cleared by extension',
            'Appendix P overdue',
          ]),
        );
      });

      test('both severities are represented, urgent first', () {
        final flags = tocExceptionFlags(records, asOf: day);
        expect(flags.first.severity, TocFlagSeverity.high);
        expect(flags.last.severity, TocFlagSeverity.medium);
      });

      test(
        'one opening is closed out, so the average has something to average',
        () {
          expect(tocClosedOutCount(records), greaterThan(0));
          expect(tocAverageAging(records, asOf: day), isNotNull);
        },
      );

      test('the committee workload has someone on more than one', () {
        final workload = tocCommitteeWorkload(records, asOf: day);
        expect(workload, isNotEmpty);
        expect(workload.first.total, greaterThan(1));
      });

      test('no signature is dated after the opening it is for', () {
        for (final record in records) {
          final opening = record.openingDateTime;
          if (opening == null) continue;
          for (final member in record.committee) {
            for (final ack in [member.appendixIAckAt, member.appendixJAckAt]) {
              if (ack == null) continue;
              expect(
                ack.isAfter(opening),
                isFalse,
                reason:
                    '${record.tenderNo}: ${member.name} signed after the '
                    'opening',
              );
            }
          }
        }
      });
    });
  }

  test('no bid data reaches the sample set', () {
    // The report is read before evaluation. See docs/toc-report.md.
    const forbidden = [
      'hargaTawaran',
      'jadualHarga',
      'tempohSiap',
      'tempohSahLaku',
      'otpValue',
      'bidAmount',
    ];
    for (final json in buildTocRecords()) {
      for (final key in forbidden) {
        expect(json.keys, isNot(contains(key)));
      }
    }
  });
}
