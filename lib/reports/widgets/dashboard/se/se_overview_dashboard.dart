// lib/reports/widgets/dashboard/se/se_overview_dashboard.dart
//
// The Overview tab (SE view): tender and RFC status at a glance, plus the
// two lists that need attention — tenders about to close and endorsed RFCs
// whose validity has run out.
import 'package:etender_reports/reports/models/records/tender_record.dart';
import 'package:etender_reports/reports/models/status/erfc_status.dart';
import 'package:etender_reports/reports/models/status/tender_status.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_period.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_theme.dart';
import 'package:etender_reports/shared/utils/formatters.dart';
import 'package:flutter/material.dart';

/// How long an endorsed RFC stays valid before it must flow to a tender.
const int kErfcValidityDays = 30;

/// Tab indexes the "Go to" links jump to.
const int kTendersTabIndex = 1;
const int kErfcTabIndex = 2;

class SeOverviewDashboard extends StatefulWidget {
  const SeOverviewDashboard({
    super.key,
    required this.tenders,
    required this.rfcs,
    required this.onNavigate,
  });

  final List<Map<String, dynamic>> tenders;
  final List<Map<String, dynamic>> rfcs;
  final ValueChanged<int> onNavigate;

  @override
  State<SeOverviewDashboard> createState() => _SeOverviewDashboardState();
}

class _SeOverviewDashboardState extends State<SeOverviewDashboard> {
  DashPeriod _period = DashPeriod.thisMonth;

  static DateTime? _date(Object? value) =>
      DateTime.tryParse(value?.toString() ?? '');

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final tenders = widget.tenders
        .where((r) => _period.contains(_date(r['closingDate'])))
        .toList();
    int tenderCount(TenderStatus status) => tenders
        .where((r) => TenderStatus.fromWire(r['status']) == status)
        .length;

    final rfcs = widget.rfcs
        .where((r) => _period.contains(_date(r['submissionDate'])))
        .toList();
    int rfcCount(Set<ErfcStatus> statuses) => rfcs
        .where((r) => statuses.contains(ErfcStatus.fromWire(r['status'])))
        .length;

    final submitted = rfcCount({ErfcStatus.submitted});
    final verified = rfcCount({
      ErfcStatus.firstVerified,
      ErfcStatus.secondVerified,
    });

    final closingSoon = <({Map<String, dynamic> record, int days})>[
      for (final r in widget.tenders)
        if (TenderStatus.openForBidding.contains(
          TenderStatus.fromWire(r['status']),
        ))
          if (_date(r['closingDate']) case final closing?)
            if (!closing.isBefore(now) &&
                closing.difference(now).inDays <= kClosingSoonDays)
              (record: r, days: closing.difference(now).inDays),
    ]..sort((a, b) => a.days.compareTo(b.days));

