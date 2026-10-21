// lib/reports/procurement_lead_time/procurement_lead_time_screen.dart
//
// Statistic – Procurement Lead Time: working days from VTM receiving an RFC
// to the tender or quotation being published, banded and rated.
//
// Every figure depends on a received date range, so the report opens on the
// default period (LeadTimeRules.defaultPeriod) and searches it straight
// away; the received date chips re-search the moment they are tapped.
// How the rating is reached sits beside the search, where it stays in view.
import 'dart:async';

import 'package:etender_reports/data/services/report_export_service.dart';
import 'package:etender_reports/reports/models/export/report_export.dart';
import 'package:etender_reports/reports/procurement_lead_time/bloc/lead_time_cubit.dart';
import 'package:etender_reports/reports/procurement_lead_time/lead_time_rules.dart';
import 'package:etender_reports/reports/procurement_lead_time/models/lead_time_query.dart';
import 'package:etender_reports/reports/procurement_lead_time/models/lead_time_record.dart';
import 'package:etender_reports/reports/procurement_lead_time/widgets/lead_time_drilldown_table.dart';
import 'package:etender_reports/reports/procurement_lead_time/widgets/lead_time_filter_bar.dart';
import 'package:etender_reports/reports/procurement_lead_time/widgets/lead_time_rating_badge.dart';
import 'package:etender_reports/reports/procurement_lead_time/widgets/lead_time_rating_explanation.dart';
import 'package:etender_reports/reports/procurement_lead_time/widgets/lead_time_summary_section.dart';
import 'package:etender_reports/reports/report_type.dart';
import 'package:etender_reports/reports/widgets/shared/report_panel.dart';
import 'package:etender_reports/reports/widgets/shared/report_status_panel.dart';
import 'package:etender_reports/reports/widgets/shared/status_chip.dart';
import 'package:etender_reports/shared/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProcurementLeadTimeScreen extends StatefulWidget {
  const ProcurementLeadTimeScreen({
    super.key,
    required this.sectionSpacing,
    required this.fillHeight,
    this.today,
  });

  final double sectionSpacing;

  /// From this width the rating explanation sits beside the search panel.
  /// Narrower, the result header links to it in a dialog instead.
  static const double explanationBesideWidth = 1000;

  /// The explanation's width is picked from this range, in
  /// [explanationWidthStep]s, as whichever leaves it and the search panel
  /// closest in height, so neither is left with empty space at the bottom.
  /// Wider, its text takes fewer lines; but the search panel it narrows
  /// wraps its chips and radios onto more. At the minimum each rating rule
  /// still sits beside its badge; the maximum keeps it from sprawling.
  static const double explanationMinWidth = 400;
  static const double explanationMaxWidth = 560;
  static const double explanationWidthStep = 20;

  /// What the period presets count from. Defaults to the clock; a test
  /// passes a fixed date.
  final DateTime? today;

  /// When true the title band stays put and everything under it scrolls.
  final bool fillHeight;

  @override
  State<ProcurementLeadTimeScreen> createState() =>
      _ProcurementLeadTimeScreenState();
}

class _ProcurementLeadTimeScreenState extends State<ProcurementLeadTimeScreen> {
  bool _exporting = false;

