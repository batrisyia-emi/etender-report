// test/widgets/table_sort_alignment_test.dart
//
// Each table matches its sort keys to its columns by position: column 6 is
// sorted by whatever sits at index 6 of its sort list. Nothing checks that
// at compile time, so adding or removing a column silently sorts by the
// wrong field — the table keeps working, it just answers a different
// question. Known issue 8 in the README.
//
// Removing the Unit column from the tender report is exactly that case: it
// shifted four sortable columns down by one.
import 'package:data_table_2/data_table_2.dart';
import 'package:etender_reports/data/mock/report_mock_data.dart';
import 'package:etender_reports/reports/models/records/tender_record.dart';
import 'package:etender_reports/reports/models/records/vendor_participation_record.dart';
import 'package:etender_reports/reports/models/sorting/report_sort_columns.dart';
import 'package:etender_reports/reports/models/sorting/report_sorting.dart';
import 'package:etender_reports/reports/widgets/shared/sortable_header.dart';
import 'package:etender_reports/reports/widgets/tender_summary/tender_data_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The columns the table actually renders.
List<DataColumn> columnsOf(WidgetTester tester) {
  final table = tester.widget<DataTable2>(find.byType(DataTable2));
  return table.columns;
}

/// A column's heading text, whichever widget is carrying it.
String? labelOf(DataColumn column) => switch (column.label) {
  final Text text => text.data,
  final SortableHeader header => header.label,
  _ => null,
};

Future<void> pumpTenderTable(WidgetTester tester) async {
  tester.view.physicalSize = const Size(2600, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(
        body: TenderDataTable(records: ReportMockData.tenderRecords),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('tender table', () {
    testWidgets('has no Unit column', (tester) async {
      await pumpTenderTable(tester);
      expect(find.text('Unit'), findsNothing);
    });

    testWidgets('shows the opening date after the published date', (
      tester,
    ) async {
      await pumpTenderTable(tester);
      final labels = columnsOf(tester).map(labelOf).toList();
      expect(
        labels.indexOf('Tender Opening Date'),
        labels.indexOf('Published Date') + 1,
        reason: 'the opening date sits immediately after the published date',
      );
    });

    test('a tender is never opened before it closes', () {
      // The rule the mock dates were generated under, and the one a real
      // endpoint has to honour. Null is fine: a tender still open has not
      // been opened.
      for (final json in ReportMockData.tenderRecords) {
        final record = TenderRecord.fromJson(json);
        final opening = record.openingDate;
        final closing = record.closingDate;
        if (opening == null || closing == null) continue;
        expect(
          opening.isBefore(closing),
          isFalse,
          reason: '${record.tenderNo} opens before it closes',
        );
      }
    });

    test('only closed tenders carry an opening date', () {
      for (final json in ReportMockData.tenderRecords) {
        final record = TenderRecord.fromJson(json);
        final open = {'Published', 'Extended'}.contains(record.status);
        expect(
          record.openingDate,
          open ? isNull : isNotNull,
          reason: '${record.tenderNo} is ${record.status}',
        );
      }
    });

    testWidgets('has one sort key per column', (tester) async {
      await pumpTenderTable(tester);

      // A short sort list means the last columns sort by nothing; a long one
      // means a column was removed and its key left behind.
      expect(
        tenderSortColumns,
        hasLength(columnsOf(tester).length),
        reason: 'the sort list and the columns have drifted apart',
      );
    });

    testWidgets('every sortable column has a key, and vice versa', (
      tester,
    ) async {
      await pumpTenderTable(tester);
      final columns = columnsOf(tester);

      for (var i = 0; i < columns.length; i++) {
        final tappable = columns[i].onSort != null;
        final hasKey = tenderSortColumns[i] != null;
        expect(
          tappable,
          hasKey,
          reason: tappable
              ? 'column $i looks sortable but has no sort key'
              : 'column $i has a sort key but cannot be tapped',
        );
      }
    });

    testWidgets('sorting by value really orders by value', (tester) async {
      // The check the alignment exists for: a misaligned index still sorts,
      // just by the wrong field, so only the resulting order shows it.
      await pumpTenderTable(tester);

      final valueIndex = tenderSortColumns.indexWhere((c) => c != null);
      final sorted = sortRecords(
        rows: ReportMockData.tenderRecords,
        columns: tenderSortColumns,
        columnIndex: valueIndex,
        ascending: true,
      );

      final values = [
        for (final row in sorted)
          double.tryParse(row['value']?.toString() ?? '') ?? 0,
      ];
      expect(
        values,
        orderedEquals(List<double>.from(values)..sort()),
        reason: 'the first sortable column did not order by value',
      );
    });
  });

  group('vendor participation table', () {
    test('a vendor never asks to take part after it has bid', () {
      // The rule the requested dates were derived under: the request comes
      // first. A backend sending them the other way round is a finding.
      for (final json in ReportMockData.vendorParticipationRecords) {
        final record = VendorParticipationRecord.fromJson(json);
        final requested = record.requestedDate;
        final submitted = record.submissionDateTime;
        if (requested == null || submitted == null) continue;
        expect(
          requested.isAfter(submitted),
          isFalse,
          reason: '${record.vendorName} on ${record.tenderNo}',
        );
      }
    });

    test('only invited vendors have a requested date', () {
      // Nothing to ask about without an invitation.
      for (final json in ReportMockData.vendorParticipationRecords) {
        final record = VendorParticipationRecord.fromJson(json);
        if (record.invitationStatus == 'Sent') continue;
        expect(
          record.requestedDate,
          isNull,
          reason: '${record.vendorName} was ${record.invitationStatus}',
        );
      }
    });

    test('participation has exactly two values', () {
      final values = {
        for (final json in ReportMockData.vendorParticipationRecords)
          json['participationStatus']?.toString(),
      };
      expect(values, {'Participated', 'Not Participated'});
    });
  });
}
