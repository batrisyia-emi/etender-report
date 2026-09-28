// lib/reports/views/tender_security_view.dart
//
// Tender Security Report, per Blueprint v1.3 chapter 9.1 and process 3.5
// step 1.12.
//
// The only report with editable cells. An edit is applied to the bloc's own
// copy so the control responds, and sent to `ReportActions` in the same
// gesture — see _applyEdit.
import 'package:etender_reports/data/actions/report_actions.dart';
import 'package:etender_reports/reports/bloc/tender_security/tender_security_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// The bloc file re-exports its event, state and ReportStatus.
import 'package:etender_reports/reports/models/records/tender_security_record.dart';
import 'package:etender_reports/reports/models/tender_security_filters.dart';
import 'package:etender_reports/reports/views/cards/tender_security_kpi_cards.dart';
import 'package:etender_reports/reports/widgets/shared/collapsible_section.dart';
import 'package:etender_reports/reports/widgets/shared/kpi_card.dart';
import 'package:etender_reports/reports/widgets/shared/report_status_panel.dart';
import 'package:etender_reports/reports/widgets/tender_security/tender_security_filter_panel.dart';
import 'package:etender_reports/reports/widgets/tender_security/tender_security_table.dart';
import 'package:etender_reports/shared/utils/run_report_action.dart';

class TenderSecurityReportView extends StatefulWidget {
  const TenderSecurityReportView({
    super.key,
    required this.sectionSpacing,
    required this.fillHeight,
  });

  final double sectionSpacing;

  /// When true the filters stay put and the rest of the page scrolls.
  final bool fillHeight;

  @override
  State<TenderSecurityReportView> createState() =>
      _TenderSecurityReportViewState();
}

class _TenderSecurityReportViewState extends State<TenderSecurityReportView> {
  late final TextEditingController _tenderNoController;
  late final TextEditingController _vendorController;

  @override
  void initState() {
    super.initState();
    final filters = context.read<TenderSecurityBloc>().state.filters;
    _tenderNoController = TextEditingController(text: filters.tenderNoQuery);
    _vendorController = TextEditingController(text: filters.vendorQuery);
  }

  @override
  void dispose() {
    _tenderNoController.dispose();
    _vendorController.dispose();
    super.dispose();
  }

  /// Keeps the text fields in step when the filters change from elsewhere,
  /// e.g. the Reset button.
  void _syncControllers(TenderSecurityFilters filters) {
    if (_tenderNoController.text != filters.tenderNoQuery) {
      _tenderNoController.text = filters.tenderNoQuery;
    }
    if (_vendorController.text != filters.vendorQuery) {
      _vendorController.text = filters.vendorQuery;
    }
  }

  /// One gesture, two destinations.
  ///
  /// The bloc gets the change so the control the user touched responds, and
  /// `ReportActions` gets it so a real backend can persist it. Until that
  /// is implemented the action throws and `runReportAction` says the change
  /// is on screen only — which is true, and better than a tick box that
  /// silently forgets.
  void _applyEdit(TenderSecurityRecord record, TenderSecurityEdit edit) {
    context.read<TenderSecurityBloc>().add(
      TenderSecurityFieldEdited(
        uniqueNo: record.uniqueNo,
        originalCopyReceived: edit.originalCopyReceived,
        submittedToRevenueAssuranceDate: edit.submittedToRevenueAssuranceDate,
        clearSubmittedToRevenueAssuranceDate:
            edit.clearSubmittedToRevenueAssuranceDate,
        unsuccessfulTenderer: edit.unsuccessfulTenderer,
        clearUnsuccessfulTenderer: edit.clearUnsuccessfulTenderer,
        refundDate: edit.refundDate,
        clearRefundDate: edit.clearRefundDate,
      ),
    );

    runReportAction(
      context,
      () => context.read<ReportActions>().updateTenderSecurity(
        record.uniqueNo,
        TenderSecurityPatch(
          originalCopyReceived: edit.originalCopyReceived,
          submittedToRevenueAssuranceDate: edit.submittedToRevenueAssuranceDate,
          clearSubmittedToRevenueAssuranceDate:
              edit.clearSubmittedToRevenueAssuranceDate,
          unsuccessfulTenderer: edit.unsuccessfulTenderer,
          clearUnsuccessfulTenderer: edit.clearUnsuccessfulTenderer,
          refundDate: edit.refundDate,
          clearRefundDate: edit.clearRefundDate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = widget.sectionSpacing;

    return BlocConsumer<TenderSecurityBloc, TenderSecurityState>(
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

        final bloc = context.read<TenderSecurityBloc>();
        final filters = state.filters;
        final records = state.filteredRecords;

        final overview = CollapsibleSection(
          title: 'Overview',
          collapsedSummary: '5 metrics hidden',
          child: KpiCardRow(
            spacing: spacing,
            // The cards are the spec's named views: tapping one switches
            // the table to it, or back to All when it is already showing.
            cards: buildTenderSecurityKpiCards(
              records: records,
              onViewTap: (view) => bloc.add(TenderSecurityViewToggled(view)),
            ),
          ),
        );

        final table = TenderSecurityTable(
          records: records,
          onEdit: _applyEdit,
          onOpenScanCopy: (url) => runReportAction(
            context,
            () => context.read<ReportActions>().openTenderSecurityScanCopy(url),
          ),
        );

        final body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            overview,
            SizedBox(height: spacing),
            table,
          ],
        );

        // The filters stay put at the top — still collapsible, just not
        // scrolled away — and the rest scrolls under them, as on the TOC
        // report. When the window is too short, `fillHeight` is false and
        // the shell is already scrolling the whole page.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: widget.fillHeight ? MainAxisSize.max : MainAxisSize.min,
          children: [
            TenderSecurityFilterPanel(
              tenderNoController: _tenderNoController,
              onTenderNoChanged: (value) =>
                  bloc.add(TenderSecurityTenderNoQueryChanged(value)),
              vendorController: _vendorController,
              onVendorChanged: (value) =>
                  bloc.add(TenderSecurityVendorQueryChanged(value)),
              paymentTypes: TenderSecurityState.paymentTypeOptions,
              paymentTypeLabels: TenderSecurityFilters.paymentTypeLabels,
              selectedPaymentType: filters.paymentType,
              onPaymentTypeChanged: (value) =>
                  bloc.add(TenderSecurityPaymentTypeChanged(value)),
              views: TenderSecurityState.viewOptions,
              selectedView: filters.view.label,
              onViewChanged: (label) => bloc.add(
                TenderSecurityViewChanged(TenderSecurityView.fromLabel(label)),
              ),
              onFiltersReset: () =>
                  bloc.add(const TenderSecurityFiltersCleared()),
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