  DateTime get _today => widget.today ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    // Only the first time: coming back to the report keeps the search the
    // user last ran.
    final cubit = context.read<LeadTimeCubit>();
    if (cubit.state.status == ReportStatus.initial) {
      unawaited(
        cubit.search(
          LeadTimeQuery.forPreset(LeadTimeRules.defaultPeriod, today: _today),
        ),
      );
    }
  }

  Future<void> _export(
    ExportFormat format,
    LeadTimeSelection selection,
    List<MeasuredLeadTime> items,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _exporting = true);
    try {
      final fileName = await const ReportExportService().export(
        ExportTable(
          fileBaseName:
              'procurement_lead_time_${selection.type.name}'
              '_${selection.bucket.key}',
          sheetName: 'Procurement Lead Time',
          columns: LeadTimeDrilldownTable.exportColumns,
          rows: [
            for (final item in items) LeadTimeDrilldownTable.exportRow(item),
          ],
        ),
        format,
      );
      messenger.showSnackBar(SnackBar(content: Text('Saved $fileName')));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not export these tenders.')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = widget.sectionSpacing;

    return BlocBuilder<LeadTimeCubit, LeadTimeState>(
      builder: (context, state) {
        final cubit = context.read<LeadTimeCubit>();
        final results = _buildResults(context, state, cubit);

        return LayoutBuilder(
          builder: (context, constraints) {
            final explanationBeside =
                constraints.maxWidth >=
                ProcurementLeadTimeScreen.explanationBesideWidth;
            final filters = LeadTimeFilterBar(
              today: _today,
              initialQuery: state.query,
              isSearching: state.status == ReportStatus.loading,
              onSearch: (query) => unawaited(cubit.search(query)),
            );

            // The search and explanation scroll away with the results
            // rather than staying pinned: together they are tall enough to
            // squeeze the results on a laptop screen.
            final body = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (explanationBeside)
                  _SameHeightPair(
                    minSideWidth: ProcurementLeadTimeScreen.explanationMinWidth,
                    maxSideWidth: ProcurementLeadTimeScreen.explanationMaxWidth,
                    sideWidthStep:
                        ProcurementLeadTimeScreen.explanationWidthStep,
                    gap: spacing,
                    children: [filters, const LeadTimeRatingExplanation()],
                  )
                else
                  filters,
                SizedBox(height: spacing),
                results,
              ],
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: widget.fillHeight
                  ? MainAxisSize.max
                  : MainAxisSize.min,
              children: [
                _TitleBand(state: state, showRatingLink: !explanationBeside),
                SizedBox(height: spacing),
                // Pinned: only the title band stays put. Not pinned: the
                // shell's page already scrolls.
                if (widget.fillHeight)
                  Expanded(child: SingleChildScrollView(child: body))
                else
                  body,
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildResults(
    BuildContext context,
    LeadTimeState state,
    LeadTimeCubit cubit,
  ) {
    switch (state.status) {
      case ReportStatus.initial:
        return const ReportMessagePanel(
          title: 'Procurement lead time',
          message:
              'Choose a received date range and mode of procurement, '
              'then press Search.',
        );
      case ReportStatus.loading:
        return const ReportLoadingIndicator();
      case ReportStatus.failure:
        return _ErrorPanel(
          message: state.errorMessage ?? 'Could not load report data.',
          onRetry: () => unawaited(cubit.retry()),
        );
      case ReportStatus.ready:
        break;
    }

    final query = state.query!;
    if (state.total == 0) {
      return ReportMessagePanel(
        title: 'No results',
        message:
            'No ${query.type.description}'
            '${_modeSuffix(query)} received between '
            '${formatDottedDate(query.receivedFrom)} and '
            '${formatDottedDate(query.receivedTo)} has been published.',
      );
    }

    final spacing = widget.sectionSpacing;
    final selection = state.selection!;
    final drilldownItems =
        state.selectedSummary?.itemsIn(selection.bucket) ?? const [];
    final showType = state.summaries.length > 1;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final summary in state.summaries) ...[
          LeadTimeSummarySection(
            summary: summary,
            selectedBucket: selection.type == summary.documentType
                ? selection.bucket
                : null,
            onBucketSelected: (bucket) =>
                cubit.selectBucket(summary.documentType, bucket),
          ),
          SizedBox(height: spacing),
        ],
        LeadTimeDrilldownTable(
          title:
              'Drill-down – '
              '${showType ? '${selection.type.label}, ' : ''}'
              '${selection.bucket.label}, ${drilldownItems.length} tenders',
          items: drilldownItems,
          isExporting: _exporting,
          onExport: (format) =>
              unawaited(_export(format, selection, drilldownItems)),
        ),
      ],
    );

    return content;
  }
}

/// Page title, and once there are results, what they cover in one line.
/// ', 7.2 Selective Tender/Quotation' when the search is for one mode;
/// nothing for all modes.
String _modeSuffix(LeadTimeQuery query) {
  final mode = query.procurementModeDescription;
  return mode == null ? '' : ', $mode';
}

class _TitleBand extends StatelessWidget {
  const _TitleBand({required this.state, required this.showRatingLink});

  final LeadTimeState state;

  /// The link to the rating explanation, for when it is not already on
  /// screen beside the search.
  final bool showRatingLink;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = state.query;
    final showResultLine = state.status == ReportStatus.ready && query != null;

    return ReportPanel(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 4,
          children: [
            Text(
              ReportType.procurementLeadTime.pageTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (showResultLine)
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Result – ${query.type.description}'
                    '${_modeSuffix(query)}, received '
                    '${formatDottedDate(query.receivedFrom)} to '
                    '${formatDottedDate(query.receivedTo)} '
                    '(${query.preset.label}) · ${state.total} tenders',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  // One per document type with anything to rate. Named by
                  // type only when there are two, e.g. 'Tender: Good'.
                  for (final summary in state.summaries)
                    if (summary.total > 0)
                      LeadTimeRatingBadge(
                        rating: summary.rating,
                        label: state.summaries.length > 1
                            ? '${summary.documentType.label}: '
                                  '${summary.rating.label}'
                            : 'Rating: ${summary.rating.label}',
                      ),
                  if (showRatingLink &&
                      state.summaries.any((summary) => summary.total > 0))
                    TextButton.icon(
                      onPressed: () => LeadTimeRatingExplanation.show(context),
                      icon: const Icon(Icons.info_outline, size: 16),
                      label: const Text('How is the rating calculated?'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        minimumSize: const Size(0, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  // A period still running will gain tenders yet.
                  if (query.preset.isToDate)
                    StatusChip(
                      label: 'To date – not final',
                      colors: ChipPalette.amber,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// The search panel and, on its right, the rating explanation, both as
/// tall as the taller of the two.
///
/// The explanation's width is whichever from [minSideWidth] to
/// [maxSideWidth], in [sideWidthStep]s, brings the two natural heights
/// closest, so the stretched one gains as little empty space as possible.
/// A tie goes to the shorter pair.
///
/// IntrinsicHeight cannot do this: the search panel measures its width with
/// a LayoutBuilder, which has no intrinsic height to report. So both are
/// laid out at each candidate width to find their natural heights, then
/// once more at the chosen width and the larger height. Both are small, so
/// the few extra layouts cost little.
class _SameHeightPair extends MultiChildRenderObjectWidget {
  const _SameHeightPair({
    required this.minSideWidth,
    required this.maxSideWidth,
    required this.sideWidthStep,
    required this.gap,
    required super.children,
  }) : assert(children.length == 2),
       assert(minSideWidth <= maxSideWidth),
       assert(sideWidthStep > 0);

  final double minSideWidth;
  final double maxSideWidth;
  final double sideWidthStep;
  final double gap;

  @override
  _RenderSameHeightPair createRenderObject(BuildContext context) =>
      _RenderSameHeightPair(
        minSideWidth: minSideWidth,
        maxSideWidth: maxSideWidth,
        sideWidthStep: sideWidthStep,
        gap: gap,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSameHeightPair renderObject,
  ) {
    renderObject
      ..minSideWidth = minSideWidth
      ..maxSideWidth = maxSideWidth
      ..sideWidthStep = sideWidthStep
      ..gap = gap;
  }
}

class _RenderSameHeightPair extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, MultiChildLayoutParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, MultiChildLayoutParentData> {
  _RenderSameHeightPair({
    required this._minSideWidth,
    required this._maxSideWidth,
    required this._sideWidthStep,
    required this._gap,
  });

  double _minSideWidth;
  set minSideWidth(double value) {
    if (value == _minSideWidth) return;
    _minSideWidth = value;
    markNeedsLayout();
  }

  double _maxSideWidth;
  set maxSideWidth(double value) {
    if (value == _maxSideWidth) return;
    _maxSideWidth = value;
    markNeedsLayout();
  }

  double _sideWidthStep;
  set sideWidthStep(double value) {
    if (value == _sideWidthStep) return;
    _sideWidthStep = value;
    markNeedsLayout();
  }

  double _gap;
  set gap(double value) {
    if (value == _gap) return;
    _gap = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! MultiChildLayoutParentData) {
      child.parentData = MultiChildLayoutParentData();
    }
  }

  @override
  void performLayout() {
    final main = firstChild!;
    final side = childAfter(main)!;
    double mainWidthFor(double sideWidth) =>
        (constraints.maxWidth - sideWidth - _gap).clamp(0.0, double.infinity);

    // Natural heights at each candidate width; keep the closest pair.
    var bestSideWidth = _minSideWidth;
    var bestDifference = double.infinity;
    var bestHeight = double.infinity;
    for (
      var sideWidth = _minSideWidth;
      sideWidth <= _maxSideWidth;
      sideWidth += _sideWidthStep
    ) {
      main.layout(
        BoxConstraints.tightFor(width: mainWidthFor(sideWidth)),
        parentUsesSize: true,
      );
      side.layout(
        BoxConstraints.tightFor(width: sideWidth),
        parentUsesSize: true,
      );
      final difference = (main.size.height - side.size.height).abs();
      final height = main.size.height > side.size.height
          ? main.size.height
          : side.size.height;
      if (difference < bestDifference ||
          (difference == bestDifference && height < bestHeight)) {
        bestSideWidth = sideWidth;
        bestDifference = difference;
        bestHeight = height;
      }
    }

    // A minimum height rather than a tight one: a child given a tight size
    // lays itself out again alone when its content changes (Custom adding
    // the date range), and would overflow instead of this pair measuring
    // again.
    final mainWidth = mainWidthFor(bestSideWidth);
    final height = constraints.constrainHeight(bestHeight);
    main.layout(
      BoxConstraints(
        minWidth: mainWidth,
        maxWidth: mainWidth,
        minHeight: height,
      ),
      parentUsesSize: true,
    );
    side.layout(
      BoxConstraints(
        minWidth: bestSideWidth,
        maxWidth: bestSideWidth,
        minHeight: height,
      ),
      parentUsesSize: true,
    );

    (main.parentData! as MultiChildLayoutParentData).offset = Offset.zero;
    (side.parentData! as MultiChildLayoutParentData).offset = Offset(
      mainWidth + _gap,
      0,
    );
    size = constraints.constrain(Size(constraints.maxWidth, height));
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

/// The load failure, with a way to try the same search again.
class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ReportPanel(
      title: 'Something went wrong',
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
