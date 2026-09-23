// lib/reports/models/record_matching.dart
import 'package:flutter/material.dart' show DateTimeRange;

/// Records are untyped maps for now, so every read goes through these.
DateTime? parseRecordDate(dynamic value) =>
    DateTime.tryParse(value?.toString() ?? '');

/// Inclusive of both ends of [range]. A record with no date never matches an
/// active range.
bool matchesDateRange(DateTime? recordDate, DateTimeRange? range) {
  if (range == null) return true;
  if (recordDate == null) return false;

  final start = DateTime(range.start.year, range.start.month, range.start.day);
  final endExclusive = DateTime(
    range.end.year,
    range.end.month,
    range.end.day + 1,
  );
  return !recordDate.isBefore(start) && recordDate.isBefore(endExclusive);
}

/// Case-insensitive contains across [keys].
bool matchesQuery(
  Map<String, dynamic> record,
  List<String> keys,
  String rawQuery,
) {
  final query = rawQuery.trim().toLowerCase();
  if (query.isEmpty) return true;
  return keys.any(
    (key) => (record[key]?.toString().toLowerCase() ?? '').contains(query),
  );
}

bool matchesAnyOf(Set<String> selected, dynamic value) =>
    selected.isEmpty || selected.contains(value);

bool matchesOptional(String? selected, dynamic value) =>
    selected == null || value == selected;

List<String> distinctValues(List<Map<String, dynamic>> records, String key) {
  return records
      .map((record) => record[key]?.toString())
      .whereType<String>()
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList();
}
