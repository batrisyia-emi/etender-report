// lib/reports/widgets/report_panel.dart
import 'package:etender_reports/shared/app_colors.dart';
import 'package:flutter/material.dart';

/// White bordered card with the blue title strip. Shared by the tables, the
/// message panel and anything else that needs the same frame.
class ReportPanel extends StatelessWidget {
  const ReportPanel({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.fillHeight = false,
  });

  final String title;
  final Widget child;

  /// Sits at the right end of the header, e.g. a record count pill.
  final Widget? trailing;

  /// Pass through when [child] must fill the remaining height.
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: fillHeight ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: const BoxDecoration(color: AppColors.panelHeader),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.heading,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          if (fillHeight) Expanded(child: child) else child,
        ],
      ),
    );
  }
}

/// The white pill showing a record count in a panel header.
class ReportCountPill extends StatelessWidget {
  const ReportCountPill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.blue.shade800,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
