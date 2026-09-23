// lib/reports/widgets/dashboard/se/se_kpi_row.dart
//
// The four cross-report headline figures across the top of the page.
import 'package:flutter/material.dart';

import 'package:etender_reports/reports/models/erfc_metrics.dart';
import 'package:etender_reports/reports/models/tender_metrics.dart';
import 'package:etender_reports/reports/models/tender_status.dart';
import 'package:etender_reports/reports/models/vendor_metrics.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_cards.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_theme.dart';
import 'package:etender_reports/shared/utils/formatters.dart';

class SeKpiRow extends StatelessWidget {
  const SeKpiRow({
    super.key,
    required this.tenders,
    required this.rfcs,
    required this.vendors,
  });

  final List<Map<String, dynamic>> tenders;
  final List<Map<String, dynamic>> rfcs;
  final List<Map<String, dynamic>> vendors;

  int _countOf(List<Map<String, dynamic>> records, Set<String> wires) =>
      records.where((r) => wires.contains(r['status']?.toString())).length;

  @override
  Widget build(BuildContext context) {
    final openTenders = _countOf(
      tenders,
      TenderStatus.wiresOf(TenderStatus.openForBidding),
    );
    final extended = _countOf(tenders, {TenderStatus.extended.wireValue});
    final inFlight = _countOf(rfcs, kErfcInFlightStatuses);
    final overdue = rfcs.where(erfcIsOverdue).length;
    final participated = vendorParticipatedCount(vendors);

    final cards = [
      DashKpiCard(
        icon: Icons.account_balance_wallet_outlined,
        accent: DashTheme.accent,
        value: formatValue(tenderTotalValue(tenders)),
        label: 'Total Tender/Quotation Value',
        note: '${tenders.length} records',
      ),
      DashKpiCard(
        icon: Icons.campaign_outlined,
        accent: DashTheme.success,
        value: formatNumber(openTenders, decimals: 0),
        label: 'Open for Bidding',
        note: '$extended extended',
        noteColor: extended > 0 ? DashTheme.warning : null,
      ),
      DashKpiCard(
        icon: Icons.autorenew,
        accent: DashTheme.info,
        value: formatNumber(inFlight, decimals: 0),
        label: 'eRFCs In Progress',
        note: overdue > 0 ? '$overdue overdue' : 'None overdue',
        noteColor: overdue > 0 ? DashTheme.danger : null,
      ),
      DashKpiCard(
        icon: Icons.how_to_reg_outlined,
        accent: DashTheme.purple,
        value: formatNumber(participated, decimals: 0),
        label: 'Vendors Participated',
        note: '${vendors.length} vendor records',
      ),
    ];

    return DashCardGrid(cards: cards);
  }
}
