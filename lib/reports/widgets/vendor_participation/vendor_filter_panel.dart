// lib/reports/widgets/vendor_filter_panel.dart
import 'package:etender_reports/reports/models/open_to.dart';
import 'package:etender_reports/reports/widgets/shared/filter_fields.dart';
import 'package:flutter/material.dart';

/// Filters for the vendor participation report, matching the report spec:
/// tender reference, vendor classification, credentials, and the
/// invitation -> document purchase -> submission funnel. All single-select.
class VendorFilterPanel extends StatelessWidget {
  const VendorFilterPanel({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.tenderIds,
    required this.selectedTenderIds,
    required this.onTenderIdsChanged,
    required this.openToOptions,
    required this.selectedOpenTo,
    required this.onOpenToChanged,
    required this.certificationTypes,
    required this.selectedCertificationTypes,
    required this.onCertificationTypesChanged,
    required this.invitationStatuses,
    required this.selectedInvitationStatus,
    required this.onInvitationStatusChanged,
    required this.purchaseOptions,
    required this.selectedPurchaseOption,
    required this.onPurchaseOptionChanged,
    required this.participationStatuses,
    required this.selectedParticipationStatus,
    required this.onParticipationStatusChanged,
    required this.submissionStatuses,
    required this.selectedSubmissionStatuses,
    required this.onSubmissionStatusesChanged,
    required this.submissionDateFilter,
    required this.onSubmissionDateChanged,
    required this.onFiltersReset,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  final List<String> tenderIds;
  final Set<String> selectedTenderIds;
  final ValueChanged<Set<String>> onTenderIdsChanged;

  final List<String> openToOptions;
  final String? selectedOpenTo;
  final ValueChanged<String?> onOpenToChanged;

  final List<String> certificationTypes;
  final Set<String> selectedCertificationTypes;
  final ValueChanged<Set<String>> onCertificationTypesChanged;

  final List<String> invitationStatuses;
  final String? selectedInvitationStatus;
  final ValueChanged<String?> onInvitationStatusChanged;

  final List<String> purchaseOptions;
  final String? selectedPurchaseOption;
  final ValueChanged<String?> onPurchaseOptionChanged;

  final List<String> participationStatuses;
  final String? selectedParticipationStatus;
  final ValueChanged<String?> onParticipationStatusChanged;

  final List<String> submissionStatuses;
  final Set<String> selectedSubmissionStatuses;
  final ValueChanged<Set<String>> onSubmissionStatusesChanged;

  final DateTimeRange? submissionDateFilter;
  final ValueChanged<DateTimeRange?> onSubmissionDateChanged;

  final VoidCallback onFiltersReset;

  /// Widths at which each row's fields fit side by side. The rows follow
  /// the vendor's journey: find them, then whether they were invited and
  /// took it up, then whether a bid actually arrived.
  static const double _searchRowBreakpoint = 960;
  static const double _invitationRowBreakpoint = 780;
  static const double _submissionRowBreakpoint = 880;
  static const Icon _tenderIcon = Icon(Icons.article_outlined, size: 18);
  static const Icon _openToIcon = Icon(Icons.diversity_3_outlined, size: 18);
  static const Icon _certificationIcon = Icon(
    Icons.verified_outlined,
    size: 18,
  );
  static const Icon _invitationIcon = Icon(
    Icons.mark_email_read_outlined,
    size: 18,
  );
  static const Icon _purchaseIcon = Icon(
    Icons.shopping_cart_outlined,
    size: 18,
  );
  static const Icon _participationIcon = Icon(
    Icons.how_to_reg_outlined,
    size: 18,
  );
  static const Icon _submissionIcon = Icon(Icons.inbox_outlined, size: 18);
  static const Icon _submissionDateIcon = Icon(Icons.schedule, size: 18);

  @override
  Widget build(BuildContext context) {
    return FilterPanelShell(
      subtitle: 'Refine vendor participation',
      onReset: onFiltersReset,
      builder: (context, layout) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Find them: free text, which tender, what they are certified for.
            FilterFieldRow(
              useRow: layout.availableWidth >= _searchRowBreakpoint,
              layout: layout,
              flexes: const [2, 1, 1],
              gridSpans: const [2, 1, 1],
              fieldBuilders: [
                (width) => FilterSearchField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  label: 'Search vendor or tender',
                  width: width,
                ),
                (width) => FilterMultiSelectField(
                  icon: _tenderIcon,
                  label: 'Tender/Quotation Number',
                  placeholder: 'All tenders',
                  options: tenderIds,
                  selectedValues: selectedTenderIds,
                  onChanged: onTenderIdsChanged,
                  width: width,
                ),
                (width) => FilterMultiSelectField(
                  icon: _certificationIcon,
                  label: 'Vendor Certification Type',
                  placeholder: 'All certificates',
                  options: certificationTypes,
                  selectedValues: selectedCertificationTypes,
                  onChanged: onCertificationTypesChanged,
                  width: width,
                ),
              ],
            ),
            const SizedBox(height: kFilterRowSpacing),

            // Who could bid, and whether they took it up.
            FilterFieldRow(
              useRow: layout.availableWidth >= _invitationRowBreakpoint,
              layout: layout,
              fieldBuilders: [
                (width) => FilterDropdownField(
                  icon: _openToIcon,
                  label: 'Open To',
                  placeholder: 'Any eligibility',
                  options: openToOptions,
                  // Short text in the closed field, the contract value rule
                  // underneath each option in the open menu.
                  optionLabels: OpenTo.labels,
                  optionSubtitles: OpenTo.thresholds,
                  value: selectedOpenTo,
                  onChanged: onOpenToChanged,
                  width: width,
                ),
                (width) => FilterDropdownField(
                  icon: _invitationIcon,
                  label: 'Invitation Status',
                  placeholder: 'All invitations',
                  options: invitationStatuses,
                  value: selectedInvitationStatus,
                  onChanged: onInvitationStatusChanged,
                  width: width,
                ),
                (width) => FilterDropdownField(
                  icon: _participationIcon,
                  label: 'Participation',
                  placeholder: 'All vendors',
                  options: participationStatuses,
                  value: selectedParticipationStatus,
                  onChanged: onParticipationStatusChanged,
                  width: width,
                ),
              ],
            ),
            const SizedBox(height: kFilterRowSpacing),

            // Whether a bid arrived, and when.
            FilterFieldRow(
              useRow: layout.availableWidth >= _submissionRowBreakpoint,
              layout: layout,
              flexes: const [1, 1, 2],
              fieldBuilders: [
                (width) => FilterDropdownField(
                  icon: _purchaseIcon,
                  label: 'Document Purchased',
                  placeholder: 'Any',
                  options: purchaseOptions,
                  value: selectedPurchaseOption,
                  onChanged: onPurchaseOptionChanged,
                  width: width,
                ),
                (width) => FilterMultiSelectField(
                  icon: _submissionIcon,
                  label: 'Submission Status',
                  placeholder: 'All submissions',
                  options: submissionStatuses,
                  selectedValues: selectedSubmissionStatuses,
                  onChanged: onSubmissionStatusesChanged,
                  width: width,
                ),
                (width) => FilterDateField(
                  icon: _submissionDateIcon,
                  label: 'Submission Date',
                  selectedRange: submissionDateFilter,
                  onChanged: onSubmissionDateChanged,
                  width: width,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
