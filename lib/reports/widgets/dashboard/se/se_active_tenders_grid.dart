// lib/reports/widgets/dashboard/se/se_active_tenders_grid.dart
//
// Every tender still open for bidding as its own card, two across.
import 'package:flutter/material.dart';

import 'package:etender_reports/reports/models/tender_status.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_cards.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_primitives.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_theme.dart';
import 'package:etender_reports/shared/utils/formatters.dart';

class SeActiveTendersGrid extends StatelessWidget {
  const SeActiveTendersGrid({super.key, required this.records});

  final List<Map<String, dynamic>> records;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final active =
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
            .toList()
          // Dated ones first, soonest to close at the top.
          ..sort((a, b) {
            if (a.closing == null) return b.closing == null ? 0 : 1;
            if (b.closing == null) return -1;
            return a.closing!.compareTo(b.closing!);
          });

    if (active.isEmpty) {
      return DashCard(
        icon: Icons.campaign_outlined,
        title: 'Active Tenders',
        child: const Text(
          'Nothing is currently open for bidding.',
          style: TextStyle(fontSize: 12, color: DashTheme.muted),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              const Icon(
                Icons.campaign_outlined,
                size: 17,
                color: DashTheme.primary,
              ),
              const SizedBox(width: 9),
              const Text(
                'Active Tenders',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: DashTheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${active.length} open for bidding',
                style: const TextStyle(fontSize: 11, color: DashTheme.muted),
              ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 760 ? 2 : 1;
            final rows = <Widget>[];
            for (var start = 0; start < active.length; start += columns) {
              final end = (start + columns).clamp(0, active.length);
              rows.add(
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = start; i < end; i++) ...[
                      if (i > start) const SizedBox(width: 14),
                      Expanded(
                        child: SeTenderCard(
                          record: active[i].record,
                          closing: active[i].closing,
                          now: now,
                        ),
                      ),
                    ],
                    for (var i = end; i < start + columns; i++) ...[
                      const SizedBox(width: 14),
                      const Expanded(child: SizedBox.shrink()),
                    ],
                  ],
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) const SizedBox(height: 14),
                  IntrinsicHeight(child: rows[i]),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class SeTenderCard extends StatelessWidget {
  const SeTenderCard({
    super.key,
    required this.record,
    required this.closing,
    required this.now,
  });

  final Map<String, dynamic> record;
  final DateTime? closing;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final daysLeft = closing?.difference(now).inDays;
    // .tcard.urgent / .watch / .normal
    final urgency = daysLeft == null
        ? DashTheme.muted
        : daysLeft <= 3
        ? DashTheme.danger
        : daysLeft <= 7
        ? DashTheme.warning
        : DashTheme.accent;
    final status = record['status']?.toString() ?? '';

    // The template's `.tcard.urgent` is a 3px left border, but Flutter will
    // not round a border whose sides differ, so the stripe is a child of a
    // uniformly bordered card instead. The grid's IntrinsicHeight gives the
    // row a tight height, so stretch runs the stripe the full way down.
    return Container(
      decoration: BoxDecoration(
        color: DashTheme.card,
        border: Border.all(color: DashTheme.border),
        borderRadius: BorderRadius.circular(DashTheme.radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 3, color: urgency),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // .tc-head
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: DashTheme.border)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              record['tenderNo']?.toString() ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: DashTheme.accent,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              record['title']?.toString() ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                                color: DashTheme.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      DashPill(label: status, color: urgency),
                    ],
                  ),
                ),
                // .tc-body / .tc-meta
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SeMetaRow(
                        left: (
                          'Mode',
                          record['modeOfProcurement']?.toString() ?? '',
                        ),
                        right: (
                          'Division',
                          record['division']?.toString() ?? '',
                        ),
                      ),
                      const SizedBox(height: 6),
                      SeMetaRow(
                        left: ('Estimated Value', formatValue(record['value'])),
                        right: (
                          'Category',
                          record['tenderCategory']?.toString() ?? '',
                        ),
                      ),
                      const SizedBox(height: 6),
                      SeMetaRow(
                        left: (
                          'Envelope',
                          record['envelopeType']?.toString() ?? '',
                        ),
                        right: (
                          'Item Type',
                          record['itemType']?.toString() ?? '',
                        ),
                      ),
                    ],
                  ),
                ),
                // .tc-foot
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  decoration: BoxDecoration(
                    color: DashTheme.background,
                    border: const Border(
                      top: BorderSide(color: DashTheme.border),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        daysLeft == null
                            ? 'No closing date'
                            : daysLeft < 0
                            ? 'Closed'
                            : daysLeft == 0
                            ? 'Closes today'
                            : '$daysLeft ${daysLeft == 1 ? 'day' : 'days'} left',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: urgency,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Closing: ${formatDateOnly(record['closingDate'])}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: DashTheme.muted,
                        ),
                      ),
                    ],
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

class SeMetaRow extends StatelessWidget {
  const SeMetaRow({super.key, required this.left, required this.right});

  final (String, String) left;
  final (String, String) right;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SeMetaItem(label: left.$1, value: left.$2),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SeMetaItem(label: right.$1, value: right.$2),
        ),
      ],
    );
  }
}

class SeMetaItem extends StatelessWidget {
  const SeMetaItem({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
            color: DashTheme.muted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.isEmpty ? '—' : value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: DashTheme.text,
          ),
        ),
      ],
    );
  }
}
