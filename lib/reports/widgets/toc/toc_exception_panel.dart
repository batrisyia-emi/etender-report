// lib/reports/widgets/toc/toc_exception_panel.dart
import 'package:etender_reports/shared/app_colors.dart';
import 'package:flutter/material.dart';

import 'package:etender_reports/reports/models/records/toc_opening_record.dart';
import 'package:etender_reports/reports/models/toc_metrics.dart';
import 'package:etender_reports/reports/widgets/shared/report_panel.dart';

/// The openings that need chasing, urgent ones first, each with the one
/// button that clears it.
///
/// Four things trip a flag, all of them about the process rather than the
/// bids: no committee with the closing date almost here, declarations still
/// unsigned on opening day, a committee cleared by an extension, and an
/// Appendix P that has not followed its Appendix G.
///
/// Each flag names its own remedy — see [TocRemedy] — so the button on a row
/// is decided by the rule that raised it, not by this widget guessing.
class TocExceptionPanel extends StatelessWidget {
  const TocExceptionPanel({
    super.key,
    required this.records,
    this.onRemedy,
    this.onView,
  });

  final List<TocOpeningRecord> records;

  /// The row's primary button. Null leaves it disabled, which is what a
  /// caller that has nothing to wire it to should do.
  final void Function(TocOpeningRecord record, TocRemedy remedy)? onRemedy;

  /// The row's quieter second button: open the opening's own record.
  final ValueChanged<TocOpeningRecord>? onView;

  @override
  Widget build(BuildContext context) {
    final flags = tocExceptionFlags(records);

    // No title: the CollapsibleSection wrapping this one already shows
    // "Needs Attention" and the urgent count, and rendering both put the
    // same words on two consecutive lines.
    return ReportPanel(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: flags.isEmpty
            ? const Text(
                'Every opening in the current selection has a committee, '
                'signed declarations and its paperwork up to date.',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < flags.length; index++)
                    _FlagRow(
                      flag: flags[index],
                      onRemedy: onRemedy,
                      onView: onView,
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
  const _FlagRow({
    required this.flag,
    this.onRemedy,
    this.onView,
    this.isLast = false,
  });

  final TocExceptionFlag flag;
  final void Function(TocOpeningRecord record, TocRemedy remedy)? onRemedy;
  final ValueChanged<TocOpeningRecord>? onView;
  final bool isLast;

  /// Width at which the buttons still fit beside the text. Below it they
  /// drop to their own line rather than squeezing the detail out.
  static const double _inlineButtonsBreakpoint = 560;

  static IconData _remedyIcon(TocRemedy remedy) => switch (remedy) {
    TocRemedy.appointCommittee => Icons.group_add_outlined,
    TocRemedy.startOpening => Icons.play_circle_outline,
    TocRemedy.openRecord => Icons.open_in_new,
    TocRemedy.fileAppendixP => Icons.assignment_turned_in_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final urgent = flag.severity == TocFlagSeverity.high;
    final accent = urgent ? Colors.red.shade700 : Colors.orange.shade800;
    final tint = urgent ? const Color(0xFFFEF2F2) : const Color(0xFFFFF7ED);

    // The remedy carries the row's own colour, so an urgent row reads as one
    // thing rather than a red warning next to a blue button.
    final remedyButton = FilledButton.icon(
      onPressed: onRemedy == null
          ? null
          : () => onRemedy!(flag.record, flag.remedy),
      icon: Icon(_remedyIcon(flag.remedy), size: 15),
      label: Text(flag.remedy.label),
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: accent.withValues(alpha: 0.35),
        disabledForegroundColor: Colors.white,
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );

    final viewButton = TextButton(
      onPressed: onView == null ? null : () => onView!(flag.record),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accent,
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      child: const Text('View'),
    );

    final buttons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [remedyButton, const SizedBox(width: 4), viewButton],
    );

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              flag.record.tenderNo,
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
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
      ],
    );

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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= _inlineButtonsBreakpoint) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: text),
                        const SizedBox(width: 12),
                        buttons,
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      text,
                      const SizedBox(height: 8),
                      Align(alignment: Alignment.centerLeft, child: buttons),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
