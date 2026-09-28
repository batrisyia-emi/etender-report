// lib/reports/widgets/toc/toc_workload_panel.dart
import 'package:etender_reports/reports/models/metrics/toc_metrics.dart';
import 'package:etender_reports/reports/models/records/toc_opening_record.dart';
import 'package:etender_reports/reports/widgets/shared/report_panel.dart';
import 'package:etender_reports/shared/app_colors.dart';
import 'package:flutter/material.dart';

/// Who is sitting on how many committees, busiest first.
///
/// The blueprint sets no ceiling on how many committees one officer may
/// join, which is the reason to show this: the constraint is the person's
/// calendar, and only this view makes it visible before an opening day is
/// double-booked.
class TocCommitteeWorkloadPanel extends StatelessWidget {
  const TocCommitteeWorkloadPanel({super.key, required this.records});

  final List<TocOpeningRecord> records;

  /// Beyond this the list stops being scannable; the table below carries
  /// the rest.
  static const int _maxRows = 8;

  @override
  Widget build(BuildContext context) {
    final workload = tocCommitteeWorkload(records);
    final busiest = workload.isEmpty ? 0 : workload.first.total;
    final shown = workload.take(_maxRows).toList();

    // No title, for the same reason as the exception panel: the
    // CollapsibleSection above it already carries one.
    return ReportPanel(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: workload.isEmpty
            ? const Text(
                'No committees have been appointed in the current selection, '
                'so there is no workload to show yet.',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < shown.length; index++)
                    _WorkloadRow(
                      person: shown[index],
                      fraction: busiest == 0 ? 0 : shown[index].total / busiest,
                      // The panel, or the "N more" line, supplies the gap
                      // under the last row.
                      isLast:
                          index == shown.length - 1 &&
                          workload.length == shown.length,
                    ),
                  if (workload.length > shown.length)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${workload.length - shown.length} more officers '
                        'sitting on one committee each',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _WorkloadRow extends StatelessWidget {
  const _WorkloadRow({
    required this.person,
    required this.fraction,
    this.isLast = false,
  });

  final TocMemberWorkload person;
  final double fraction;
  final bool isLast;

  static const double _barHeight = 8;

  @override
  Widget build(BuildContext context) {
    final upcoming = person.upcomingOpenings;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  person.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.heading,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                person.asChairman == 0
                    ? '${person.total} as member'
                    : '${person.total} total, ${person.asChairman} as chair',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(_barHeight / 2),
            child: LinearProgressIndicator(
              value: fraction.clamp(0, 1),
              minHeight: _barHeight,
              backgroundColor: const Color(0xFFEEF2F7),
              // Chairing carries the paperwork, so a chair-heavy load reads
              // as the heavier one.
              valueColor: AlwaysStoppedAnimation<Color>(
                person.asChairman > 0
                    ? AppColors.accent
                    : Colors.blueGrey.shade300,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            upcoming == 0
                ? '${person.division} - no openings ahead'
                : '${person.division} - $upcoming opening'
                      '${upcoming == 1 ? '' : 's'} still ahead',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
