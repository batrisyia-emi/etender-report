// lib/reports/procurement_lead_time/procurement_lead_time_screen.dart
//
// Statistic – Procurement Lead Time: working days from VTM receiving an RFC
// to the tender or quotation being published, banded and rated.
//
// Every figure depends on a published date range, so the report opens on the
// default period (LeadTimeRules.defaultPeriod) and searches it straight
// away; the period chips re-search the moment they are tapped.
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
import 'package:flutter_bloc/flutter_bloc.dart';

class ProcurementLeadTimeScreen extends StatefulWidget {
  const ProcurementLeadTimeScreen({
    super.key,
    required this.sectionSpacing,
    required this.fillHeight,
    this.today,
  });

  final double sectionSpacing;

  /// What the period presets count from. Defaults to the clock; a test
  /// passes a fixed date.
  final DateTime? today;

  /// When true the header and search stay put and the results scroll.
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: widget.fillHeight ? MainAxisSize.max : MainAxisSize.min,
          children: [
            _TitleBand(state: state),
            SizedBox(height: spacing),
            LeadTimeFilterBar(
              today: _today,
              initialQuery: state.query,
              isSearching: state.status == ReportStatus.loading,
              onSearch: (query) => unawaited(cubit.search(query)),
            ),
            SizedBox(height: spacing),
            if (widget.fillHeight) Expanded(child: results) else results,
          ],
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
              'Choose a published date range and mode of procurement, '
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
            '${_modeSuffix(query)} was published between '
            '${formatDottedDate(query.publishedFrom)} and '
            '${formatDottedDate(query.publishedTo)}.',
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
        // Once, after the sections it explains, and before the rows.
        const LeadTimeRatingExplanation(),
        SizedBox(height: spacing),
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

    // Pinned: the summaries and drill-down scroll under the search. Not
    // pinned: the shell's page already scrolls.
    return widget.fillHeight ? SingleChildScrollView(child: content) : content;
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
  const _TitleBand({required this.state});

  final LeadTimeState state;

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
                    '${_modeSuffix(query)}, published '
                    '${formatDottedDate(query.publishedFrom)} to '
                    '${formatDottedDate(query.publishedTo)} '
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
