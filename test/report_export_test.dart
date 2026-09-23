// test/report_export_test.dart
//
// CSV is where naive implementations break: commas, quotes and newlines
// inside a value all have to survive a round trip.
import 'package:etender_reports/reports/models/report_export.dart';
import 'package:flutter_test/flutter_test.dart';

ExportTable tableOf(List<Map<String, dynamic>> rows) => ExportTable(
  fileBaseName: 'test',
  sheetName: 'Test',
  columns: [
    ExportColumn('Title', (r) => r['title']?.toString() ?? ''),
    ExportColumn(
      'Value (RM)',
      (r) => 'RM ${r['value']}',
      readNumber: (r) => r['value'] as num?,
    ),
  ],
  rows: rows,
);

void main() {
  test('writes a header row from the column labels', () {
    final csv = buildCsv(tableOf([]));
    expect(csv, 'Title,Value (RM)');
  });

  test('quotes a value containing a comma', () {
    final csv = buildCsv(
      tableOf([
        {'title': 'Supply of Cables, Phase 2', 'value': 1200000},
      ]),
    );
    expect(csv, contains('"Supply of Cables, Phase 2"'));
  });

  test('doubles up embedded quotes', () {
    final csv = buildCsv(
      tableOf([
        {'title': 'Works "Package A"', 'value': 1},
      ]),
    );
    expect(csv, contains('"Works ""Package A"""'));
  });

  test('quotes a value containing a newline', () {
    final csv = buildCsv(
      tableOf([
        {'title': 'Line\nRefurbishment', 'value': 1},
      ]),
    );
    expect(csv, contains('"Line\nRefurbishment"'));
  });

  test('numeric columns are written raw so a spreadsheet can sum them', () {
    final csv = buildCsv(
      tableOf([
        {'title': 'Cables', 'value': 1200000},
      ]),
    );
    // Not "RM 1200000".
    expect(csv, contains(',1200000'));
    expect(csv, isNot(contains('RM 1200000')));
  });

  test('rows are separated by CRLF', () {
    final csv = buildCsv(
      tableOf([
        {'title': 'One', 'value': 1},
        {'title': 'Two', 'value': 2},
      ]),
    );
    expect(csv.split('\r\n').length, 3);
  });

  test('a value needing no quoting is left alone', () {
    final csv = buildCsv(
      tableOf([
        {'title': 'Plain title', 'value': 5},
      ]),
    );
    expect(csv, contains('\r\nPlain title,5'));
  });
}
