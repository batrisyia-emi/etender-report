// lib/reports/views/toc_report_view.dart
//
// TOC Appointment & Tender Opening Status, per Blueprint v1.3 sections
// 3.6 / 4.5 / 8.3 / 8.4.
//
// Read by VTM staff before evaluation, which is why nothing on this page
// touches bid data. See the warning on [TocOpeningRecord].
import 'package:etender_reports/data/actions/report_actions.dart';
import 'package:etender_reports/reports/bloc/toc/toc_bloc.dart';
import 'package:etender_reports/reports/models/filters/report_criteria.dart';
// The bloc file re-exports its event, state and ReportStatus.
import 'package:etender_reports/reports/models/filters/toc_filters.dart';
import 'package:etender_reports/reports/models/metrics/toc_metrics.dart';
import 'package:etender_reports/reports/report_type.dart';
import 'package:etender_reports/reports/widgets/shared/collapsible_section.dart';
import 'package:etender_reports/reports/widgets/shared/report_header.dart';
import 'package:etender_reports/reports/widgets/shared/report_status_panel.dart';
import 'package:etender_reports/reports/widgets/shared/report_timeline_filter.dart';
import 'package:etender_reports/reports/widgets/toc/toc_exception_panel.dart';
import 'package:etender_reports/reports/widgets/toc/toc_filter_panel.dart';
import 'package:etender_reports/reports/widgets/toc/toc_report_table.dart';
import 'package:etender_reports/reports/widgets/toc/toc_workload_panel.dart';
import 'package:etender_reports/shared/utils/run_report_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TocReportView extends StatefulWidget {
  const TocReportView({
    super.key,
    required this.sectionSpacing,
    required this.fillHeight,
  });

  final double sectionSpacing;

  /// When true the filters and overview stay put and only the table scrolls.
  final bool fillHeight;

  @override
  State<TocReportView> createState() => _TocReportViewState();
}

class _TocReportViewState extends State<TocReportView> {
  late final TextEditingController _tenderNoController;
  late final TextEditingController _memberController;

  @override
  void initState() {
    super.initState();
    final filters = context.read<TocBloc>().state.filters;
    _tenderNoController = TextEditingController(text: filters.tenderNoQuery);
    _memberController = TextEditingController(text: filters.memberQuery);
  }

  @override
  void dispose() {
    _tenderNoController.dispose();
    _memberController.dispose();
    super.dispose();
  }

  /// Keeps the text fields in step when the filters change from elsewhere,
  /// e.g. the Reset button.
  void _syncControllers(TocFilters filters) {
    if (_tenderNoController.text != filters.tenderNoQuery) {
      _tenderNoController.text = filters.tenderNoQuery;
    }
    if (_memberController.text != filters.memberQuery) {
      _memberController.text = filters.memberQuery;
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = widget.sectionSpacing;

    return BlocConsumer<TocBloc, TocState>(
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

        final bloc = context.read<TocBloc>();
        final filters = state.filters;
        final records = state.filteredRecords;

        // fillHeight is deliberately not passed through. This page pins
        // only the filters; everything below them scrolls as one column, so
        // the table takes its own capped height rather than the page's.
        final table = TocReportTable(records: records);

        // Open by default: it is the panel worth acting on, and with the
        // body scrolling it no longer squeezes the table off the screen.
        final flags = tocExceptionFlags(records);
        final urgent = flags
            .where((flag) => flag.severity == TocFlagSeverity.high)
            .length;

        final exceptions = CollapsibleSection(
          title: 'Needs Attention',
          collapsedSummary: flags.isEmpty
              ? 'Nothing behind or unassigned'
              : '$urgent urgent, ${flags.length - urgent} to watch',
          icon: Icons.warning_amber_rounded,
          child: TocExceptionPanel(
            records: records,
            // The flag decides which remedy it needs; this only routes it.
            // runReportAction turns the "not wired up" throw into a notice
            // rather than letting it vanish into the console.
            onRemedy: (record, remedy) => runReportAction(context, () {
              final actions = context.read<ReportActions>();
              return switch (remedy) {
                TocRemedy.appointCommittee => actions.appointTocCommittee(
                  record.tenderNo,
                ),
                TocRemedy.startOpening => actions.startTocOpening(
                  record.tenderNo,
                ),
                TocRemedy.openRecord => actions.viewTocOpening(record.tenderNo),
                TocRemedy.fileAppendixP => actions.fileTocAppendixP(
                  record.tenderNo,
                ),
              };
            }),
            onView: (record) => runReportAction(
              context,
              () =>
                  context.read<ReportActions>().viewTocOpening(record.tenderNo),
            ),
          ),
        );

        // Reference rather than action, so this one stays folded.
        final workload = CollapsibleSection(
          title: 'Committee Workload',
          collapsedSummary: records.isEmpty
              ? 'Nobody appointed yet'
              : 'How many committees each officer sits on',
          icon: Icons.groups_outlined,
          initiallyExpanded: false,
          child: TocCommitteeWorkloadPanel(records: records),
        );

        // The filters stay put at the top - still collapsible, just not
        // scrolled away - and the rest scrolls under them. When the window
        // is too short for that, `fillHeight` is false and the shell is
        // already scrolling the whole page, so this must not nest a second
        // scroll view inside it.
        // Only the filters are pinned. The two panels and the table scroll
        // together: fixed above the table they left it about 370px on a
        // laptop window, which is barely a few rows.
        final body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            exceptions,
            SizedBox(height: spacing),
            workload,
            SizedBox(height: spacing),
            table,
          ],
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: widget.fillHeight ? MainAxisSize.max : MainAxisSize.min,
          children: [
            ReportHeader(
              title: ReportType.toc.pageTitle,
              criteria: filters.describe(),
              shownCount: records.length,
              totalCount: state.records.length,
              unit: 'openings',
            ),
            SizedBox(height: spacing),
            ReportTimelineFilter(
              label: 'Closing date',
              selectedRange: filters.closingDateRange,
              onChanged: (range) => bloc.add(TocClosingDateChanged(range)),
            ),
            SizedBox(height: spacing),
            TocFilterPanel(
              tenderNoController: _tenderNoController,
              onTenderNoChanged: (value) =>
                  bloc.add(TocTenderNoQueryChanged(value)),
              memberController: _memberController,
              onMemberChanged: (value) =>
                  bloc.add(TocMemberQueryChanged(value)),
              documentTypes: TocState.documentTypeOptions,
              selectedDocumentType: filters.documentType,
              onDocumentTypeChanged: (value) =>
                  bloc.add(TocDocumentTypeChanged(value)),
              statuses: TocState.statusOptions,
              selectedStatuses: filters.statuses,
              onStatusesChanged: (values) =>
                  bloc.add(TocStatusesChanged(values)),
              envelopeTypes: TocState.envelopeTypeOptions,
              selectedEnvelopeType: filters.envelopeType,
              onEnvelopeTypeChanged: (value) =>
                  bloc.add(TocEnvelopeTypeChanged(value)),
              closingDateFilter: filters.closingDateRange,
              onClosingDateChanged: (range) =>
                  bloc.add(TocClosingDateChanged(range)),
              onFiltersReset: () => bloc.add(const TocFiltersCleared()),
            ),
            SizedBox(height: spacing),
            if (widget.fillHeight)
              Expanded(child: SingleChildScrollView(child: body))
            else
              body,
          ],
        );
      },
    );
  }
}
