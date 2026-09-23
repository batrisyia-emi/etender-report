// lib/reports/views/cards/tender_kpi_cards.dart
import 'package:etender_reports/shared/utils/formatters.dart';
import 'package:flutter/material.dart';

import 'package:etender_reports/reports/models/tender_metrics.dart';
import 'package:etender_reports/reports/models/tender_status.dart';
import 'package:etender_reports/reports/widgets/shared/kpi_card.dart';

/// What the matching tenders/quotations are worth, then the lifecycle in
/// its three stages. Every record lands in exactly one stage card, so those
/// counts add up to the record total.
List<Widget> buildTenderKpiCards({
  required List<Map<String, dynamic>> records,
  ValueChanged<Set<String>>? onStatusTap,
}) {
  final statusCounts = tenderStatusCounts(records);
  final totalValue = tenderTotalValue(records);
  final averageValue = tenderAverageValue(records);

  /// A count of the records holding any of [statuses], tapping through to
  /// exactly that set as a filter. Greyed out when nothing holds them.
  ///
  /// Takes the enum and converts once: the records are keyed by wire text,
  /// but nothing above this line has to know that.
  KpiCard statusCard({
    required String header,
    required Set<TenderStatus> statuses,
    required IconData icon,
    required Color tint,
    required Color color,
    required String note,
  }) {
    final wires = TenderStatus.wiresOf(statuses);
    final count = wires.fold<int>(
      0,
      (total, wire) => total + (statusCounts[wire] ?? 0),
    );
    return KpiCard(
      header: header,
      value:
          '${formatNumber(count, decimals: 0)} '
          '${count == 1 ? 'Tender' : 'Tenders'}',
      icon: icon,
      iconTint: count > 0 ? tint : kKpiGreyTint,
      iconColor: count > 0 ? color : kKpiGreyText,
      onTap: count == 0 || onStatusTap == null
          ? null
          : () => onStatusTap(wires),
      footer: KpiFooterText(
        records.isEmpty ? note : '$note · $count of ${records.length}',
        color: count > 0 ? color : kKpiMuted,
      ),
    );
  }

  return [
    KpiCard(
      header: 'TOTAL TENDER/QUOTATION ESTIMATED VALUE',
      value: formatValue(totalValue),
      icon: Icons.account_balance_wallet_outlined,
      iconTint: kKpiBlueTint,
      iconColor: kKpiBlueText,
      footer: KpiFooterText(
        averageValue == null
            ? 'Across every record shown'
            : 'Avg ${formatValue(averageValue, decimals: 0)} each',
      ),
    ),
    statusCard(
      header: 'PUBLISHED',
      statuses: const {TenderStatus.published},
      icon: Icons.campaign_outlined,
      tint: kKpiGreenTint,
      color: kKpiGreenText,
      note: 'Open for bidding',
    ),
    statusCard(
      header: 'EXTENDED',
      statuses: const {TenderStatus.extended},
      icon: Icons.update_outlined,
      tint: kKpiOrangeTint,
      color: kKpiOrangeText,
      note: 'Deadline pushed out',
    ),
    statusCard(
      header: 'CLOSED',
      statuses: const {TenderStatus.closed},
      icon: Icons.lock_clock_outlined,
      tint: kKpiGreyTint,
      color: kKpiGreyText,
      note: 'Bidding ended',
    ),
  ];
}
