// lib/reports/views/vendor_participation_view.dart
import 'package:etender_reports/reports/bloc/vendor_participation/vendor_participation_bloc.dart';
import 'package:etender_reports/reports/models/filters/report_criteria.dart';
// The bloc file re-exports its event, state and ReportStatus.
import 'package:etender_reports/reports/models/filters/report_filters.dart';
import 'package:etender_reports/reports/report_type.dart';
import 'package:etender_reports/reports/widgets/shared/report_header.dart';
import 'package:etender_reports/reports/widgets/shared/report_status_panel.dart';
import 'package:etender_reports/reports/widgets/shared/report_timeline_filter.dart';
import 'package:etender_reports/reports/widgets/vendor_participation/vendor_filter_panel.dart';
import 'package:etender_reports/reports/widgets/vendor_participation/vendor_participation_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class VendorParticipationView extends StatefulWidget {
  const VendorParticipationView({
    super.key,
    required this.sectionSpacing,
    required this.fillHeight,
  });

  final double sectionSpacing;

  /// When true the cards and filters stay put and only the table scrolls.
  final bool fillHeight;

  @override
  State<VendorParticipationView> createState() =>
      _VendorParticipationViewState();
}

class _VendorParticipationViewState extends State<VendorParticipationView> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final filters = context.read<VendorParticipationBloc>().state.filters;
    _searchController = TextEditingController(text: filters.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _syncControllers(VendorFilters filters) {
    if (_searchController.text != filters.searchQuery) {
      _searchController.text = filters.searchQuery;
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = widget.sectionSpacing;

    return BlocConsumer<VendorParticipationBloc, VendorParticipationState>(
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

        final bloc = context.read<VendorParticipationBloc>();
        final filters = state.filters;
        final records = state.filteredRecords;

        final table = VendorParticipationTable(
          records: records,
          fillHeight: widget.fillHeight,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: widget.fillHeight ? MainAxisSize.max : MainAxisSize.min,
          children: [
            ReportHeader(
              title: ReportType.vendorParticipation.pageTitle,
              criteria: filters.describe(),
              shownCount: records.length,
              totalCount: state.records.length,
              unit: 'invitations',
            ),
            SizedBox(height: spacing),
            ReportTimelineFilter(
              label: 'Submission date',
              selectedRange: filters.submissionDateRange,
              onChanged: (range) =>
                  bloc.add(VendorSubmissionDateChanged(range)),
            ),
            SizedBox(height: spacing),
            VendorFilterPanel(
              searchController: _searchController,
              onSearchChanged: (value) => bloc.add(VendorSearchChanged(value)),
              // Appendix A 8.1, the tender's eligibility rule. Distinct
              // from participationStatus below, which is whether the vendor
              // took the invitation up.
              openToOptions: state.openToOptions,
              selectedOpenTo: filters.openTo,
              onOpenToChanged: (value) =>
                  bloc.add(VendorParticipationTypeChanged(value)),
              certificationTypes: VendorParticipationState.certificationTypes,
              selectedCertificationTypes: filters.certificationTypes,
              onCertificationTypesChanged: (values) =>
                  bloc.add(VendorCertificationTypesChanged(values)),
              invitationStatuses: VendorParticipationState.invitationStatuses,
              selectedInvitationStatus: filters.invitationStatus,
              onInvitationStatusChanged: (value) =>
                  bloc.add(VendorInvitationStatusChanged(value)),
              purchaseOptions: VendorParticipationState.purchaseOptions,
              selectedPurchaseOption: filters.purchaseOption,
              onPurchaseOptionChanged: (value) =>
                  bloc.add(VendorPurchaseOptionChanged(value)),
              participationStatuses:
                  VendorParticipationState.participationStatuses,
              selectedParticipationStatus: filters.participationStatus,
              onParticipationStatusChanged: (value) =>
                  bloc.add(VendorParticipationStatusChanged(value)),
              submissionStatuses: VendorParticipationState.submissionStatuses,
              selectedSubmissionStatuses: filters.submissionStatuses,
              onSubmissionStatusesChanged: (values) =>
                  bloc.add(VendorSubmissionStatusesChanged(values)),
              submissionDateFilter: filters.submissionDateRange,
              onSubmissionDateChanged: (range) =>
                  bloc.add(VendorSubmissionDateChanged(range)),
              onFiltersReset: () => bloc.add(const VendorFiltersCleared()),
            ),
            SizedBox(height: spacing),
            if (widget.fillHeight) Expanded(child: table) else table,
          ],
        );
      },
    );
  }
}
