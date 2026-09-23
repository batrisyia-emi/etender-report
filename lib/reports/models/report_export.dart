// lib/reports/models/report_export.dart
//
// Pure Dart: describes what a report exports and builds the CSV. The xlsx
// encoding lives in ReportExportService, so this file stays testable and
// package-free.

enum ExportFormat {
  csv('CSV', 'csv'),
  excel('Excel', 'xlsx');

  const ExportFormat(this.label, this.extension);

  final String label;
  final String extension;
}

/// One exported column. [read] returns the display string; [readNumber]
/// returns the underlying number when there is one, so spreadsheets get a
/// real numeric cell instead of "RM 250,000.00" as text.
class ExportColumn {
  const ExportColumn(this.label, this.read, {this.readNumber});

  final String label;
  final String Function(Map<String, dynamic> record) read;
  final num? Function(Map<String, dynamic> record)? readNumber;

  bool get isNumeric => readNumber != null;
}

class ExportTable {
  const ExportTable({
    required this.fileBaseName,
    required this.sheetName,
    required this.columns,
    required this.rows,
  });

  /// Timestamp is appended by the service.
  final String fileBaseName;
  final String sheetName;
  final List<ExportColumn> columns;
  final List<Map<String, dynamic>> rows;

  List<String> get headerRow => [for (final c in columns) c.label];
}

/// RFC 4180: quote anything containing a comma, quote or newline, and double
/// up embedded quotes.
String _escapeCsv(String value) {
  final needsQuotes =
      value.contains(',') || value.contains('"') || value.contains('\n');
  if (!needsQuotes) return value;
  return '"${value.replaceAll('"', '""')}"';
}

String buildCsv(ExportTable table) {
  final lines = <String>[table.headerRow.map(_escapeCsv).join(',')];

  for (final row in table.rows) {
    final cells = <String>[];
    for (final column in table.columns) {
      // Numbers go in unformatted so the spreadsheet can total them.
      final number = column.readNumber?.call(row);
      cells.add(
        number != null ? number.toString() : _escapeCsv(column.read(row)),
      );
    }
    lines.add(cells.join(','));
  }

  return lines.join('\r\n');
}
