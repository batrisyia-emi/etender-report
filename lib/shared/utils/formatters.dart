// lib/utils/formatters.dart
import 'package:flutter/material.dart' show DateTimeRange;

String formatLastUpdate(dynamic value) {
  final text = value?.toString() ?? '';
  if (text.isEmpty) return '';

  final normalized = text.contains('T')
      ? text
      : text.contains(' ')
      ? text.replaceFirst(' ', 'T')
      : '$text T00:00:00';

  try {
    final dateTime = DateTime.parse(normalized);
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  } catch (_) {
    return text;
  }
}

/// Date without a time, for columns the spec shows as dates only.
/// Returns an em dash when there is no parsable date.
String formatDateOnly(dynamic value) {
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  if (parsed == null) return '—';
  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  return '$day/$month/${parsed.year}';
}

String formatDateRange(DateTimeRange? range) {
  if (range == null) return 'Any date range';

  String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  return '${formatDate(range.start)} - ${formatDate(range.end)}';
}

/// Groups thousands with commas: 1535000 -> "1,535,000.00".
String formatNumber(dynamic value, {int decimals = 2}) {
  final amount = (value as num?)?.toDouble() ?? 0;
  final fixed = amount.abs().toStringAsFixed(decimals);

  final separatorIndex = fixed.indexOf('.');
  final whole = separatorIndex == -1
      ? fixed
      : fixed.substring(0, separatorIndex);
  final fraction = separatorIndex == -1 ? '' : fixed.substring(separatorIndex);

  final grouped = StringBuffer();
  for (var index = 0; index < whole.length; index++) {
    if (index > 0 && (whole.length - index) % 3 == 0) grouped.write(',');
    grouped.write(whole[index]);
  }

  return '${amount < 0 ? '-' : ''}$grouped$fraction';
}

/// Ringgit amount: "RM 250,000.00". Pass decimals: 0 for whole ringgit.
String formatValue(dynamic value, {int decimals = 2}) {
  return 'RM ${formatNumber(value, decimals: decimals)}';
}
