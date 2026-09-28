// lib/reports/views/cards/toc_kpi_cards.dart
//
// The summary cards for the TOC report.
//
// Every figure here counts records or days. None of them touch bid data —
// see the warning on [TocOpeningRecord].
import 'package:etender_reports/shared/utils/formatters.dart';
import 'package:flutter/material.dart';

import 'package:etender_reports/reports/models/records/toc_opening_record.dart';
import 'package:etender_reports/reports/models/toc_metrics.dart';
import 'package:etender_reports/reports/models/toc_status.dart';
import 'package:etender_reports/reports/widgets/shared/kpi_card.dart';

final Set<String> _open = TocStatus.wiresOf({TocStatus.open});
final Set<String> _appointed = TocStatus.wiresOf({
  TocStatus.committeeAppointed,
});
final Set<String> _completed = TocStatus.wiresOf({TocStatus.openingCompleted});

/// The five stages between "committee named" and "done", one-envelope and
/// two-envelope alike. Tapping the card shows all of them, because which
/// one a tender is at depends on how it takes its bids.
final Set<TocStatus> _underWayStatuses = {
  for (final status in TocStatus.values)
    if (status.isUnderWay) status,
};
final Set<String> _underWay = TocStatus.wiresOf(_underWayStatuses);

List<Widget> buildTocKpiCards({
  required List<TocOpeningRecord> records,
  ValueChanged<Set<String>>? onStatusTap,
}) {
  final open = tocCountWithStatus(records, TocStatus.open);
  final appointed = tocCountWithStatus(records, TocStatus.committeeAppointed);
  final underWay = tocCountWithStatuses(records, _underWayStatuses);
  final completed = tocCountWithStatus(records, TocStatus.openingCompleted);
  final averageAging = tocAverageAging(records);
  final flags = tocExceptionFlags(records);
  final urgent = flags
      .where((flag) => flag.severity == TocFlagSeverity.high)
      .length;

  /// Filters to [statuses], or clears that filter when it is already what
  /// is selected. Null when no record holds the status, so the card is
  /// inert rather than filtering the table down to nothing.
  VoidCallback? tapFor(Set<String> statuses, int count) =>
      count == 0 || onStatusTap == null ? null : () => onStatusTap(statuses);

  return [
    KpiCard(
      header: 'TOTAL OPENINGS',
      value: formatNumber(records.length, decimals: 0),
      icon: Icons.how_to_vote_outlined,
      footer: KpiBadgeFooter(
        badges: [
          if (open > 0) KpiBadge.grey('$open waiting'),
          if (underWay > 0) KpiBadge.orange('$underWay under way'),
          if (completed > 0) KpiBadge.green('$completed done'),
        ],
      ),
    ),
    KpiCard(
      header: 'OPEN',
      value: formatNumber(open, decimals: 0),
      icon: Icons.lock_open_outlined,
      iconTint: open > 0 ? kKpiGreyTint : kKpiGreyTint,
      iconColor: kKpiGreyText,
      onTap: tapFor(_open, open),
      footer: const KpiFooterText('Taking bids, nobody appointed yet'),
    ),
    KpiCard(
      header: 'COMMITTEE APPOINTED',
      value: formatNumber(appointed, decimals: 0),
      icon: Icons.groups_outlined,
      iconTint: kKpiBlueTint,
      iconColor: kKpiBlueText,
      onTap: tapFor(_appointed, appointed),
      footer: const KpiFooterText('Named, waiting on the opening day'),
    ),
    KpiCard(
      header: 'OPENING UNDER WAY',
      value: formatNumber(underWay, decimals: 0),
      icon: Icons.mark_email_read_outlined,
      iconTint: underWay > 0 ? kKpiOrangeTint : kKpiGreyTint,
      iconColor: underWay > 0 ? kKpiOrangeText : kKpiGreyText,
      onTap: tapFor(_underWay, underWay),
      // One envelope opens once; two opens the technical, holds the
      // commercial sealed, then opens it. All of that is "under way".
      footer: const KpiFooterText('Started, not yet closed out'),
    ),
    KpiCard(
      header: 'OPENING COMPLETED',
      value: formatNumber(completed, decimals: 0),
      icon: Icons.task_alt,
      iconTint: kKpiGreenTint,
      iconColor: kKpiGreenText,
      onTap: tapFor(_completed, completed),
      footer: KpiFooterText(
        records.isEmpty
            ? 'Nothing to open yet'
            : '$completed of ${records.length} finished',
      ),
    ),
    KpiCard(
      header: 'NEEDS ATTENTION',
      value: formatNumber(flags.length, decimals: 0),
      icon: Icons.warning_amber_rounded,
      iconTint: urgent > 0 ? kKpiRedTint : kKpiGreyTint,
      iconColor: urgent > 0 ? kKpiRedText : kKpiGreyText,
      footer: KpiFooterText(
        flags.isEmpty
            ? 'Nothing overdue or unassigned'
            : '$urgent urgent, ${flags.length - urgent} to watch',
        icon: urgent > 0 ? Icons.error_outline : null,
        color: urgent > 0 ? kKpiRedText : kKpiMuted,
      ),
    ),
    KpiCard(
      header: 'AVG DAYS TO CLOSE OUT',
      value: averageAging == null
          ? '-'
          : '${averageAging.toStringAsFixed(1)} days',
      icon: Icons.timelapse_outlined,
      footer: const KpiFooterText('From closing date to Appendix P'),
    ),
  ];
}
