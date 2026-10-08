// test/models/report_criteria_test.dart
//
// The report header states what the rows were filtered by. If that
// description drifts from the filters, the header lies — and a lying
// header is worse than none, because it travels with the numbers.
import 'package:etender_reports/reports/models/filters/report_criteria.dart';
import 'package:etender_reports/reports/models/filters/report_filters.dart';
import 'package:etender_reports/reports/models/filters/tender_security_filters.dart';
import 'package:etender_reports/reports/models/filters/toc_filters.dart';
import 'package:etender_reports/reports/models/filters/vtm_monitoring_filters.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_test/flutter_test.dart';

/// Every criterion rendered as "Label: value", for terse assertions.
List<String> lines(List<ReportCriterion> criteria) =>
    criteria.map((c) => c.toString()).toList();

void main() {
  group('an untouched filter set describes nothing', () {
    test('every report starts with no criteria', () {
      // The header prints "None applied — all records" off the back of
      // this, so an accidental default would claim a filter nobody set.
      expect(const TenderFilters().describe(), isEmpty);
      expect(const VendorFilters().describe(), isEmpty);
      expect(const ErfcFilters().describe(), isEmpty);
      expect(const SupplierFilters().describe(), isEmpty);
      expect(const TocFilters().describe(), isEmpty);
      expect(const TenderSecurityFilters().describe(), isEmpty);
      expect(const VtmMonitoringFilters().describe(), isEmpty);
    });

    test('a blank search box is not a criterion', () {
      expect(const TenderFilters(searchQuery: '   ').describe(), isEmpty);
    });
  });

  group('TenderFilters', () {
    test('names only what was set', () {
      const filters = TenderFilters(
        statuses: {'Published', 'Extended'},
        divisions: {'Distribution'},
      );

      expect(lines(filters.describe()), [
        'Status: Extended, Published',
        'Division: Distribution',
      ]);
    });

    test('sorts values so the same selection reads the same way', () {
      const a = TenderFilters(statuses: {'Published', 'Extended'});
      const b = TenderFilters(statuses: {'Extended', 'Published'});
      expect(lines(a.describe()), lines(b.describe()));
    });

    test('summarises a long selection instead of running off the line', () {
      const filters = TenderFilters(divisions: {'A', 'B', 'C', 'D', 'E', 'F'});
      expect(lines(filters.describe()), ['Division: A, B, C, D and 2 more']);
    });

    test('four values are still named in full', () {
      const filters = TenderFilters(divisions: {'A', 'B', 'C', 'D'});
      expect(lines(filters.describe()), ['Division: A, B, C, D']);
    });

    test('a search term is quoted so a one-word filter is obvious', () {
      expect(lines(const TenderFilters(searchQuery: 'substation').describe()), [
        'Search: "substation"',
      ]);
    });

    test('an open-ended value band reads as a bound, not a range', () {
      expect(
        lines(const TenderFilters(minimumValue: 50000).describe()).single,
        contains('and above'),
      );
      expect(
        lines(const TenderFilters(maximumValue: 50000).describe()).single,
        startsWith('Value: up to'),
      );
      expect(
        lines(
          const TenderFilters(
            minimumValue: 1000,
            maximumValue: 5000,
          ).describe(),
        ).single,
        contains(' to '),
      );
    });

    test('a date range is described', () {
      final filters = TenderFilters(
        closingDateRange: DateTimeRange(
          start: DateTime(2026, 9),
          end: DateTime(2026, 10, 31),
        ),
      );
      expect(filters.describe().single.label, 'Closing');
      expect(filters.describe().single.value, isNotEmpty);
    });
  });

  group('flags and named views', () {
    test('a boolean filter describes what it means, not "true"', () {
      expect(lines(const ErfcFilters(overdueOnly: true).describe()), [
        'Overdue: overdue only',
      ]);
      expect(const ErfcFilters().describe(), isEmpty);
    });

    test('the tender security view counts as a criterion', () {
      expect(
        lines(
          const TenderSecurityFilters(view: TenderSecurityView.pendingRefund)
              .describe(),
        ),
        ['View: Pending refund'],
      );
    });

    test('the default "all" view is not a criterion', () {
      expect(
        const TenderSecurityFilters(view: TenderSecurityView.all).describe(),
        isEmpty,
      );
    });
  });

  group('the other reports describe their own fields', () {
    test('TOC names the member search separately from the tender search', () {
      const filters = TocFilters(
        tenderNoQuery: 'T.10001',
        memberQuery: 'Alpha',
      );
      expect(lines(filters.describe()), [
        'Tender/Quotation no.: "T.10001"',
        'Committee member: "Alpha"',
      ]);
    });

    test('VTM leads with the eRFC number, which is its key', () {
      const filters = VtmMonitoringFilters(
        erfcNoQuery: 'RFC-1',
        tenderNoQuery: 'T.1',
      );
      expect(filters.describe().first.label, 'eRFC no.');
    });

    test('supplier and vendor filters describe their own vocabulary', () {
      expect(
        lines(const SupplierFilters(pendingPaymentOnly: true).describe()),
        ['Payment: pending payment only'],
      );
      expect(lines(const VendorFilters(invitationStatus: 'Sent').describe()), [
        'Invitation: Sent',
      ]);
    });
  });
}
