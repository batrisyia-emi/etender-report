// lib/reports/widgets/shared/export_menu.dart
import 'package:etender_reports/reports/models/report_export.dart';
import 'package:etender_reports/shared/app_colors.dart';
import 'package:flutter/material.dart';

class ExportMenu extends StatelessWidget {
  const ExportMenu({
    super.key,
    required this.onExport,
    this.isExporting = false,
    this.label = 'Export',
    this.tooltip = 'Export these records',
  });

  final ValueChanged<ExportFormat> onExport;
  final bool isExporting;
  final String label;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    if (isExporting) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: SizedBox(
          height: 14,
          width: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return PopupMenuButton<ExportFormat>(
      tooltip: tooltip,
      position: PopupMenuPosition.under,
      onSelected: onExport,
      itemBuilder: (context) => [
        for (final format in ExportFormat.values)
          PopupMenuItem<ExportFormat>(
            value: format,
            height: 38,
            child: Row(
              children: [
                Icon(
                  format == ExportFormat.csv
                      ? Icons.description_outlined
                      : Icons.table_chart_outlined,
                  size: 16,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 8),
                Text(format.label, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.download_outlined,
              size: 14,
              color: AppColors.accent,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