    final exceeded = <({Map<String, dynamic> record, int days})>[
      for (final r in widget.rfcs)
        if (ErfcStatus.fromWire(r['status']) == ErfcStatus.endorsed)
          if (_date(r['endorsedDate']) case final endorsed?)
            if (now.difference(endorsed).inDays > kErfcValidityDays)
              (
                record: r,
                days: now.difference(endorsed).inDays - kErfcValidityDays,
              ),
    ]..sort((a, b) => b.days.compareTo(a.days));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        DashPeriodSelector(
          selected: _period,
          onChanged: (period) => setState(() => _period = period),
        ),
        const SizedBox(height: 20),
        _Heading(
          title: 'Tender Status',
          linkLabel: 'Go to Tenders',
          onLink: () => widget.onNavigate(kTendersTabIndex),
        ),
        const SizedBox(height: 12),
        _TileGrid(
          tiles: [
            _StatusTile(
              value: tenderCount(TenderStatus.published),
              label: 'Published',
              note: 'Open for bidding',
              color: DashTheme.success,
            ),
            _StatusTile(
              value: tenderCount(TenderStatus.extended),
              label: 'Extended',
              note: 'Closing date extended',
              color: DashTheme.warning,
            ),
            _StatusTile(
              value: tenderCount(TenderStatus.closed),
              label: 'Closed',
              note: 'Pending opening',
              color: DashTheme.muted,
            ),
            _StatusTile(
              value: tenderCount(TenderStatus.completed),
              label: 'Completed',
              note: 'Appendix P completed',
              color: DashTheme.info,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _Heading(
          title: 'RFC Status',
          linkLabel: 'Go to RFC',
          onLink: () => widget.onNavigate(kErfcTabIndex),
        ),
        const SizedBox(height: 12),
        _TileGrid(
          tiles: [
            _StatusTile(
              value: submitted + verified,
              label: 'In Approval',
              note: '$submitted submitted · $verified verified',
              color: DashTheme.warning,
            ),
            _StatusTile(
              value: rfcCount({ErfcStatus.endorsed}),
              label: 'Endorsed',
              note: 'Validity running',
              color: DashTheme.success,
            ),
            _StatusTile(
              value: rfcCount({
                ErfcStatus.erfcCompleted,
                ErfcStatus.paperworkReceived,
                ErfcStatus.confirmToProceed,
              }),
              label: 'RFC Completed',
              note: 'Flowed to tender preparation',
              color: DashTheme.info,
            ),
            _StatusTile(
              value: exceeded.length,
              label: 'Exceeded Validity',
              note: 'Needs action',
              color: DashTheme.danger,
              emphasise: true,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _TwoUp(
          left: _ListCard(
            title: 'Tenders Closing Soon',
            subtitle: 'Next $kClosingSoonDays days',
            onViewAll: () => widget.onNavigate(kTendersTabIndex),
            emptyText: 'No tenders closing in the next $kClosingSoonDays days.',
            rows: [
              for (final entry in closingSoon.take(5))
                _ListRow(
                  reference: entry.record['tenderNo']?.toString() ?? '',
                  title: entry.record['title']?.toString() ?? '',
                  pill: entry.days == 0 ? 'Today' : '${entry.days} days left',
                  color: entry.days <= 3 ? DashTheme.danger : DashTheme.warning,
                ),
            ],
          ),
          right: _ListCard(
            title: 'RFC Exceeded Validity',
            subtitle: 'Still Endorsed after Valid Period',
            onViewAll: () => widget.onNavigate(kErfcTabIndex),
            emptyText: 'No endorsed RFCs have exceeded their validity.',
            rows: [
              for (final entry in exceeded.take(5))
                _ListRow(
                  reference: entry.record['rfcNumber']?.toString() ?? '',
                  title:
                      '${entry.record['department'] ?? ''} · '
                      '${entry.record['unit'] ?? ''}',
                  pill: '${entry.days} days over',
                  color: DashTheme.danger,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({
    required this.title,
    required this.linkLabel,
    required this.onLink,
  });

  final String title;
  final String linkLabel;
  final VoidCallback onLink;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: DashTheme.text,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      InkWell(
        onTap: onLink,
        child: Text(
          '$linkLabel ›',
          style: const TextStyle(
            color: DashTheme.accent,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ],
  );
}

class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 900
          ? 4
          : constraints.maxWidth >= 480
          ? 2
          : 1;
      final rows = <Widget>[];
      for (var s = 0; s < tiles.length; s += columns) {
        final e = (s + columns).clamp(0, tiles.length);
        rows.add(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = s; i < e; i++) ...[
                  if (i > s) const SizedBox(width: DashTheme.gap),
                  Expanded(child: tiles[i]),
                ],
                for (var i = e; i < s + columns; i++) ...[
                  const SizedBox(width: DashTheme.gap),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ],
            ),
          ),
        );
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: DashTheme.gap),
            rows[i],
          ],
        ],
      );
    },
  );
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.value,
    required this.label,
    required this.note,
    required this.color,
    this.emphasise = false,
  });

  final int value;
  final String label;
  final String note;
  final Color color;

  /// Tints the number too, for the one tile that asks for action.
  final bool emphasise;

  @override
  Widget build(BuildContext context) => Container(
    decoration: DashTheme.cardDecoration,
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: DashTheme.tintOf(color),
            border: Border.all(color: color.withValues(alpha: 0.25)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatNumber(value, decimals: 0),
                style: TextStyle(
                  color: emphasise ? color : DashTheme.text,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: DashTheme.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                note,
                style: const TextStyle(color: DashTheme.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _TwoUp extends StatelessWidget {
  const _TwoUp({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 800) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            left,
            const SizedBox(height: DashTheme.gap),
            right,
          ],
        );
      }
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: left),
            const SizedBox(width: DashTheme.gap),
            Expanded(child: right),
          ],
        ),
      );
    },
  );
}

class _ListRow {
  const _ListRow({
    required this.reference,
    required this.title,
    required this.pill,
    required this.color,
  });

  final String reference;
  final String title;
  final String pill;
  final Color color;
}

class _ListCard extends StatelessWidget {
  const _ListCard({
    required this.title,
    required this.subtitle,
    required this.onViewAll,
    required this.emptyText,
    required this.rows,
  });

  final String title;
  final String subtitle;
  final VoidCallback onViewAll;
  final String emptyText;
  final List<_ListRow> rows;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: DashTheme.cardDecoration,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: DashTheme.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: DashTheme.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: onViewAll,
                child: const Text(
                  'View all ›',
                  style: TextStyle(
                    color: DashTheme.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
            child: Text(
              emptyText,
              style: const TextStyle(color: DashTheme.muted, fontSize: 12),
            ),
          )
        else
          for (final row in rows)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: DashTheme.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.reference,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: DashTheme.accent,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          row.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: DashTheme.text,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: DashTheme.tintOf(row.color),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      row.pill,
                      style: TextStyle(
                        color: row.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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
