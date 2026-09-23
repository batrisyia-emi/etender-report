// lib/reports/models/records/record_parsing.dart
//
// Every field a record reads from JSON goes through one of these, so a
// missing or oddly typed value fails in one place with one rule rather than
// at each call site.

/// Empty strings become null: the API contract says null means "no value",
/// and treating "" as a value is what produces blank-but-present cells.
String? asStringOrNull(Object? value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) return null;
  return text;
}

String asString(Object? value, {String fallback = ''}) =>
    asStringOrNull(value) ?? fallback;

double? asDoubleOrNull(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

double asDouble(Object? value, {double fallback = 0}) =>
    asDoubleOrNull(value) ?? fallback;

int? asIntOrNull(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  final text = value?.toString() ?? '';
  return int.tryParse(text) ?? double.tryParse(text)?.round();
}

int asInt(Object? value, {int fallback = 0}) => asIntOrNull(value) ?? fallback;

/// Accepts a real bool, and the strings a lax backend might send.
bool asBool(Object? value) {
  if (value is bool) return value;
  final text = value?.toString().toLowerCase();
  return text == 'true' || text == 'yes' || text == '1';
}

DateTime? asDateOrNull(Object? value) {
  if (value is DateTime) return value;
  return DateTime.tryParse(value?.toString() ?? '');
}
