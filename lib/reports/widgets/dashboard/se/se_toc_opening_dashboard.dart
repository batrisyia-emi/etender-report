import 'package:etender_reports/reports/models/records/toc_opening_record.dart';
import 'package:etender_reports/reports/models/status/toc_status.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_cards.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_period.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_scroll.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_theme.dart';
import 'package:etender_reports/shared/utils/formatters.dart';
import 'package:flutter/material.dart';

class SeTocOpeningDashboard extends StatefulWidget {
  const SeTocOpeningDashboard({super.key, required this.records});

  final List<TocOpeningRecord> records;

  @override
  State<SeTocOpeningDashboard> createState() => _SeTocOpeningDashboardState();
}

class _SeTocOpeningDashboardState extends State<SeTocOpeningDashboard> {
  DashPeriod _period = DashPeriod.thisMonth;
  _EnvelopeFilter _envelopeFilter = _EnvelopeFilter.both;
  TocStatus? _pendingStatus;
  bool _showPendingDetails = false;
  bool _showAllPending = false;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final records = widget.records.where((record) {
      final closing = record.closingDateTime;
      return closing != null && _period.contains(closing);
    }).toList();
    final total = records.length;
    final twoEnvelope = records
        .where(
          (record) => record.envelopeTypeValue == TocEnvelopeType.twoEnvelope,
        )
        .length;
    final oneEnvelope = records
        .where(
          (record) => record.envelopeTypeValue == TocEnvelopeType.oneEnvelope,
        )
        .length;
    final open = _count(records, TocStatus.open);
    final appointed = _count(records, TocStatus.committeeAppointed);
    final inProgress = _count(records, TocStatus.openingInProgress);
    final opened = records.where(_isOpenedPendingAppendixP).length;
    final completed = records
        .where((record) => record.appendixPSubmittedAt != null)
        .length;
    final lifecycleRecords = widget.records.where((record) {
      final opening = record.openingDateTime;
      return opening != null &&
          opening.year == now.year &&
          opening.month == now.month;
    }).toList();

