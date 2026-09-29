// lib/reports/widgets/cards/vtm_monitoring_kpi_cards.dart
//
// The summary figures for the VTM Tender/Quotation Monitoring report: what
// is in the pipeline, what is stuck, and how long the ones that made it
// took.
import 'package:etender_reports/reports/models/metrics/tender_security_metrics.dart';
import 'package:etender_reports/reports/models/metrics/vtm_monitoring_metrics.dart';
import 'package:etender_reports/reports/models/records/tender_security_record.dart';
import 'package:etender_reports/reports/models/records/vtm_monitoring_record.dart';
import 'package:etender_reports/reports/models/status/vtm_monitoring_status.dart';
import 'package:etender_reports/reports/widgets/shared/kpi_card.dart';
import 'package:etender_reports/shared/utils/formatters.dart';
import 'package:flutter/material.dart';

/// Moving forward: neither sent back nor floated.
final Set<VtmStatus> _inProgressStatuses = {
  for (final status in VtmStatus.values)
    if (status.isInProgress) status,
};
final Set<String> _inProgress = VtmStatus.codesOf(_inProgressStatuses);

/// Both gates' rejections. Which gate turned it back matters less at a
/// glance than the fact that somebody has to redo it.
final Set<String> _rejected = VtmStatus.codesOf({
  VtmStatus.rejectedByExec,
  VtmStatus.rejectedByManager,
});

final Set<String> _approved = VtmStatus.codesOf({VtmStatus.approvedByManager});
final Set<String> _published = VtmStatus.codesOf({VtmStatus.published});

List<Widget> buildVtmMonitoringKpiCards({
  required List<VtmMonitoringRecord> records,

  /// Every tender security on file, from the tender security dataset.
  ///
  /// Not this report's records, so [records]' filters do not apply to it.
  /// Empty when that endpoint is unavailable.
  List<TenderSecurityRecord> securities = const [],
  ValueChanged<Set<String>>? onStatusTap,
}) {
  final inProgress = vtmInProgressCount(records);
  final rejected = vtmRejectedCount(records);
  final approved = vtmCountWithStatus(records, VtmStatus.approvedByManager);
  final published = vtmPublishedCount(records);
  final slow = vtmSlowCount(records);
  final averageAging = vtmAveragePublishedAging(records);
  final byType = vtmDocumentTypeCounts(records);

  // Lodged less refunded: what VTM is still holding on behalf of tenderers.
  final outstandingSecurity = tenderSecurityHeld(securities);
  final securitiesHeld = securities
      .where((record) => !tenderSecurityIsRefunded(record))
      .length;

  /// Filters to [statuses], or clears that filter when it is already the
  /// selection. Null when nothing holds the status, so the card is inert
  /// rather than filtering the table down to nothing.
  VoidCallback? tapFor(Set<String> statuses, int count) =>
      count == 0 || onStatusTap == null ? null : () => onStatusTap(statuses);

  return [
    KpiCard(
      header: 'DOCUMENTS',
      value: formatNumber(records.length, decimals: 0),
      icon: Icons.description_outlined,
      footer: KpiBadgeFooter(
        badges: [
          if ((byType['Tender'] ?? 0) > 0)
            KpiBadge.blue('${byType['Tender']} tender'),
          if ((byType['Quotation'] ?? 0) > 0)
            KpiBadge.grey('${byType['Quotation']} quotation'),
        ],
      ),
    ),
    KpiCard(
      header: 'OUTSTANDING TENDER SECURITY',
      // A dash rather than RM 0 when there is nothing to read: zero held
      // and no data are different statements, and only one of them is
      // about the securities.
      value: securities.isEmpty ? '-' : formatValue(outstandingSecurity),
      icon: Icons.account_balance_wallet_outlined,
      iconTint: kKpiBlueTint,
      iconColor: kKpiBlueText,
      // Says "all tenders" because this comes from the tender security
      // dataset, so the filters above it do not narrow it.
      footer: KpiFooterText(
        securities.isEmpty
            ? 'No tender security data'
            : '$securitiesHeld held, across all tenders',
      ),
    ),
    KpiCard(
      header: 'IN PROGRESS',
      value: formatNumber(inProgress, decimals: 0),
      icon: Icons.autorenew,
      iconTint: inProgress > 0 ? kKpiOrangeTint : kKpiGreyTint,
      iconColor: inProgress > 0 ? kKpiOrangeText : kKpiGreyText,
      onTap: tapFor(_inProgress, inProgress),
      footer: const KpiFooterText('Moving through preparation'),
    ),
    KpiCard(
      header: 'REJECTED',
      value: formatNumber(rejected, decimals: 0),
      icon: Icons.assignment_return_outlined,
      iconTint: rejected > 0 ? kKpiRedTint : kKpiGreyTint,
      iconColor: rejected > 0 ? kKpiRedText : kKpiGreyText,
      onTap: tapFor(_rejected, rejected),
      footer: KpiFooterText(
        rejected > 0
            ? 'Back with the preparer to correct'
            : 'Nothing sent back',
        icon: rejected > 0 ? Icons.error_outline : null,
        color: rejected > 0 ? kKpiRedText : kKpiMuted,
      ),
    ),
    KpiCard(
      header: 'AWAITING FLOAT',
      value: formatNumber(approved, decimals: 0),
      icon: Icons.outbox_outlined,
      iconTint: approved > 0 ? kKpiOrangeTint : kKpiGreyTint,
      iconColor: approved > 0 ? kKpiOrangeText : kKpiGreyText,
      onTap: tapFor(_approved, approved),
      footer: const KpiFooterText('Approved, one step from suppliers'),
    ),
    KpiCard(
      header: 'PUBLISHED',
      value: formatNumber(published, decimals: 0),
      icon: Icons.campaign_outlined,
      iconTint: kKpiGreenTint,
      iconColor: kKpiGreenText,
      onTap: tapFor(_published, published),
      footer: KpiFooterText(
        records.isEmpty
            ? 'Nothing floated yet'
            : '$published of ${records.length} floated',
      ),
    ),
    KpiCard(
      header: 'SITTING TOO LONG',
      value: formatNumber(slow, decimals: 0),
      icon: Icons.hourglass_bottom,
      iconTint: slow > 0 ? kKpiRedTint : kKpiGreyTint,
      iconColor: slow > 0 ? kKpiRedText : kKpiGreyText,
      footer: KpiFooterText(
        slow > 0
            ? 'Over $kVtmSlowDays days since endorsement'
            : 'Nothing over $kVtmSlowDays days',
        color: slow > 0 ? kKpiRedText : kKpiMuted,
      ),
    ),
    KpiCard(
      header: 'AVG DAYS TO FLOAT',
      value: averageAging == null
          ? '-'
          : '${averageAging.toStringAsFixed(1)} days',
      icon: Icons.timelapse_outlined,
      // Published documents only: averaging in the ones still waiting would
      // report a lead time nobody has achieved.
      footer: const KpiFooterText('Endorsement to floating, published only'),
    ),
  ];
}
