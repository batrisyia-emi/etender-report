// lib/reports/widgets/report_status_panel.dart
import 'package:etender_reports/shared/app_colors.dart';
import 'package:flutter/material.dart';

import 'package:etender_reports/reports/widgets/shared/report_panel.dart';

/// Bordered panel with the standard blue header. Used for load failures and
/// for reports that are not built yet.
class ReportMessagePanel extends StatelessWidget {
  const ReportMessagePanel({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ReportPanel(
      title: title,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
        ),
      ),
    );
  }
}

class ReportLoadingIndicator extends StatelessWidget {
  const ReportLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(48),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
