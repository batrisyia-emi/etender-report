// lib/reports/views/cards/erfc_kpi_cards.dart
import 'package:etender_reports/shared/utils/formatters.dart';
import 'package:flutter/material.dart';

import 'package:etender_reports/reports/models/erfc_metrics.dart';
import 'package:etender_reports/reports/models/erfc_status.dart';
import 'package:etender_reports/reports/widgets/shared/kpi_card.dart';

final Set<String> _cancelled = ErfcStatus.wiresOf({ErfcStatus.cancelled});
final Set<String> _verifying = ErfcStatus.wiresOf({
  ErfcStatus.submitted,
  ErfcStatus.firstVerified,
  ErfcStatus.secondVerified,
});

List<Widget> buildErfcKpiCards({
  required List<Map<String, dynamic>> records,
  ValueChanged<Set<String>>? onStatusTap,
  VoidCallback? onOverdueTap,
}) {
  final inFlight = records.where((r) => !erfcIsTerminal(r)).length;
  final endorsed = erfcCountWithStatus(records, kErfcEndorsedStatuses);
  final rejected = erfcCountWithStatus(records, kErfcRejectedStatuses);
  final cancelled = erfcCountWithStatus(records, _cancelled);
  final draft = erfcCountWithStatus(
    records,
    ErfcStatus.wiresOf({ErfcStatus.draft}),
  );
  final verifying = erfcCountWithStatus(records, _verifying);

  /// Filters to [statuses], or clears that filter when it is already the
  /// selection. Null when nothing holds the status, so the card is inert.
  VoidCallback? tapFor(Set<String> statuses, int count) =>
      count == 0 || onStatusTap == null ? null : () => onStatusTap(statuses);

  final overdue = records.where(erfcIsOverdue).length;
  final oldest = erfcOldestInFlightDays(records);
  final averageDays = erfcAverageProcessingDays(records);

  /// A count against the number of records the filters matched, so the
  /// footer says how many rather than what share.
  String outOf(int part) =>
      records.isEmpty ? '-' : '$part of ${records.length}';

  return [
    KpiCard(
      header: 'TOTAL RFCS',
      value: formatNumber(records.length, decimals: 0),
      icon: Icons.request_page_outlined,
      footer: KpiBadgeFooter(
        badges: [
          if (draft > 0) KpiBadge.grey('$draft Draft'),
          if (verifying > 0) KpiBadge.blue('$verifying Verifying'),
          if (endorsed > 0) KpiBadge.green('$endorsed Endorsed'),
        ],
      ),
    ),
    KpiCard(
      header: 'PIPELINE VALUE',
      value: formatValue(erfcPipelineValue(records)),
      icon: Icons.account_balance_wallet_outlined,
      iconTint: kKpiBlueTint,
      iconColor: kKpiBlueText,
      footer: const KpiFooterText('Total value requested'),
    ),
    KpiCard(
      header: 'IN PROGRESS',
      value: formatNumber(inFlight, decimals: 0),
      icon: Icons.autorenew,
      iconTint: kKpiOrangeTint,
      iconColor: kKpiOrangeText,
      onTap: tapFor(kErfcInFlightStatuses, inFlight),
      footer: KpiFooterText(
        oldest == null ? 'Nothing in progress' : 'Oldest waiting $oldest days',
      ),
    ),
    KpiCard(
      header: 'ENDORSED',
      value: formatNumber(endorsed, decimals: 0),
      icon: Icons.verified_outlined,
      iconTint: kKpiGreenTint,
      iconColor: kKpiGreenText,
      onTap: tapFor(kErfcEndorsedStatuses, endorsed),
      footer: KpiFooterText('${outOf(endorsed)} endorsed'),
    ),
    KpiCard(
      header: 'OVERDUE',
      value: formatNumber(overdue, decimals: 0),
      icon: Icons.warning_amber_rounded,
      iconTint: overdue > 0 ? kKpiRedTint : kKpiGreyTint,
      iconColor: overdue > 0 ? kKpiRedText : kKpiGreyText,
      onTap: overdue == 0 ? null : onOverdueTap,
      footer: KpiFooterText(
        overdue > 0
            ? 'Waiting more than $kErfcOverdueDays days'
            : 'None waiting over $kErfcOverdueDays days',
        icon: overdue > 0 ? Icons.error_outline : null,
        color: overdue > 0 ? kKpiRedText : kKpiMuted,
      ),
    ),
    KpiCard(
      header: 'AVG PROCESSING',
      value: averageDays == null
          ? '-'
          : '${averageDays.toStringAsFixed(1)} days',
      icon: Icons.timelapse_outlined,
      footer: const KpiFooterText('From submitted to endorsed'),
    ),
    KpiCard(
      header: 'REJECTED/DECLINED',
      value: formatNumber(rejected, decimals: 0),
      icon: Icons.block_outlined,
      iconTint: rejected > 0 ? kKpiRedTint : kKpiGreyTint,
      iconColor: rejected > 0 ? kKpiRedText : kKpiGreyText,
      onTap: tapFor(kErfcRejectedStatuses, rejected),
      footer: KpiFooterText('${outOf(rejected)} stopped here'),
    ),
    KpiCard(
      header: 'CANCELLED',
      value: formatNumber(cancelled, decimals: 0),
      icon: Icons.cancel_outlined,
      onTap: tapFor(_cancelled, cancelled),
      footer: const KpiFooterText('Withdrawn before finishing'),
    ),
  ];
}
