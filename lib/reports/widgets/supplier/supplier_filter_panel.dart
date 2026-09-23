// lib/reports/widgets/supplier/supplier_filter_panel.dart
import 'package:etender_reports/reports/models/open_to.dart';
import 'package:etender_reports/reports/widgets/shared/filter_fields.dart';
import 'package:flutter/material.dart';

/// Filters for the supplier report: which tender,
/// then how far its request got, then the dates that bound it.
class SupplierFilterPanel extends StatelessWidget {
  const SupplierFilterPanel({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.statuses,
    required this.selectedStatuses,
    required this.onStatusesChanged,
    required this.categories,
    required this.selectedCategories,
    required this.onCategoriesChanged,
    required this.divisions,
    required this.selectedDivisions,
    required this.onDivisionsChanged,
    required this.openToOptions,
    required this.selectedOpenTo,
    required this.onOpenToChanged,
    required this.requestDateFilter,
    required this.onRequestDateChanged,
    required this.closingDateFilter,
    required this.onClosingDateChanged,
    required this.pendingPaymentOnly,
    required this.onPendingPaymentOnlyChanged,
    required this.onFiltersReset,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  final List<String> statuses;
  final Set<String> selectedStatuses;
  final ValueChanged<Set<String>> onStatusesChanged;

  final List<String> categories;
  final Set<String> selectedCategories;
  final ValueChanged<Set<String>> onCategoriesChanged;

  final List<String> divisions;
  final Set<String> selectedDivisions;
  final ValueChanged<Set<String>> onDivisionsChanged;

  final List<String> openToOptions;
  final String? selectedOpenTo;
  final ValueChanged<String?> onOpenToChanged;

  final DateTimeRange? requestDateFilter;
  final ValueChanged<DateTimeRange?> onRequestDateChanged;

  final DateTimeRange? closingDateFilter;
  final ValueChanged<DateTimeRange?> onClosingDateChanged;

  final bool pendingPaymentOnly;
  final ValueChanged<bool> onPendingPaymentOnlyChanged;

  final VoidCallback onFiltersReset;

  /// Width at which search plus three fields fit on one row.
  static const double _rowBreakpoint = 960;
  static const Icon _statusIcon = Icon(Icons.flag_outlined, size: 18);
  static const Icon _categoryIcon = Icon(Icons.category_outlined, size: 18);
  static const Icon _divisionIcon = Icon(Icons.account_tree_outlined, size: 18);
  static const Icon _openToIcon = Icon(Icons.verified_outlined, size: 18);
  static const Icon _requestDateIcon = Icon(Icons.calendar_today, size: 18);
  static const Icon _closingDateIcon = Icon(
    Icons.event_busy_outlined,
    size: 18,
  );

  @override
  Widget build(BuildContext context) {
    return FilterPanelShell(
      subtitle: 'Refine your records',
      onReset: onFiltersReset,
      builder: (context, layout) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Find it: free text over the tenders this supplier took part in.
            FilterFieldRow(
              useRow: layout.availableWidth >= _rowBreakpoint,
              layout: layout,
              // The only field in its row, so it takes all four cells.
              flexes: const [4],
              gridSpans: const [4],
              fieldBuilders: [
                (width) => FilterSearchField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  label: 'Search tender',
                  width: width,
                ),
              ],
            ),
            const SizedBox(height: kFilterRowSpacing),

            // How far it got, and what kind of tender it is against.
            FilterFieldRow(
              useRow: layout.availableWidth >= _rowBreakpoint,
              layout: layout,
              fieldBuilders: [
                (width) => FilterMultiSelectField(
                  icon: _statusIcon,
                  label: 'Current Status',
                  placeholder: 'All statuses',
                  options: statuses,
                  selectedValues: selectedStatuses,
                  onChanged: onStatusesChanged,
                  width: width,
                ),
                (width) => FilterMultiSelectField(
                  icon: _categoryIcon,
                  label: 'Tender Category',
                  placeholder: 'All categories',
                  options: categories,
                  selectedValues: selectedCategories,
                  onChanged: onCategoriesChanged,
                  width: width,
                ),
                (width) => FilterMultiSelectField(
                  icon: _divisionIcon,
                  label: 'Divisions',
                  placeholder: 'All divisions',
                  options: divisions,
                  selectedValues: selectedDivisions,
                  onChanged: onDivisionsChanged,
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

            // When it was asked for, when it closes, and the one shortcut
            // that matters day to day.
            Row(
              children: [
                SizedBox(
                  width: layout.span(1),
                  child: FilterDateField(
                    icon: _requestDateIcon,
                    label: 'Request Date',
                    selectedRange: requestDateFilter,
                    onChanged: onRequestDateChanged,
                  ),
                ),
                const SizedBox(width: kFilterFieldSpacing),
                SizedBox(
                  width: layout.span(1),
                  child: FilterDateField(
                    icon: _closingDateIcon,
                    label: 'Tender Closing Date',
                    selectedRange: closingDateFilter,
                    onChanged: onClosingDateChanged,
                  ),
                ),
                const SizedBox(width: kFilterFieldSpacing),
                // The fee shortcut: rows that owe money right now.
                Flexible(
                  child: FilterChip(
                    avatar: Icon(
                      Icons.payments_outlined,
                      size: 18,
                      color: pendingPaymentOnly
                          ? Colors.white
                          : kFilterAccentColor,
                    ),
                    label: const Text('Pending payment only'),
                    selected: pendingPaymentOnly,
                    showCheckmark: false,
                    onSelected: onPendingPaymentOnlyChanged,
                    backgroundColor: kFilterFillColor,
                    selectedColor: kFilterAccentColor,
                    labelStyle: TextStyle(
                      color: pendingPaymentOnly
                          ? Colors.white
                          : kFilterValueColor,
                      fontWeight: FontWeight.w500,
                    ),
                    side: const BorderSide(color: kFilterBorderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
