// lib/reports/views/cards/supplier_kpi_cards.dart
import 'package:etender_reports/shared/utils/formatters.dart';
import 'package:flutter/material.dart';

import 'package:etender_reports/reports/models/supplier_metrics.dart';
import 'package:etender_reports/reports/models/supplier_status.dart';
import 'package:etender_reports/reports/widgets/shared/kpi_card.dart';

final Set<String> _requested = SupplierStatus.wiresOf({
  SupplierStatus.participationRequested,
});
final Set<String> _draftOrSubmitted = SupplierStatus.wiresOf({
  SupplierStatus.draft,
  SupplierStatus.submitted,
});

/// What the supplier is looking at, then how far each request got: the
/// review decision, the fee, and whether a bid actually landed.
List<Widget> buildSupplierKpiCards({
  required List<Map<String, dynamic>> records,
  ValueChanged<Set<String>>? onStatusTap,
  VoidCallback? onPendingPaymentTap,
}) {
  final open = supplierCountWithStatus(records, kSupplierOpenStatuses);
  final rejected = supplierCountWithStatus(records, kSupplierRejectedStatuses);
  final cleared = supplierCountWithStatus(records, kSupplierClearedStatuses);
  final pendingPayment = supplierCountWithStatus(
    records,
    kSupplierPendingPaymentStatuses,
  );
  final participated = supplierCountWithStatus(
    records,
    kSupplierParticipatedStatuses,
  );
  final missed = supplierCountWithStatus(
    records,
    kSupplierNoParticipateStatuses,
  );
  final requested = supplierCountWithStatus(records, _requested);
  final bidding = supplierCountWithStatus(records, _draftOrSubmitted);

  final rate = supplierParticipationRate(records);
  final averageDecision = supplierAverageDecisionDays(records);
  final outstanding = supplierFeesOutstanding(records);
  final closingSoon = records.where(supplierIsClosingSoon).length;

  /// Filters to [statuses], or clears that filter when it is already the
  /// selection. Null when nothing holds the status, so the card is inert.
  VoidCallback? tapFor(Set<String> statuses, int count) =>
      count == 0 || onStatusTap == null ? null : () => onStatusTap(statuses);

  /// A count against the number of records the filters matched, so the
  /// footer says how many rather than what share.
  String outOf(int part) =>
      records.isEmpty ? '-' : '$part of ${records.length}';

  return [
    KpiCard(
      header: 'TENDERS VISIBLE',
      value: formatNumber(records.length, decimals: 0),
      icon: Icons.storefront_outlined,
      footer: KpiBadgeFooter(
        badges: [
          if (requested > 0) KpiBadge.blue('$requested Requested'),
          if (bidding > 0) KpiBadge.grey('$bidding Bidding'),
          if (participated > 0) KpiBadge.green('$participated Participated'),
        ],
      ),
    ),
    KpiCard(
      header: 'OPEN',
      value: formatNumber(open, decimals: 0),
      icon: Icons.visibility_outlined,
      iconTint: kKpiBlueTint,
      iconColor: kKpiBlueText,
      onTap: tapFor(kSupplierOpenStatuses, open),
      footer: KpiFooterText(
        closingSoon > 0
            ? '$closingSoon closing within $kSupplierClosingSoonDays days'
            : 'Nothing closing this week',
        icon: closingSoon > 0 ? Icons.schedule : null,
        color: closingSoon > 0 ? kKpiOrangeText : kKpiMuted,
      ),
    ),
    KpiCard(
      header: 'APPROVED TO BID',
      value: formatNumber(cleared, decimals: 0),
      icon: Icons.verified_outlined,
      iconTint: kKpiGreenTint,
      iconColor: kKpiGreenText,
      onTap: tapFor(kSupplierClearedStatuses, cleared),
      footer: KpiFooterText('${outOf(cleared)} tenders approved'),
    ),
    KpiCard(
      header: 'PENDING PAYMENT',
      value: formatNumber(pendingPayment, decimals: 0),
      icon: Icons.payments_outlined,
      iconTint: pendingPayment > 0 ? kKpiOrangeTint : kKpiGreyTint,
      iconColor: pendingPayment > 0 ? kKpiOrangeText : kKpiGreyText,
      onTap: pendingPayment == 0 ? null : onPendingPaymentTap,
      footer: KpiFooterText(
        pendingPayment > 0
            ? '${formatValue(outstanding)} in fees owed'
            : 'No fees outstanding',
        icon: pendingPayment > 0 ? Icons.error_outline : null,
        color: pendingPayment > 0 ? kKpiOrangeText : kKpiMuted,
      ),
    ),
    KpiCard(
      header: 'REJECTED',
      value: formatNumber(rejected, decimals: 0),
      icon: Icons.block_outlined,
      iconTint: rejected > 0 ? kKpiRedTint : kKpiGreyTint,
      iconColor: rejected > 0 ? kKpiRedText : kKpiGreyText,
      onTap: tapFor(kSupplierRejectedStatuses, rejected),
      footer: KpiFooterText('${outOf(rejected)} requests rejected'),
    ),
    KpiCard(
      header: 'PARTICIPATED',
      value: formatNumber(participated, decimals: 0),
      icon: Icons.how_to_reg_outlined,
      iconTint: kKpiGreenTint,
      iconColor: kKpiGreenText,
      onTap: tapFor(kSupplierParticipatedStatuses, participated),
      footer: KpiFooterText(
        missed > 0 ? '$missed closed without bidding' : 'Bid on every one',
      ),
    ),
    KpiCard(
      header: 'PARTICIPATION RATE',
      value: rate == null ? '-' : '${rate.toStringAsFixed(1)}%',
      icon: Icons.donut_small_outlined,
      footer: KpiFooterText(
        rate == null
            ? 'Nothing has closed yet'
            : 'Based on ${participated + missed} closed tenders',
      ),
    ),
    KpiCard(
      header: 'TOTAL BID VALUE',
      value: formatValue(supplierTotalBidValue(records)),
      icon: Icons.account_balance_wallet_outlined,
      iconTint: kKpiBlueTint,
      iconColor: kKpiBlueText,
      footer: KpiFooterText(
        averageDecision == null
            ? 'Added up across all bids'
            : 'Avg ${averageDecision.toStringAsFixed(1)} days to a decision',
      ),
    ),
  ];
}
