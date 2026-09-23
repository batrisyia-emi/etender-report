// lib/data/report_export_service.dart
//
// The only file that knows about the excel and file_saver packages. Swapping
// either out, or moving to a server-side export, should touch nothing else.
import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';

import 'package:etender_reports/reports/models/report_export.dart';

class ReportExportService {
  const ReportExportService();

  /// Writes the file and returns the name it was saved as.
  Future<String> export(ExportTable table, ExportFormat format) async {
    final fileName = '${table.fileBaseName}_${_timestamp(DateTime.now())}';

    final bytes = switch (format) {
      ExportFormat.csv => _buildCsvBytes(table),
      ExportFormat.excel => _buildExcelBytes(table),
    };

    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: bytes,
      // Called `ext` in file_saver 0.2.x and `fileExtension` from 0.3.0 on.
      fileExtension: format.extension,
      mimeType: format == ExportFormat.csv
          ? MimeType.csv
          : MimeType.microsoftExcel,
    );

    return '$fileName.${format.extension}';
  }

  /// The BOM makes Excel open a UTF-8 CSV without mangling accents.
  Uint8List _buildCsvBytes(ExportTable table) {
    return Uint8List.fromList(utf8.encode('\uFEFF${buildCsv(table)}'));
  }

  Uint8List _buildExcelBytes(ExportTable table) {
    final workbook = Excel.createExcel();
    final defaultSheet = workbook.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != table.sheetName) {
      workbook.rename(defaultSheet, table.sheetName);
    }
    final sheet = workbook[table.sheetName];

    sheet.appendRow([
      for (final label in table.headerRow) TextCellValue(label),
    ]);

    for (final row in table.rows) {
      sheet.appendRow([
        for (final column in table.columns)
          if (column.readNumber?.call(row) case final number?)
            DoubleCellValue(number.toDouble())
          else
            TextCellValue(column.read(row)),
      ]);
    }

    final encoded = workbook.encode();
    if (encoded == null) {
      throw StateError('Could not encode the workbook.');
    }
    return Uint8List.fromList(encoded);
  }

  String _timestamp(DateTime now) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}'
        '_${two(now.hour)}${two(now.minute)}';
  }
}
