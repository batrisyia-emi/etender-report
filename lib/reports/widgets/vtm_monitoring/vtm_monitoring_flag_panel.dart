// lib/reports/widgets/vtm_monitoring/vtm_monitoring_flag_panel.dart
import 'package:etender_reports/reports/models/metrics/vtm_monitoring_metrics.dart';
import 'package:etender_reports/reports/models/records/vtm_monitoring_record.dart';
import 'package:etender_reports/reports/widgets/shared/report_panel.dart';
import 'package:etender_reports/shared/app_colors.dart';
import 'package:flutter/material.dart';

/// The documents that need chasing, urgent ones first.
///
/// Four things trip a finding: a rejection with no reason given, anything
/// sitting past the threshold, an approval nobody has floated, and a
/// published document with no number.
class VtmMonitoringFlagPanel extends StatelessWidget {
  const VtmMonitoringFlagPanel({super.key, required this.records});

  final List<VtmMonitoringRecord> records;

  @override
  Widget build(BuildContext context) {
    final flags = vtmFlags(records);

    // No title: the CollapsibleSection above already carries one and the
    // count, and rendering both put the same words on two lines.
    return ReportPanel(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: flags.isEmpty
            ? const Text(
                'Every document in the current selection is moving, has its '
                'reasons recorded and carries the number it should.',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < flags.length; index++)
                    _FlagRow(
                      flag: flags[index],
                      // The panel supplies the gap under the last row.
                      isLast: index == flags.length - 1,
                    ),
                ],
              ),
      ),
    );
  }
}

class _FlagRow extends StatelessWidget {
  const _FlagRow({required this.flag, this.isLast = false});

  final VtmFlag flag;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final urgent = flag.severity == VtmFlagSeverity.high;
    final accent = urgent ? Colors.red.shade700 : Colors.orange.shade800;
    final tint = urgent ? const Color(0xFFFEF2F2) : const Color(0xFFFFF7ED);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Container(
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              urgent ? Icons.error_outline : Icons.schedule,
              size: 18,
              color: accent,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        // The eRFC number, since most rows have no tender
                        // number to identify them by yet.
                        flag.record.erfcNo,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.heading,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          flag.label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    flag.detail,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
