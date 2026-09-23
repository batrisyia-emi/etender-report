// lib/reports/widgets/dashboard/supplier/supplier_tenders_card.dart
//
// What is still open in the categories this supplier is registered for.
import 'package:flutter/material.dart';

import 'package:etender_reports/reports/models/supplier_dashboard_metrics.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_cards.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_primitives.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_theme.dart';
import 'package:etender_reports/shared/utils/formatters.dart';

class SupplierMatchingTendersCard extends StatelessWidget {
  const SupplierMatchingTendersCard({
    super.key,
    required this.tenders,
    required this.categories,
    required this.now,
    this.limit = 6,
    this.onViewAll,
    this.onBidNow,
    this.onViewTender,
  });

  final List<Map<String, dynamic>> tenders;
  final Set<String> categories;
  final DateTime now;

  /// The overview lists a handful; the Tenders tab has room for them all.
  final int limit;

  /// Omitted on the Tenders tab, which is already showing everything.
  final VoidCallback? onViewAll;

  /// The per-row actions, both taking the tender number. Null renders the
  /// rows without a button. Which one a row offers is decided by how close
  /// it is to closing.
  final ValueChanged<String>? onBidNow;
  final ValueChanged<String>? onViewTender;

  @override
  Widget build(BuildContext context) {
    final matching = supplierOpenTenders(tenders, now, categories: categories);

    return DashCard(
      icon: Icons.schedule,
      title: 'Tenders Closing Soon',
      subtitle: 'Matching your registered categories',
      padded: false,
      trailing: onViewAll == null
          ? null
          : DashButton(label: 'View all', onTap: onViewAll!),
      child: matching.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              child: Text(
                'Nothing open in your categories right now.',
                style: TextStyle(fontSize: 12, color: DashTheme.muted),
              ),
            )
          : Column(
              children: [
                SupplierMatchingHeaderRow(withAction: onBidNow != null),
                for (final record in matching.take(limit))
                  SupplierMatchingRow(
                    record: record,
                    daysLeft: DateTime.parse(record['closingDate'].toString())
                        .difference(now)
                        .inDays,
                    onBidNow: onBidNow,
                    onViewTender: onViewTender,
                  ),
              ],
            ),
    );
  }
}

class SupplierMatchingHeaderRow extends StatelessWidget {
  const SupplierMatchingHeaderRow({super.key, this.withAction = false});

  final bool withAction;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: DashTheme.muted,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: DashTheme.border)),
      ),
      child: Row(
        children: [
          const Expanded(flex: 3, child: Text('T/Q No.', style: style)),
          const Expanded(flex: 5, child: Text('Title', style: style)),
          const Expanded(flex: 3, child: Text('Category', style: style)),
          const Expanded(flex: 2, child: Text('Closing', style: style)),
          const Expanded(flex: 2, child: Text('Days Left', style: style)),
          if (withAction) const Expanded(flex: 2, child: SizedBox.shrink()),
        ],
      ),
    );
  }
}

class SupplierMatchingRow extends StatelessWidget {
  const SupplierMatchingRow({
    super.key,
    required this.record,
    required this.daysLeft,
    this.onBidNow,
    this.onViewTender,
  });

  final Map<String, dynamic> record;
  final int daysLeft;
  final ValueChanged<String>? onBidNow;
  final ValueChanged<String>? onViewTender;

  @override
  Widget build(BuildContext context) {
    final urgency = daysLeft <= 3
        ? DashTheme.danger
        : daysLeft <= 7
        ? DashTheme.warning
        : DashTheme.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: DashTheme.border)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              record['tenderNo']?.toString() ?? '',
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
              record['title']?.toString() ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: DashTheme.text),
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: DashPill(
                label: record['tenderCategory']?.toString() ?? '',
                color: DashTheme.info,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              formatDateOnly(record['closingDate']),
              style: const TextStyle(fontSize: 12, color: DashTheme.text),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: DashPill(
                label: daysLeft == 0 ? 'Today' : '$daysLeft days',
                color: urgency,
              ),
            ),
          ),
          if (onBidNow != null)
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                // The template pushes the ones about to close, and leaves
                // the rest as a plain look. Both leave this module for the
                // bidding screen; only the intent differs.
                child: Builder(
                  builder: (context) {
                    final tenderNo = record['tenderNo']?.toString() ?? '';
                    final urgent = daysLeft <= 7;
                    return DashButton(
                      label: urgent ? 'Bid now' : 'View',
                      onTap: () => urgent
                          ? onBidNow!(tenderNo)
                          : onViewTender!(tenderNo),
                      filled: urgent,
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
