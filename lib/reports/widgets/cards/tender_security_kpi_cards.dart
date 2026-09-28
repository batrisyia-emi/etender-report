// lib/reports/widgets/cards/tender_security_kpi_cards.dart
//
// The summary figures from the report spec, plus Expired — which the spec
// lists as a filter and an indicator but not a summary, and which is the
// one state nobody should have to go looking for.
import 'package:etender_reports/reports/models/filters/tender_security_filters.dart';
import 'package:etender_reports/reports/models/metrics/tender_security_metrics.dart';
import 'package:etender_reports/reports/models/records/tender_security_record.dart';
import 'package:etender_reports/reports/widgets/shared/kpi_card.dart';
import 'package:etender_reports/shared/utils/formatters.dart';
import 'package:flutter/material.dart';

List<Widget> buildTenderSecurityKpiCards({
  required List<TenderSecurityRecord> records,
  ValueChanged<TenderSecurityView>? onViewTap,
}) {
  final total = tenderSecurityTotal(records);
  final held = tenderSecurityHeld(records);
  final expiringSoon = tenderSecurityExpiringSoonCount(records);
  final expired = tenderSecurityExpiredCount(records);
  final pendingRefund = tenderSecurityPendingRefundCount(records);
  final refunded = tenderSecurityRefundedCount(records);
  final originalMissing = tenderSecurityOriginalNotReceivedCount(records);

  /// Switches the table to [view], or back to All when it is already the
  /// selection. Null when nothing is in that state, so the card is inert
  /// rather than filtering the table down to nothing.
  VoidCallback? tapFor(TenderSecurityView view, int count) =>
      count == 0 || onViewTap == null ? null : () => onViewTap(view);

  return [
    KpiCard(
      header: 'SECURITIES',
      value: formatNumber(records.length, decimals: 0),
      icon: Icons.shield_outlined,
      footer: KpiBadgeFooter(
        badges: [
          if (originalMissing > 0)
            KpiBadge.orange('$originalMissing original missing'),
          if (refunded > 0) KpiBadge.green('$refunded refunded'),
        ],
      ),
    ),
    KpiCard(
      header: 'CURRENTLY HELD',
      value: formatValue(held),
      icon: Icons.account_balance_outlined,
      iconTint: kKpiBlueTint,
      iconColor: kKpiBlueText,
      footer: KpiFooterText(
        // The distinction the two figures are for: what is still on hand
        // against what has passed through.
        refunded == 0
            ? 'Nothing returned yet'
            : '${formatValue(total)} lodged in total',
      ),
    ),
    KpiCard(
      header: 'EXPIRING SOON',
      value: formatNumber(expiringSoon, decimals: 0),
      icon: Icons.schedule,
      iconTint: expiringSoon > 0 ? kKpiOrangeTint : kKpiGreyTint,
      iconColor: expiringSoon > 0 ? kKpiOrangeText : kKpiGreyText,
      onTap: tapFor(TenderSecurityView.expiringSoon, expiringSoon),
      footer: const KpiFooterText(
        'Lapsing within $kTenderSecurityExpiringSoonDays days',
      ),
    ),
    KpiCard(
      header: 'EXPIRED',
      value: formatNumber(expired, decimals: 0),
      icon: Icons.error_outline,
      iconTint: expired > 0 ? kKpiRedTint : kKpiGreyTint,
      iconColor: expired > 0 ? kKpiRedText : kKpiGreyText,
      onTap: tapFor(TenderSecurityView.expired, expired),
      footer: KpiFooterText(
        expired > 0
            ? 'Lapsed while still held'
            : 'Nothing has lapsed while held',
        icon: expired > 0 ? Icons.error_outline : null,
        color: expired > 0 ? kKpiRedText : kKpiMuted,
      ),
    ),
    KpiCard(
      header: 'PENDING REFUND',
      value: formatNumber(pendingRefund, decimals: 0),
      icon: Icons.assignment_return_outlined,
      iconTint: pendingRefund > 0 ? kKpiOrangeTint : kKpiGreyTint,
      iconColor: pendingRefund > 0 ? kKpiOrangeText : kKpiGreyText,
      onTap: tapFor(TenderSecurityView.pendingRefund, pendingRefund),
      footer: const KpiFooterText('Unsuccessful, not yet returned'),
    ),
  ];
}
