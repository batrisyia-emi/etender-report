// test/report_sorting_test.dart
import 'package:etender_reports/reports/models/report_sorting.dart';
import 'package:flutter_test/flutter_test.dart';

final rows = [
  {'name': 'beta', 'value': 250000, 'date': '2026-08-05T14:30:00'},
  {'name': 'Alpha', 'value': 1200000, 'date': null},
  {'name': 'gamma', 'value': 85000, 'date': '2026-07-25T15:00:00'},
];

List<String> namesAfterSort(
  List<SortableColumn?> columns,
  int? index, {
  bool ascending = true,
}) => sortRecords(
  rows: rows,
  columns: columns,
  columnIndex: index,
  ascending: ascending,
).map((row) => row['name'] as String).toList();

void main() {
  final columns = [
    SortableColumn.text('name'),
    SortableColumn.number('value'),
    SortableColumn.date('date'),
    null, // an unsortable column
  ];

  test('numbers sort numerically, not as text', () {
    expect(namesAfterSort(columns, 1), ['gamma', 'beta', 'Alpha']);
    expect(namesAfterSort(columns, 1, ascending: false), [
      'Alpha',
      'beta',
      'gamma',
    ]);
  });

  test('text sorts case-insensitively', () {
    expect(namesAfterSort(columns, 0), ['Alpha', 'beta', 'gamma']);
  });

  test('nulls sort last ascending and descending', () {
    expect(namesAfterSort(columns, 2).last, 'Alpha');
    expect(namesAfterSort(columns, 2, ascending: false).last, 'Alpha');
  });

  test('a null column leaves the order untouched', () {
    expect(namesAfterSort(columns, 3), ['beta', 'Alpha', 'gamma']);
  });

  test('a null or out of range index leaves the order untouched', () {
    expect(namesAfterSort(columns, null), ['beta', 'Alpha', 'gamma']);
    expect(namesAfterSort(columns, 99), ['beta', 'Alpha', 'gamma']);
  });

  test('the source list is never sorted in place', () {
    final before = rows.map((row) => row['name']).toList();
    sortRecords(rows: rows, columns: columns, columnIndex: 1);
    expect(rows.map((row) => row['name']).toList(), before);
  });

  test('a computed column sorts on its derived value', () {
    final computed = [
      SortableColumn.computed((row) => (row['name'] as String).length),
    ];
    expect(namesAfterSort(computed, 0), ['beta', 'Alpha', 'gamma']);
  });
}
