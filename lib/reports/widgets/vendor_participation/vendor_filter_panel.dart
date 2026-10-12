// lib/reports/widgets/vendor_filter_panel.dart
import 'package:etender_reports/reports/models/attributes/open_to.dart';
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
    required this.openToOptions,
    required this.selectedOpenTo,
    required this.onOpenToChanged,
    required this.certificationTypes,
    required this.selectedCertificationTypes,
    required this.onCertificationTypesChanged,
    required this.purchaseOptions,
    required this.selectedPurchaseOption,
    required this.onPurchaseOptionChanged,
    required this.respondStatuses,
    required this.selectedRespondStatus,
    required this.onRespondStatusChanged,
    required this.onFiltersReset,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  final List<String> openToOptions;
  final String? selectedOpenTo;
  final ValueChanged<String?> onOpenToChanged;

  final List<String> certificationTypes;
  final Set<String> selectedCertificationTypes;
  final ValueChanged<Set<String>> onCertificationTypesChanged;

  final List<String> purchaseOptions;
  final String? selectedPurchaseOption;
  final ValueChanged<String?> onPurchaseOptionChanged;

  final List<String> respondStatuses;
  final String? selectedRespondStatus;
  final ValueChanged<String?> onRespondStatusChanged;

  final VoidCallback onFiltersReset;

  /// Width at which a group of fields fits on a single row. 960 across
  /// every report's filter panel, so they all reflow together.
  ///
  /// The rows follow the vendor's journey: find them, then whether they
  /// were invited and took it up, then whether a bid actually arrived.
  static const double _rowBreakpoint = 960;

  static const Icon _openToIcon = Icon(Icons.diversity_3_outlined, size: 18);
  static const Icon _certificationIcon = Icon(
    Icons.verified_outlined,
    size: 18,
  );
  static const Icon _purchaseIcon = Icon(
    Icons.shopping_cart_outlined,
    size: 18,
  );
  static const Icon _submissionIcon = Icon(Icons.inbox_outlined, size: 18);

  @override
  Widget build(BuildContext context) {
    return FilterPanelShell(
      subtitle: 'Refine vendor participation',
      onReset: onFiltersReset,
      builder: (context, layout) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Two rows of four equal cells, so every edge falls at 25%, 50%
            // and 75%. Search takes one cell rather than the two it gets on
            // the wider panels - that is what lets these eight controls
            // close up into two rows instead of three.
            //
            // Row one is the vendor and the invitation: who they are, what
            // they are certified for, what they were eligible for, and
            // whether they were asked.
            //
            // There is no tender-number field: the search box already
            // matches a tender number, and a dropdown listing every number
            // in the data did the same job twice.
            FilterFieldRow(
              useRow: layout.availableWidth >= _rowBreakpoint,
              layout: layout,
              fieldBuilders: [
                (width) => FilterSearchField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  label: 'Search vendor or tender',
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
              ],
            ),
            const SizedBox(height: kFilterRowSpacing),

            // Row two is what they did with it: bought the documents,
            // responded, and when they asked.
            FilterFieldRow(
              useRow: layout.availableWidth >= _rowBreakpoint,
              layout: layout,
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
                (width) => FilterDropdownField(
                  icon: _submissionIcon,
                  label: 'Tender Respond Status',
                  placeholder: 'All respond statuses',
                  options: respondStatuses,
                  value: selectedRespondStatus,
                  onChanged: onRespondStatusChanged,
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
