// lib/reports/widgets/dashboard/supplier/supplier_bids_cards.dart
//
// The bid pipeline and the table of every bid behind it.
import 'package:flutter/material.dart';

import 'package:etender_reports/reports/models/supplier_dashboard_metrics.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_cards.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_primitives.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_theme.dart';
import 'package:etender_reports/shared/utils/formatters.dart';

class SupplierBidPipelineCard extends StatelessWidget {
  const SupplierBidPipelineCard({
    super.key,
    required this.bids,
    this.onViewAll,
  });

  final List<Map<String, dynamic>> bids;

  /// Omitted on the Bids tab, which already lists every bid below it.
  final VoidCallback? onViewAll;

  static const Map<SupplierBidOutcome, Color> _outcomeColors = {
    SupplierBidOutcome.underEvaluation: DashTheme.info,
    SupplierBidOutcome.shortlisted: DashTheme.purple,
    SupplierBidOutcome.awarded: DashTheme.success,
    SupplierBidOutcome.unsuccessful: DashTheme.danger,
  };

  static const Map<SupplierBidOutcome, String> _outcomeLabels = {
    SupplierBidOutcome.underEvaluation: 'Under evaluation',
    SupplierBidOutcome.shortlisted: 'Shortlisted',
    SupplierBidOutcome.awarded: 'Awarded',
    SupplierBidOutcome.unsuccessful: 'Unsuccessful',
  };

  @override
  Widget build(BuildContext context) {
    final total = bids.length;
    final winRate = supplierWinRate(bids);
    final closed = supplierClosedBidCount(bids);
    final won = supplierBidsWithOutcome(bids, SupplierBidOutcome.awarded);

    return DashCard(
      icon: Icons.insights_outlined,
      title: 'Bid Pipeline',
      subtitle: '$total submitted',
      trailing: onViewAll == null
          ? null
          : DashButton(label: 'View all', onTap: onViewAll!),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final outcome in SupplierBidOutcome.values) ...[
            if (outcome != SupplierBidOutcome.values.first)
              const SizedBox(height: 12),
            DashMeasureBar(
              label: _outcomeLabels[outcome]!,
              valueLabel: '${supplierBidsWithOutcome(bids, outcome)} of $total',
              fraction: total == 0
                  ? 0
                  : supplierBidsWithOutcome(bids, outcome) / total,
              color: _outcomeColors[outcome]!,
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1, color: DashTheme.border),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Win rate',
                  style: TextStyle(fontSize: 12, color: DashTheme.text),
                ),
              ),
              Text(
                winRate == null
                    ? 'No decisions yet'
                    : '${(winRate * 100).toStringAsFixed(1)}% '
                          '($won of $closed closed)',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: DashTheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SupplierBidsTableCard extends StatelessWidget {
  const SupplierBidsTableCard({super.key, required this.bids});

  final List<Map<String, dynamic>> bids;

  static Color _colorOf(SupplierBidOutcome? outcome) => switch (outcome) {
    SupplierBidOutcome.awarded => DashTheme.success,
    SupplierBidOutcome.shortlisted => DashTheme.purple,
    SupplierBidOutcome.unsuccessful => DashTheme.danger,
    _ => DashTheme.info,
  };

  @override
  Widget build(BuildContext context) {
    final sorted = [...bids]
      ..sort(
        (a, b) => (b['submittedDate']?.toString() ?? '').compareTo(
          a['submittedDate']?.toString() ?? '',
        ),
      );

    const header = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: DashTheme.muted,
    );

    return DashCard(
      icon: Icons.gavel_outlined,
      title: 'My Bids & Quotations',
      subtitle: '${bids.length} submitted',
      padded: false,
      child: sorted.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              child: Text(
                'You have not submitted a bid yet.',
                style: TextStyle(fontSize: 12, color: DashTheme.muted),
              ),
            )
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 9,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: DashTheme.border)),
                  ),
                  child: const Row(
                    children: [
                      Expanded(flex: 3, child: Text('T/Q No.', style: header)),
                      Expanded(flex: 5, child: Text('Title', style: header)),
                      Expanded(
                        flex: 3,
                        child: Text('Bid Amount', style: header),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text('Submitted', style: header),
                      ),
                      Expanded(flex: 3, child: Text('Outcome', style: header)),
                    ],
                  ),
                ),
                for (final bid in sorted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: DashTheme.border),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            bid['tenderNo']?.toString() ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: DashTheme.accent,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 5,
                          child: Text(
                            bid['title']?.toString() ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: DashTheme.text,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            formatValue(bid['bidAmount']),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: DashTheme.text,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            formatDateOnly(bid['submittedDate']),
                            style: const TextStyle(
                              fontSize: 12,
                              color: DashTheme.text,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: DashPill(
                              label: bid['outcome']?.toString() ?? '',
                              color: _colorOf(
                                SupplierBidOutcome.fromWire(bid['outcome']),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
