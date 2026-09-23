// lib/reports/widgets/dashboard/se/se_closing_soon_card.dart
//
// The tenders whose closing date is still ahead, soonest first.
import 'package:flutter/material.dart';

import 'package:etender_reports/reports/models/tender_status.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_cards.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_theme.dart';
import 'package:etender_reports/shared/utils/formatters.dart';

class SeClosingSoonCard extends StatelessWidget {
  const SeClosingSoonCard({super.key, required this.records, this.limit = 6});

  final List<Map<String, dynamic>> records;

  /// The overview shows a handful; the Tenders tab has room for more.
  final int limit;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final upcoming =
        records
            .where(
              (r) => TenderStatus.openForBidding.contains(
                TenderStatus.fromWire(r['status']),
              ),
            )
            .map(
              (r) => (
                record: r,
                closing: DateTime.tryParse(r['closingDate']?.toString() ?? ''),
              ),
            )
            .where((e) => e.closing != null && !e.closing!.isBefore(now))
            .toList()
          ..sort((a, b) => a.closing!.compareTo(b.closing!));

    return DashCard(
      icon: Icons.schedule,
      title: 'Tenders Closing Soon',
      subtitle: 'Open for bidding, soonest first',
      padded: false,
      child: upcoming.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              child: Text(
                'Nothing is currently open for bidding.',
                style: TextStyle(fontSize: 12, color: DashTheme.muted),
              ),
            )
          : Column(
              children: [
                const SeClosingHeaderRow(),
                for (final entry in upcoming.take(limit))
                  SeClosingRow(
                    record: entry.record,
                    daysLeft: entry.closing!.difference(now).inDays,
                  ),
              ],
            ),
    );
  }
}

class SeClosingHeaderRow extends StatelessWidget {
  const SeClosingHeaderRow({super.key});

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
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text('T/Q No.', style: style)),
          Expanded(flex: 5, child: Text('Title', style: style)),
          Expanded(flex: 2, child: Text('Closing', style: style)),
          Expanded(flex: 2, child: Text('Days Left', style: style)),
        ],
      ),
    );
  }
}

class SeClosingRow extends StatelessWidget {
  const SeClosingRow({super.key, required this.record, required this.daysLeft});

  final Map<String, dynamic> record;
  final int daysLeft;

  @override
  Widget build(BuildContext context) {
    // The template colours its Days Left pill by urgency.
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
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: DashTheme.tintOf(urgency),
                  borderRadius: BorderRadius.circular(DashTheme.radius),
                ),
                child: Text(
                  daysLeft == 0 ? 'Today' : '$daysLeft days',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: urgency,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