    final pending = records.where((record) {
      final closing = record.closingDateTime;
      return closing != null &&
          !closing.isAfter(now) &&
          record.appendixPSubmittedAt == null;
    }).toList();
    final maxPendingCount = _pendingStatuses
        .map((status) => _count(pending, status))
        .fold<int>(0, (maximum, count) => count > maximum ? count : maximum);
    final flowRecords = records.where((record) {
      return switch (_envelopeFilter) {
        _EnvelopeFilter.both => true,
        _EnvelopeFilter.two =>
          record.envelopeTypeValue == TocEnvelopeType.twoEnvelope,
        _EnvelopeFilter.single =>
          record.envelopeTypeValue == TocEnvelopeType.oneEnvelope,
      };
    }).toList();
    final filteredPending = _pendingStatus == null
        ? pending
        : pending
              .where((record) => record.statusValue == _pendingStatus)
              .toList();
    final visiblePending = _showAllPending
        ? filteredPending
        : filteredPending.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        DashPeriodSelector(
          selected: _period,
          onChanged: (period) => setState(() {
            _period = period;
            _pendingStatus = null;
            _showAllPending = false;
          }),
        ),
        const SizedBox(height: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SeSectionHeading(
              title: 'Tender Opening Overview Status',
              metadata:
                  'SE view · $total openings · $twoEnvelope two-envelope · '
                  '$oneEnvelope single-envelope · '
                  '${_period.describe()}',
            ),
            const SizedBox(height: 12),
            SeOverviewMetricGrid(
              cards: [
                SeOverviewMetric(
                  label: 'Open',
                  value: open,
                  total: total,
                  subtext: 'Awaiting TOC appointment by VTM',
                  accent: DashTheme.warning,
                  icon: Icons.mail_outline,
                ),
                SeOverviewMetric(
                  label: 'Committee Appointed',
                  value: appointed,
                  total: total,
                  subtext: 'TOC members appointed',
                  accent: DashTheme.info,
                  icon: Icons.person_outline,
                ),
                SeOverviewMetric(
                  label: 'Opening In Progress',
                  value: inProgress,
                  total: total,
                  subtext: 'Committee performing the opening',
                  accent: DashTheme.purple,
                  icon: Icons.schedule_outlined,
                ),
                SeOverviewMetric(
                  label: 'Opened',
                  value: opened,
                  total: total,
                  subtext: 'Technical/Commercial or Tender opened, pending Appendix P',
                  accent: DashTheme.accent,
                  icon: Icons.mail_outline,
                ),
                SeOverviewMetric(
                  label: 'Opening Completed',
                  value: completed,
                  total: total,
                  subtext: 'Appendix P filled, checklist e-signed',
                  accent: DashTheme.success,
                  icon: Icons.check_circle_outline,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: DashTheme.gap),
        _statusFlowSection(
          title: 'Tender Opening Status Flow',
          metadata:
              'Tender opening status (SE view) · $total openings · '
              '${_period.describe()}',
          filter: _EnvelopeFilterControl(
            value: _envelopeFilter,
            twoEnvelopeCount: twoEnvelope,
            singleEnvelopeCount: oneEnvelope,
            onChanged: (value) => setState(() => _envelopeFilter = value),
          ),
          records: flowRecords,
        ),
        const SizedBox(height: DashTheme.gap),
        DashSplitRow(
          wide: seSection(
            title: 'Openings Pending Action',
            metadata:
                '${pending.length} closed tenders not yet Opening Completed · '
                'click a status to list them',
            icon: Icons.format_list_bulleted,
            trailing: TextButton(
              onPressed: () => setState(() {
                _showPendingDetails = !_showPendingDetails;
                if (!_showPendingDetails) _showAllPending = false;
              }),
              child: Text(_showPendingDetails ? 'Hide details' : 'View all'),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final status in _pendingStatuses) ...[
                  _PendingStatusRow(
                    status: status,
                    count: _count(pending, status),
                    maximum: maxPendingCount,
                    selected: _pendingStatus == status,
                    onTap: () => setState(() {
                      _pendingStatus = _pendingStatus == status ? null : status;
                      _showPendingDetails = true;
                    }),
                  ),
                  if (status != _pendingStatuses.last)
                    const SizedBox(height: 12),
                ],
                if (_showPendingDetails) ...[
                  const SizedBox(height: 12),
                  if (filteredPending.isEmpty)
                    const Text(
                      'No openings match this status.',
                      style: TextStyle(color: DashTheme.muted, fontSize: 12),
                    )
                  else ...[
                    _PendingTable(records: visiblePending),
                    if (!_showAllPending && filteredPending.length > 6)
                      Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () =>
                              setState(() => _showAllPending = true),
                          child: Text('Show all ${filteredPending.length}'),
                        ),
                      ),
                  ],
                ],
              ],
            ),
          ),
          narrow: seSection(
            title: 'Opening Lifecycle',
            metadata:
                '${dashMonthName(now.month)} ${now.year} · '
                '${lifecycleRecords.length} records',
            icon: Icons.bar_chart,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final item in _lifecycleStages) ...[
                  SeLifecycleProgress(
                    label: item.$1,
                    count: _lifecycleCount(lifecycleRecords, item.$2),
                    total: lifecycleRecords.length,
                    color: item.$3,
                  ),
                  if (item != _lifecycleStages.last) const SizedBox(height: 14),
                ],
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                const Text(
                  'Current status of openings active this month, regardless '
                  'of the period filter.',
                  style: TextStyle(
                    color: DashTheme.muted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

enum _EnvelopeFilter { both, two, single }

const _pendingStatuses = [
  TocStatus.open,
  TocStatus.committeeAppointed,
  TocStatus.openingInProgress,
  TocStatus.technicalOpened,
  TocStatus.commercialSealed,
  TocStatus.commercialOpened,
  TocStatus.tenderOpened,
];

enum _LifecycleKind {
  open,
  committeeAppointed,
  openingInProgress,
  opened,
  completed,
}

const _lifecycleStages = [
  ('Open', _LifecycleKind.open, DashTheme.muted),
  ('Committee Appointed', _LifecycleKind.committeeAppointed, DashTheme.accent),
  ('Opening In Progress', _LifecycleKind.openingInProgress, DashTheme.warning),
  ('Opened (pending Appendix P)', _LifecycleKind.opened, DashTheme.purple),
  ('Opening Completed', _LifecycleKind.completed, DashTheme.success),
];

class SeOverviewMetric extends StatelessWidget {
  const SeOverviewMetric({
    super.key,
    required this.label,
    required this.value,
    required this.total,
    required this.subtext,
    required this.accent,
    required this.icon,
  });

  final String label;
  final int value;
  final int total;
  final String subtext;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final percentage = total == 0 ? 0 : (value * 100 / total).round();
    return Container(
      decoration: DashTheme.cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: DashTheme.tintOf(accent),
              borderRadius: BorderRadius.circular(DashTheme.radius),
            ),
            child: Icon(icon, size: 22, color: accent),
          ),
          const SizedBox(height: 12),
          Text(
            formatNumber(value, decimals: 0),
            style: const TextStyle(
              color: DashTheme.text,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: DashTheme.text,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '$percentage% · $subtext',
            style: const TextStyle(
              color: DashTheme.muted,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class SeOverviewMetricGrid extends StatelessWidget {
  const SeOverviewMetricGrid({super.key, required this.cards});

  final List<Widget> cards;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 1000
          ? 5
          : constraints.maxWidth >= 600
          ? 3
          : constraints.maxWidth >= 400
          ? 2
          : 1;
      final rows = <Widget>[];

      for (var start = 0; start < cards.length; start += columns) {
        final end = (start + columns).clamp(0, cards.length);
        rows.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = start; index < end; index++) ...[
                if (index > start) const SizedBox(width: DashTheme.gap),
                Expanded(child: cards[index]),
              ],
              for (var index = end; index < start + columns; index++) ...[
                const SizedBox(width: DashTheme.gap),
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
          for (var index = 0; index < rows.length; index++) ...[
            if (index > 0) const SizedBox(height: DashTheme.gap),
            IntrinsicHeight(child: rows[index]),
          ],
        ],
      );
    },
  );
}

class _EnvelopeFilterControl extends StatelessWidget {
  const _EnvelopeFilterControl({
    required this.value,
    required this.twoEnvelopeCount,
    required this.singleEnvelopeCount,
    required this.onChanged,
  });

  final _EnvelopeFilter value;
  final int twoEnvelopeCount;
  final int singleEnvelopeCount;
  final ValueChanged<_EnvelopeFilter> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 4,
    alignment: WrapAlignment.end,
    children: [
      _filterButton(
        count: null,
        label: 'Single & two-envelope',
        filter: _EnvelopeFilter.both,
      ),
      _filterButton(
        count: twoEnvelopeCount,
        label: 'Two-envelope',
        filter: _EnvelopeFilter.two,
      ),
      _filterButton(
        count: singleEnvelopeCount,
        label: 'Single envelope',
        filter: _EnvelopeFilter.single,
      ),
    ],
  );

  Widget _filterButton({
    required int? count,
    required String label,
    required _EnvelopeFilter filter,
  }) => InkWell(
    borderRadius: BorderRadius.circular(18),
    onTap: () => onChanged(filter),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (count != null)
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: filter == _EnvelopeFilter.two
                    ? DashTheme.tintOf(DashTheme.purple)
                    : DashTheme.tintOf(DashTheme.info),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: filter == _EnvelopeFilter.two
                      ? DashTheme.purple
                      : DashTheme.info,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: value == filter
                    ? DashTheme.tintOf(DashTheme.accent)
                    : DashTheme.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Both',
                style: TextStyle(
                  color: value == filter ? DashTheme.accent : DashTheme.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Text(
            label,
            style: TextStyle(
              color: value == filter ? DashTheme.primary : DashTheme.muted,
              fontSize: 11,
              fontWeight: value == filter ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}

class _StatusFlow extends StatelessWidget {
  const _StatusFlow({required this.records});

  final List<TocOpeningRecord> records;

  @override
  Widget build(BuildContext context) {
    final twoEnvelopeCount = records
        .where(
          (record) => record.envelopeTypeValue == TocEnvelopeType.twoEnvelope,
        )
        .length;
    final singleEnvelopeCount = records
        .where(
          (record) => record.envelopeTypeValue == TocEnvelopeType.oneEnvelope,
        )
        .length;
    final stages = [
      const _FlowStage(
        step: 'Open',
        title: 'Open',
        statuses: [TocStatus.open],
        detail: 'First status · VTM to appoint TOC',
        envelopeLabel: 'Both',
        color: DashTheme.muted,
      ),
      const _FlowStage(
        step: 'Appoint',
        title: 'Committee Appointed',
        statuses: [TocStatus.committeeAppointed],
        detail: 'TOC members appointed by VTM',
        envelopeLabel: 'Both',
        color: DashTheme.accent,
      ),
      const _FlowStage(
        step: 'Opening',
        title: 'Opening In Progress',
        statuses: [TocStatus.openingInProgress],
        detail: 'Committee performing the opening',
        envelopeLabel: 'Both',
        color: DashTheme.warning,
      ),
      _FlowStage(
        step: 'Two-envelope',
        title: 'Technical / Commercial',
        statuses: const [
          TocStatus.technicalOpened,
          TocStatus.commercialSealed,
          TocStatus.commercialOpened,
        ],
        detail: 'Commercial opening enabled after Technical Opened',
        envelopeLabel: '$twoEnvelopeCount',
        color: DashTheme.purple,
      ),
      _FlowStage(
        step: 'Single',
        title: 'Tender Opened',
        statuses: const [TocStatus.tenderOpened],
        detail: 'TOC completed single-envelope opening',
        envelopeLabel: '$singleEnvelopeCount',
        color: DashTheme.info,
      ),
      const _FlowStage(
        step: 'Complete',
        title: 'Opening Completed',
        statuses: [TocStatus.openingCompleted],
        detail: 'VTM filed Appendix P · register finalised',
        envelopeLabel: 'Both',
        color: DashTheme.success,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth >= 1200 ? 200.0 : 190.0;
        return DashHorizontalScroll(
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < stages.length; index++) ...[
                  if (index > 0) const SizedBox(width: 12),
                  _FlowStageCard(
                    stage: stages[index],
                    records: records,
                    width: cardWidth,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FlowStage {
  const _FlowStage({
    required this.step,
    required this.title,
    required this.statuses,
    required this.detail,
    required this.envelopeLabel,
    required this.color,
  });

  final String step;
  final String title;
  final List<TocStatus> statuses;
  final String detail;
  final String envelopeLabel;
  final Color color;
}

class _FlowStageCard extends StatelessWidget {
  const _FlowStageCard({
    required this.stage,
    required this.records,
    required this.width,
  });

  final _FlowStage stage;
  final List<TocOpeningRecord> records;
  final double width;

  @override
  Widget build(BuildContext context) {
    final statusCounts = [
      for (final status in stage.statuses)
        (
          status: status,
          count: _count(records, status),
          color: _statusColor(status),
        ),
    ];
    final count = statusCounts.fold<int>(
      0,
      (total, item) => total + item.count,
    );

    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 190),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DashTheme.background,
        border: Border.all(color: DashTheme.border),
        borderRadius: BorderRadius.circular(DashTheme.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: stage.color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  stage.step,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                stage.envelopeLabel,
                style: TextStyle(
                  color: stage.color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            stage.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: DashTheme.text,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          if (statusCounts.length == 1)
            _FlowStatusCount(
              label: statusCounts.single.status.wireValue,
              count: count,
              color: statusCounts.single.color,
            )
          else
            for (final item in statusCounts)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: _FlowStatusCount(
                  label: item.status.wireValue,
                  count: item.count,
                  color: item.color,
                ),
              ),
          const SizedBox(height: 10),
          const Divider(height: 12),
          Text(
            stage.detail,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: DashTheme.muted,
              fontSize: 10,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowStatusCount extends StatelessWidget {
  const _FlowStatusCount({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(Icons.circle, size: 8, color: color),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: DashTheme.text, fontSize: 11),
        ),
      ),
      const SizedBox(width: 6),
      Text(
        '$count',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

Color _statusColor(TocStatus status) => switch (status) {
  TocStatus.open => DashTheme.muted,
  TocStatus.committeeAppointed => DashTheme.accent,
  TocStatus.openingInProgress => DashTheme.warning,
  TocStatus.technicalOpened => DashTheme.info,
  TocStatus.commercialSealed => DashTheme.purple,
  TocStatus.commercialOpened => DashTheme.primary,
  TocStatus.tenderOpened => DashTheme.info,
  TocStatus.openingCompleted => DashTheme.success,
};

class _PendingStatusRow extends StatelessWidget {
  const _PendingStatusRow({
    required this.status,
    required this.count,
    required this.maximum,
    required this.selected,
    required this.onTap,
  });

  final TocStatus status;
  final int count;
  final int maximum;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(DashTheme.radius),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 145,
            child: Text(
              status.wireValue,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? DashTheme.accent : DashTheme.text,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: maximum == 0 ? 0 : count / maximum,
                minHeight: 8,
                backgroundColor: DashTheme.background,
                color: _statusColor(status),
              ),
            ),
          ),
          SizedBox(
            width: 30,
            child: Text(
              '$count',
              textAlign: TextAlign.end,
              style: TextStyle(
                color: selected ? DashTheme.accent : DashTheme.text,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PendingTable extends StatelessWidget {
  const _PendingTable({required this.records});

  final List<TocOpeningRecord> records;

  @override
  Widget build(BuildContext context) => DashHorizontalScroll(
    child: DataTable(
      headingRowHeight: 38,
      dataRowMinHeight: 44,
      dataRowMaxHeight: 64,
      columnSpacing: 20,
      horizontalMargin: 10,
      headingRowColor: const WidgetStatePropertyAll(DashTheme.background),
      columns: const [
        DataColumn(label: Text('T/Q No.')),
        DataColumn(label: Text('Title')),
        DataColumn(label: Text('Envelope')),
        DataColumn(label: Text('Opening Status')),
        DataColumn(label: Text('Next Action')),
      ],
      rows: [
        for (final record in records)
          DataRow(
            cells: [
              DataCell(Text(record.tenderNo)),
              DataCell(
                SizedBox(
                  width: 250,
                  child: Text(
                    record.projectTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(Text(record.envelopeType)),
              DataCell(Text(record.status)),
              DataCell(Text(_nextAction(record))),
            ],
          ),
      ],
    ),
  );
}

class SeLifecycleProgress extends StatelessWidget {
  const SeLifecycleProgress({
    super.key,
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  final String label;
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: DashTheme.text, fontSize: 11),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count of $total',
            style: const TextStyle(color: DashTheme.muted, fontSize: 11),
          ),
        ],
      ),
      const SizedBox(height: 7),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: total == 0 ? 0 : count / total,
          minHeight: 8,
          backgroundColor: DashTheme.background,
          color: color,
        ),
      ),
    ],
  );
}

class SeSectionHeading extends StatelessWidget {
  const SeSectionHeading({
    super.key,
    required this.title,
    required this.metadata,
  });

  final String title;
  final String metadata;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final titleWidget = Text(
        title,
        style: const TextStyle(
          color: DashTheme.text,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      );
      final metadataWidget = Text(
        metadata,
        textAlign: TextAlign.right,
        style: const TextStyle(color: DashTheme.muted, fontSize: 11),
      );

      if (constraints.maxWidth < 700) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [titleWidget, const SizedBox(height: 4), metadataWidget],
        );
      }

      return Row(
        children: [
          Expanded(child: titleWidget),
          const SizedBox(width: 12),
          Flexible(child: metadataWidget),
        ],
      );
    },
  );
}

Widget seSection({
  required String title,
  required String metadata,
  required Widget child,
  required IconData icon,
  Widget? trailing,
}) => DashCard(
  icon: icon,
  title: title,
  subtitle: metadata,
  trailing: trailing,
  child: child,
);

Widget _statusFlowSection({
  required String title,
  required String metadata,
  required Widget filter,
  required List<TocOpeningRecord> records,
}) => LayoutBuilder(
  builder: (context, constraints) {
    return seSection(
      title: title,
      metadata: metadata,
      icon: Icons.show_chart,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(alignment: Alignment.centerRight, child: filter),
          const SizedBox(height: 12),
          _StatusFlow(records: records),
        ],
      ),
    );
  },
);

int _count(List<TocOpeningRecord> records, TocStatus status) =>
    records.where((record) => record.statusValue == status).length;

int _lifecycleCount(List<TocOpeningRecord> records, _LifecycleKind kind) =>
    switch (kind) {
      _LifecycleKind.open => _count(records, TocStatus.open),
      _LifecycleKind.committeeAppointed => _count(
        records,
        TocStatus.committeeAppointed,
      ),
      _LifecycleKind.openingInProgress => _count(
        records,
        TocStatus.openingInProgress,
      ),
      _LifecycleKind.opened => records.where(_isOpenedPendingAppendixP).length,
      _LifecycleKind.completed =>
        records.where((record) => record.appendixPSubmittedAt != null).length,
    };

bool _isOpenedPendingAppendixP(TocOpeningRecord record) =>
    record.appendixPSubmittedAt == null &&
    const {
      TocStatus.technicalOpened,
      TocStatus.commercialSealed,
      TocStatus.commercialOpened,
      TocStatus.tenderOpened,
    }.contains(record.statusValue);

String _nextAction(TocOpeningRecord record) => switch (record.statusValue) {
  TocStatus.open => 'Awaiting TOC appointment by VTM',
  TocStatus.committeeAppointed => 'Committee to begin opening',
  TocStatus.openingInProgress => 'Committee performing the opening',
  TocStatus.technicalOpened ||
  TocStatus.commercialOpened ||
  TocStatus.tenderOpened => 'Complete Appendix P',
  TocStatus.commercialSealed => 'Commercial envelope remains sealed',
  TocStatus.openingCompleted => 'Complete Appendix P',
  null => 'Review opening status',
};
