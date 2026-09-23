// lib/reports/models/report_sorting.dart
//
// Pure Dart. A sortable column reads one Comparable out of a record, so the
// same machinery sorts text, numbers and dates, including derived values
// like eRFC aging.

/// [read] returns null when the record has no value for this column; those
/// rows sort last whichever direction is chosen, so an empty Approved Date
/// never sits above a real one.
class SortableColumn {
  const SortableColumn(this.read);

  final Comparable<Object>? Function(Map<String, dynamic> record) read;

  /// Case-insensitive text, so "acme" and "Acme" sort together.
  static SortableColumn text(String key) => SortableColumn((record) {
    final value = record[key]?.toString();
    if (value == null || value.isEmpty) return null;
    return value.toLowerCase();
  });

  static SortableColumn number(String key) => SortableColumn((record) {
    final value = num.tryParse(record[key]?.toString() ?? '');
    return value as Comparable<Object>?;
  });

  static SortableColumn date(String key) => SortableColumn((record) {
    final value = DateTime.tryParse(record[key]?.toString() ?? '');
    return value as Comparable<Object>?;
  });

  /// Yes / No columns stored as bool. True sorts after false ascending.
  static SortableColumn flag(String key) =>
      SortableColumn((record) => record[key] == true ? 1 : 0);

  /// For values that are computed rather than stored.
  static SortableColumn computed(
    Comparable<Object>? Function(Map<String, dynamic> record) read,
  ) => SortableColumn(read);
}

/// Returns a new list; never sorts [rows] in place, because the caller's list
/// may be the bloc's immutable record list.
///
/// A null [columnIndex], an out of range index, or a column marked
/// unsortable all leave the order untouched.
List<Map<String, dynamic>> sortRecords({
  required List<Map<String, dynamic>> rows,
  required List<SortableColumn?> columns,
  int? columnIndex,
  bool ascending = true,
}) {
  if (columnIndex == null || columnIndex < 0 || columnIndex >= columns.length) {
    return rows;
  }
  final column = columns[columnIndex];
  if (column == null) return rows;

  final sorted = [...rows];
  sorted.sort((a, b) {
    final left = column.read(a);
    final right = column.read(b);
    if (left == null && right == null) return 0;
    if (left == null) return 1;
    if (right == null) return -1;
    final result = Comparable.compare(left, right);
    return ascending ? result : -result;
  });
  return sorted;
}
