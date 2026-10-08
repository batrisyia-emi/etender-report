// lib/reports/views/vtm_monitoring_view.dart
//
// VTM Tender/Quotation Monitoring: Appendix F preparation, verification,
// approval and floating.
//
// Read-only. The report watches a process that happens in other screens —
// nothing here changes a document.
import 'package:etender_reports/reports/bloc/vtm_monitoring/vtm_monitoring_bloc.dart';
import 'package:etender_reports/reports/models/filters/report_criteria.dart';
// The bloc file re-exports its event, state and ReportStatus.
import 'package:etender_reports/reports/models/filters/vtm_monitoring_filters.dart';
import 'package:etender_reports/reports/models/metrics/vtm_monitoring_metrics.dart';
import 'package:etender_reports/reports/report_type.dart';
import 'package:etender_reports/reports/widgets/shared/collapsible_section.dart';
import 'package:etender_reports/reports/widgets/shared/report_header.dart';
import 'package:etender_reports/reports/widgets/shared/report_status_panel.dart';
import 'package:etender_reports/reports/widgets/shared/report_timeline_filter.dart';
import 'package:etender_reports/reports/widgets/vtm_monitoring/vtm_monitoring_filter_panel.dart';
import 'package:etender_reports/reports/widgets/vtm_monitoring/vtm_monitoring_flag_panel.dart';
import 'package:etender_reports/reports/widgets/vtm_monitoring/vtm_monitoring_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class VtmMonitoringView extends StatefulWidget {
  const VtmMonitoringView({
    super.key,
    required this.sectionSpacing,
    required this.fillHeight,
  });

  final double sectionSpacing;

  /// When true the filters stay put and the rest of the page scrolls.
  final bool fillHeight;

  @override
  State<VtmMonitoringView> createState() => _VtmMonitoringViewState();
}

class _VtmMonitoringViewState extends State<VtmMonitoringView> {
  late final TextEditingController _erfcNoController;
  late final TextEditingController _tenderNoController;

  @override
  void initState() {
    super.initState();
    final filters = context.read<VtmMonitoringBloc>().state.filters;
    _erfcNoController = TextEditingController(text: filters.erfcNoQuery);
    _tenderNoController = TextEditingController(text: filters.tenderNoQuery);
  }

  @override
  void dispose() {
    _erfcNoController.dispose();
    _tenderNoController.dispose();
    super.dispose();
  }

  /// Keeps the text fields in step when the filters change from elsewhere,
  /// e.g. the Reset button.
  void _syncControllers(VtmMonitoringFilters filters) {
    if (_erfcNoController.text != filters.erfcNoQuery) {
      _erfcNoController.text = filters.erfcNoQuery;
    }
    if (_tenderNoController.text != filters.tenderNoQuery) {
      _tenderNoController.text = filters.tenderNoQuery;
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = widget.sectionSpacing;

    return BlocConsumer<VtmMonitoringBloc, VtmMonitoringState>(
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

        final bloc = context.read<VtmMonitoringBloc>();
        final filters = state.filters;
        final records = state.filteredRecords;

        final flags = vtmFlags(records);
        final urgent = flags
            .where((flag) => flag.severity == VtmFlagSeverity.high)
            .length;

        final attention = CollapsibleSection(
          title: 'Needs Attention',
          collapsedSummary: flags.isEmpty
              ? 'Nothing stuck or unexplained'
              : '$urgent urgent, ${flags.length - urgent} to watch',
          icon: Icons.warning_amber_rounded,
          child: VtmMonitoringFlagPanel(records: records),
        );

        // The filters stay put at the top — still collapsible, just not
        // scrolled away — and the rest scrolls under them, as on the TOC
        // and tender security reports.
        final table = VtmMonitoringTable(
          records: records,
          fillHeight: widget.fillHeight,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: widget.fillHeight ? MainAxisSize.max : MainAxisSize.min,
          children: [
            ReportHeader(
              title: ReportType.vtmMonitoring.pageTitle,
              criteria: filters.describe(),
              shownCount: records.length,
              totalCount: state.records.length,
              unit: 'documents',
            ),
            SizedBox(height: spacing),
            ReportTimelineFilter(
              label: 'eRFC endorsed',
              selectedRange: filters.endorsedDateRange,
              onChanged: (range) => bloc.add(VtmEndorsedDateChanged(range)),
            ),
            SizedBox(height: spacing),
            VtmMonitoringFilterPanel(
              erfcNoController: _erfcNoController,
              onErfcNoChanged: (value) =>
                  bloc.add(VtmErfcNoQueryChanged(value)),
              tenderNoController: _tenderNoController,
              onTenderNoChanged: (value) =>
                  bloc.add(VtmTenderNoQueryChanged(value)),
              documentTypes: VtmMonitoringState.documentTypeOptions,
              selectedDocumentType: filters.documentType,
              onDocumentTypeChanged: (value) =>
                  bloc.add(VtmDocumentTypeChanged(value)),
              statuses: VtmMonitoringState.statusOptions,
              statusLabels: VtmMonitoringState.statusLabels,
              selectedStatuses: filters.statuses,
              onStatusesChanged: (values) =>
                  bloc.add(VtmStatusesChanged(values)),
              modes: VtmMonitoringState.modeOptions,
              modeLabels: VtmMonitoringState.modeLabels,
              selectedMode: filters.modeOfProcurement,
              onModeChanged: (value) => bloc.add(VtmModeChanged(value)),
              divisions: state.divisionOptions,
              selectedDivision: filters.division,
              onDivisionChanged: (value) => bloc.add(VtmDivisionChanged(value)),
              endorsedDateFilter: filters.endorsedDateRange,
              onEndorsedDateChanged: (range) =>
                  bloc.add(VtmEndorsedDateChanged(range)),
              onFiltersReset: () => bloc.add(const VtmFiltersCleared()),
            ),
            SizedBox(height: spacing),
            attention,
            SizedBox(height: spacing),
            if (widget.fillHeight) Expanded(child: table) else table,
          ],
        );
      },
    );
  }
}
