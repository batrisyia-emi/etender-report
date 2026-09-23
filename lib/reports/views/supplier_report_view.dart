// lib/reports/views/supplier_report_view.dart
import 'package:etender_reports/reports/bloc/supplier/supplier_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// The bloc file re-exports its event, state and ReportStatus.
import 'package:etender_reports/reports/models/report_filters.dart';
import 'package:etender_reports/reports/widgets/shared/collapsible_section.dart';
import 'package:etender_reports/reports/widgets/shared/kpi_card.dart';
import 'package:etender_reports/reports/widgets/shared/report_status_panel.dart';
import 'package:etender_reports/reports/widgets/supplier/supplier_filter_panel.dart';
import 'package:etender_reports/reports/widgets/supplier/supplier_report_table.dart';
import 'package:etender_reports/reports/views/cards/supplier_kpi_cards.dart';

class SupplierReportView extends StatefulWidget {
  const SupplierReportView({
    super.key,
    required this.sectionSpacing,
    required this.fillHeight,
  });

  final double sectionSpacing;

  /// When true the filters and overview stay put and only the table scrolls.
  final bool fillHeight;

  @override
  State<SupplierReportView> createState() => _SupplierReportViewState();
}

class _SupplierReportViewState extends State<SupplierReportView> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final filters = context.read<SupplierBloc>().state.filters;
    _searchController = TextEditingController(text: filters.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _syncControllers(SupplierFilters filters) {
    if (_searchController.text != filters.searchQuery) {
      _searchController.text = filters.searchQuery;
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = widget.sectionSpacing;

    return BlocConsumer<SupplierBloc, SupplierState>(
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

        final bloc = context.read<SupplierBloc>();
        final filters = state.filters;
        final records = state.filteredRecords;

        final table = SupplierReportTable(
          records: records,
          fillHeight: widget.fillHeight,
        );

        final overview = CollapsibleSection(
          title: 'Overview',
          collapsedSummary: '8 metrics hidden',
          child: KpiCardRow(
            spacing: spacing,
            cards: buildSupplierKpiCards(
              records: records,
              onStatusTap: (statuses) =>
                  bloc.add(SupplierStatusGroupToggled(statuses)),
              // Tapping Pending Payment narrows to the rows owing a fee.
              onPendingPaymentTap: () =>
                  bloc.add(const SupplierPendingPaymentOnlyToggled()),
            ),
          ),
        );

        // Filters first, then the overview of what they matched, then the
        // table.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: widget.fillHeight ? MainAxisSize.max : MainAxisSize.min,
          children: [
            SupplierFilterPanel(
              searchController: _searchController,
              onSearchChanged: (value) =>
                  bloc.add(SupplierSearchChanged(value)),
              statuses: SupplierState.lifecycleStatuses,
              selectedStatuses: filters.statuses,
              onStatusesChanged: (values) =>
                  bloc.add(SupplierStatusesChanged(values)),
              categories: state.categoryOptions,
              selectedCategories: filters.categories,
              onCategoriesChanged: (values) =>
                  bloc.add(SupplierCategoriesChanged(values)),
              divisions: state.divisionOptions,
              selectedDivisions: filters.divisions,
              onDivisionsChanged: (values) =>
                  bloc.add(SupplierDivisionsChanged(values)),
              openToOptions: state.openToOptions,
              selectedOpenTo: filters.openTo,
              onOpenToChanged: (value) =>
                  bloc.add(SupplierOpenToChanged(value)),
              requestDateFilter: filters.requestDateRange,
              onRequestDateChanged: (range) =>
                  bloc.add(SupplierRequestDateChanged(range)),
              closingDateFilter: filters.closingDateRange,
              onClosingDateChanged: (range) =>
                  bloc.add(SupplierClosingDateChanged(range)),
              pendingPaymentOnly: filters.pendingPaymentOnly,
              onPendingPaymentOnlyChanged: (value) =>
                  bloc.add(SupplierPendingPaymentOnlyChanged(value)),
              onFiltersReset: () => bloc.add(const SupplierFiltersCleared()),
            ),
            SizedBox(height: spacing),
            overview,
            SizedBox(height: spacing),
            if (widget.fillHeight) Expanded(child: table) else table,
          ],
        );
      },
    );
  }
}
