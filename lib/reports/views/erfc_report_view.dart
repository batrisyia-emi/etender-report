// lib/reports/views/erfc_report_view.dart
import 'package:etender_reports/reports/bloc/erfc/erfc_bloc.dart';
import 'package:etender_reports/reports/models/filters/report_criteria.dart';
// The bloc file re-exports its event, state and ReportStatus.
import 'package:etender_reports/reports/models/filters/report_filters.dart';
import 'package:etender_reports/reports/report_type.dart';
import 'package:etender_reports/reports/widgets/erfc/erfc_filter_panel.dart';
import 'package:etender_reports/reports/widgets/erfc/erfc_processing_time_panel.dart';
import 'package:etender_reports/reports/widgets/erfc/erfc_report_table.dart';
import 'package:etender_reports/reports/widgets/shared/collapsible_section.dart';
import 'package:etender_reports/reports/widgets/shared/report_header.dart';
import 'package:etender_reports/reports/widgets/shared/report_status_panel.dart';
import 'package:etender_reports/reports/widgets/shared/report_timeline_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ErfcReportView extends StatefulWidget {
  const ErfcReportView({
    super.key,
    required this.sectionSpacing,
    required this.fillHeight,
  });

  final double sectionSpacing;

  /// When true the filters and overview stay put and only the table scrolls.
  final bool fillHeight;

  @override
  State<ErfcReportView> createState() => _ErfcReportViewState();
}

class _ErfcReportViewState extends State<ErfcReportView> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final filters = context.read<ErfcBloc>().state.filters;
    _searchController = TextEditingController(text: filters.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _syncControllers(ErfcFilters filters) {
    if (_searchController.text != filters.searchQuery) {
      _searchController.text = filters.searchQuery;
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = widget.sectionSpacing;

    return BlocConsumer<ErfcBloc, ErfcState>(
      listenWhen: (previous, current) => previous.filters != current.filters,
      listener: (context, state) => _syncControllers(state.filters),
      builder: (context, state) {
        if (state.status == ReportStatus.failure) {
          return ReportMessagePanel(
            title: 'Something went wrong',
            message: state.errorMessage ?? 'Could not load report data.',
          );
        }
        if (state.status != ReportStatus.ready) {
          return const ReportLoadingIndicator();
        }

        final bloc = context.read<ErfcBloc>();
        final filters = state.filters;
        final records = state.filteredRecords;

        // fillHeight is deliberately not passed through. This page
        // pins only the filters; everything below them scrolls as one
        // column, so the table takes its own capped height rather
        // than the page's.
        final table = ErfcReportTable(
          records: records,
          fillHeight: widget.fillHeight,
        );

        // Aging metrics by division. Collapsed by default so the table
        // keeps its height; the header carries the overall average.
        final processingTimes = CollapsibleSection(
          title: 'Processing Time by Division',
          collapsedSummary: 'Submission to endorsement, per division',
          icon: Icons.speed_outlined,
          initiallyExpanded: false,
          child: ErfcProcessingTimePanel(records: records),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: widget.fillHeight ? MainAxisSize.max : MainAxisSize.min,
          children: [
            ReportHeader(
              title: ReportType.erfc.pageTitle,
              criteria: filters.describe(),
              shownCount: records.length,
              totalCount: state.records.length,
              unit: 'eRFCs',
            ),
            SizedBox(height: spacing),
            ReportTimelineFilter(
              label: 'Submission date',
              selectedRange: filters.submissionDateRange,
              onChanged: (range) => bloc.add(ErfcSubmissionDateChanged(range)),
            ),
            SizedBox(height: spacing),
            ErfcFilterPanel(
              searchController: _searchController,
              onSearchChanged: (value) => bloc.add(ErfcSearchChanged(value)),
              divisions: state.divisionOptions,
              selectedDivisions: filters.divisions,
              onDivisionsChanged: (values) =>
                  bloc.add(ErfcDivisionsChanged(values)),
              units: state.unitOptions,
              selectedUnits: filters.units,
              onUnitsChanged: (values) => bloc.add(ErfcUnitsChanged(values)),
              procurementModes: state.procurementModeOptions,
              selectedProcurementModes: filters.procurementModes,
              onProcurementModesChanged: (values) =>
                  bloc.add(ErfcProcurementModesChanged(values)),
              statuses: ErfcState.lifecycleStatuses,
              selectedStatuses: filters.statuses,
              onStatusesChanged: (values) =>
                  bloc.add(ErfcStatusesChanged(values)),
              submissionDateFilter: filters.submissionDateRange,
              onSubmissionDateChanged: (range) =>
                  bloc.add(ErfcSubmissionDateChanged(range)),
              overdueOnly: filters.overdueOnly,
              onOverdueOnlyChanged: (value) =>
                  bloc.add(ErfcOverdueOnlyChanged(value)),
              onFiltersReset: () => bloc.add(const ErfcFiltersCleared()),
            ),
            SizedBox(height: spacing),
            processingTimes,
            SizedBox(height: spacing),
            if (widget.fillHeight) Expanded(child: table) else table,
          ],
        );
      },
    );
  }
}
