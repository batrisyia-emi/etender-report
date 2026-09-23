// lib/reports/views/tender_summary_view.dart
import 'package:etender_reports/reports/bloc/tender_summary/tender_summary_bloc.dart';
import 'package:etender_reports/reports/widgets/tender_summary/tender_filter_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// The bloc file re-exports its event, state and ReportStatus.
import 'package:etender_reports/reports/models/report_filters.dart';
import 'package:etender_reports/reports/widgets/shared/collapsible_section.dart';
import 'package:etender_reports/reports/widgets/shared/kpi_card.dart';
import 'package:etender_reports/reports/widgets/shared/report_status_panel.dart';
import 'package:etender_reports/reports/widgets/tender_summary/tender_data_table.dart';
import 'package:etender_reports/reports/views/cards/tender_kpi_cards.dart';

class TenderSummaryView extends StatefulWidget {
  const TenderSummaryView({
    super.key,
    required this.sectionSpacing,
    required this.fillHeight,
  });

  final double sectionSpacing;

  /// When true the filters and overview stay put and only the table scrolls.
  final bool fillHeight;

  @override
  State<TenderSummaryView> createState() => _TenderSummaryViewState();
}

class _TenderSummaryViewState extends State<TenderSummaryView> {
  late final TextEditingController _searchController;
  late final TextEditingController _minimumValueController;
  late final TextEditingController _maximumValueController;

  @override
  void initState() {
    super.initState();
    final filters = context.read<TenderSummaryBloc>().state.filters;
    _searchController = TextEditingController(text: filters.searchQuery);
    _minimumValueController = TextEditingController(
      text: filters.minimumValue?.toString() ?? '',
    );
    _maximumValueController = TextEditingController(
      text: filters.maximumValue?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minimumValueController.dispose();
    _maximumValueController.dispose();
    super.dispose();
  }

  /// Only writes when the text and the state actually disagree, so typing is
  /// never interrupted and the caret does not jump. This is what makes
  /// "Clear filters" empty the boxes.
  void _syncControllers(TenderFilters filters) {
    if (_searchController.text != filters.searchQuery) {
      _searchController.text = filters.searchQuery;
    }
    _syncNumberField(_minimumValueController, filters.minimumValue);
    _syncNumberField(_maximumValueController, filters.maximumValue);
  }

  void _syncNumberField(TextEditingController controller, double? value) {
    if (double.tryParse(controller.text) == value) return;
    controller.text = value?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final spacing = widget.sectionSpacing;

    return BlocConsumer<TenderSummaryBloc, TenderSummaryState>(
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

        final bloc = context.read<TenderSummaryBloc>();
        final filters = state.filters;
        final records = state.filteredRecords;
        final table = TenderDataTable(
          records: records,
          fillHeight: widget.fillHeight,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: widget.fillHeight ? MainAxisSize.max : MainAxisSize.min,
          children: [
            TenderFilterPanel(
              searchController: _searchController,
              minimumValueController: _minimumValueController,
              maximumValueController: _maximumValueController,
              onSearchChanged: (value) => bloc.add(TenderSearchChanged(value)),
              onMinValueChanged: (value) =>
                  bloc.add(TenderMinimumValueChanged(double.tryParse(value))),
              onMaxValueChanged: (value) =>
                  bloc.add(TenderMaximumValueChanged(double.tryParse(value))),
              statuses: state.statusOptions,
              selectedStatuses: filters.statuses,
              onStatusesChanged: (values) =>
                  bloc.add(TenderStatusesChanged(values)),
              categories: state.categoryOptions,
              selectedCategories: filters.categories,
              onCategoriesChanged: (values) =>
                  bloc.add(TenderCategoriesChanged(values)),
              procurementModes: state.procurementModeOptions,
              selectedProcurementModes: filters.procurementModes,
              onProcurementModesChanged: (values) =>
                  bloc.add(TenderProcurementModesChanged(values)),
              envelopeTypes: state.envelopeTypeOptions,
              selectedEnvelopeType: filters.envelopeType,
              onEnvelopeTypeChanged: (value) =>
                  bloc.add(TenderEnvelopeTypeChanged(value)),
              itemTypes: state.itemTypeOptions,
              selectedItemType: filters.itemType,
              onItemTypeChanged: (value) =>
                  bloc.add(TenderItemTypeChanged(value)),
              divisions: state.divisionOptions,
              selectedDivisions: filters.divisions,
              onDivisionsChanged: (values) =>
                  bloc.add(TenderDivisionsChanged(values)),
              departments: state.departmentOptions,
              selectedDepartments: filters.departments,
              onDepartmentsChanged: (values) =>
                  bloc.add(TenderDepartmentsChanged(values)),
              units: state.unitOptions,
              selectedUnits: filters.units,
              onUnitsChanged: (values) => bloc.add(TenderUnitsChanged(values)),
              endorsedDateFilter: filters.endorsedDateRange,
              onEndorsedDateChanged: (range) => bloc.add(
                TenderDateRangeChanged(TenderDateField.endorsed, range),
              ),
              closingDateFilter: filters.closingDateRange,
              onClosingDateChanged: (range) => bloc.add(
                TenderDateRangeChanged(TenderDateField.closing, range),
              ),
              onFiltersReset: () => bloc.add(const TenderFiltersCleared()),
            ),
            SizedBox(height: spacing),
            CollapsibleSection(
              title: 'Overview',
              collapsedSummary: '6 metrics hidden',
              child: KpiCardRow(
                spacing: spacing,
                cards: buildTenderKpiCards(
                  records: records,
                  onStatusTap: (statuses) =>
                      bloc.add(TenderStatusGroupToggled(statuses)),
                ),
              ),
            ),
            SizedBox(height: spacing),
            if (widget.fillHeight) Expanded(child: table) else table,
          ],
        );
      },
    );
  }
}
