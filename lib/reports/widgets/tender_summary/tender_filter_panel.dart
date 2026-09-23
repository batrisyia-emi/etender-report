// lib/reports/widgets/tender_summary/tender_filter_panel.dart
import 'package:flutter/material.dart';

import 'package:etender_reports/reports/widgets/shared/filter_fields.dart';

/// Filters for the tender/quotation summary report: organisational ownership,
/// procurement type, financial threshold and the date ranges.
class TenderFilterPanel extends StatelessWidget {
  const TenderFilterPanel({
    super.key,
    required this.searchController,
    required this.minimumValueController,
    required this.maximumValueController,
    required this.onSearchChanged,
    required this.onMinValueChanged,
    required this.onMaxValueChanged,
    required this.statuses,
    required this.selectedStatuses,
    required this.onStatusesChanged,
    required this.categories,
    required this.selectedCategories,
    required this.onCategoriesChanged,
    required this.procurementModes,
    required this.selectedProcurementModes,
    required this.onProcurementModesChanged,
    required this.envelopeTypes,
    required this.selectedEnvelopeType,
    required this.onEnvelopeTypeChanged,
    required this.itemTypes,
    required this.selectedItemType,
    required this.onItemTypeChanged,
    required this.divisions,
    required this.selectedDivisions,
    required this.onDivisionsChanged,
    required this.departments,
    required this.selectedDepartments,
    required this.onDepartmentsChanged,
    required this.units,
    required this.selectedUnits,
    required this.onUnitsChanged,
    required this.endorsedDateFilter,
    required this.onEndorsedDateChanged,
    required this.closingDateFilter,
    required this.onClosingDateChanged,
    required this.onFiltersReset,
  });

  final TextEditingController searchController;
  final TextEditingController minimumValueController;
  final TextEditingController maximumValueController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onMinValueChanged;
  final ValueChanged<String> onMaxValueChanged;

  final List<String> statuses;
  final Set<String> selectedStatuses;
  final ValueChanged<Set<String>> onStatusesChanged;

  final List<String> categories;
  final Set<String> selectedCategories;
  final ValueChanged<Set<String>> onCategoriesChanged;

  final List<String> procurementModes;
  final Set<String> selectedProcurementModes;
  final ValueChanged<Set<String>> onProcurementModesChanged;

  final List<String> envelopeTypes;
  final String? selectedEnvelopeType;
  final ValueChanged<String?> onEnvelopeTypeChanged;

  final List<String> itemTypes;
  final String? selectedItemType;
  final ValueChanged<String?> onItemTypeChanged;

  final List<String> divisions;
  final Set<String> selectedDivisions;
  final ValueChanged<Set<String>> onDivisionsChanged;

  final List<String> departments;
  final Set<String> selectedDepartments;
  final ValueChanged<Set<String>> onDepartmentsChanged;

  final List<String> units;
  final Set<String> selectedUnits;
  final ValueChanged<Set<String>> onUnitsChanged;

  final DateTimeRange? endorsedDateFilter;
  final ValueChanged<DateTimeRange?> onEndorsedDateChanged;
  final DateTimeRange? closingDateFilter;
  final ValueChanged<DateTimeRange?> onClosingDateChanged;

  final VoidCallback onFiltersReset;

  /// Widths at which each group of fields fits on a single row. The rows
  /// read in one order across every report: find it, then where it sits,
  /// then how it is run, then when and how much.
  static const double _findRowBreakpoint = 900;
  static const double _orgRowBreakpoint = 780;
  static const double _procurementRowBreakpoint = 780;
  static const double _valueRowBreakpoint = 880;

  static const Icon _statusIcon = Icon(Icons.flag_outlined, size: 18);
  static const Icon _categoryIcon = Icon(Icons.category_outlined, size: 18);
  static const Icon _modeIcon = Icon(Icons.gavel_outlined, size: 18);
  static const Icon _envelopeIcon = Icon(Icons.mail_outline, size: 18);
  static const Icon _itemTypeIcon = Icon(Icons.inventory_2_outlined, size: 18);
  static const Icon _divisionIcon = Icon(Icons.account_tree_outlined, size: 18);
  static const Icon _departmentIcon = Icon(Icons.apartment_outlined, size: 18);
  static const Icon _unitIcon = Icon(Icons.groups_outlined, size: 18);
  static const Icon _minValueIcon = Icon(Icons.arrow_downward, size: 18);
  static const Icon _maxValueIcon = Icon(Icons.arrow_upward, size: 18);
  static const Icon _endorsedDateIcon = Icon(Icons.event_available, size: 18);
  static const Icon _closingDateIcon = Icon(Icons.event_busy, size: 18);

  @override
  Widget build(BuildContext context) {
    return FilterPanelShell(
      onReset: onFiltersReset,
      builder: (context, layout) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Find it: free text, where it has reached, what kind it is.
            FilterFieldRow(
              useRow: layout.availableWidth >= _findRowBreakpoint,
              layout: layout,
              // Search spans two cells, so this row fills exactly four:
              // nothing is left to orphan onto the next line.
              flexes: const [2, 1, 1],
              gridSpans: const [2, 1, 1],
              fieldBuilders: [
                (width) => FilterSearchField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  width: width,
                ),
                (width) => FilterMultiSelectField(
                  icon: _statusIcon,
                  label: 'Status',
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
              ],
            ),
            const SizedBox(height: kFilterRowSpacing),

            // Where it sits in the organisation.
            FilterFieldRow(
              useRow: layout.availableWidth >= _orgRowBreakpoint,
              layout: layout,
              fieldBuilders: [
                (width) => FilterMultiSelectField(
                  icon: _divisionIcon,
                  label: 'Divisions',
                  placeholder: 'All divisions',
                  options: divisions,
                  selectedValues: selectedDivisions,
                  onChanged: onDivisionsChanged,
                  width: width,
                ),
                (width) => FilterMultiSelectField(
                  icon: _departmentIcon,
                  label: 'Departments',
                  placeholder: 'All departments',
                  options: departments,
                  selectedValues: selectedDepartments,
                  onChanged: onDepartmentsChanged,
                  width: width,
                ),
                (width) => FilterMultiSelectField(
                  icon: _unitIcon,
                  label: 'Units',
                  placeholder: 'All units',
                  options: units,
                  selectedValues: selectedUnits,
                  onChanged: onUnitsChanged,
                  width: width,
                ),
              ],
            ),
            const SizedBox(height: kFilterRowSpacing),

            // How it is run. The three are independent of each other: any
            // mode can be one envelope or two, stock or non-stock.
            FilterFieldRow(
              useRow: layout.availableWidth >= _procurementRowBreakpoint,
              layout: layout,
              fieldBuilders: [
                (width) => FilterMultiSelectField(
                  icon: _modeIcon,
                  label: 'Mode of Procurement',
                  placeholder: 'All modes',
                  options: procurementModes,
                  selectedValues: selectedProcurementModes,
                  onChanged: onProcurementModesChanged,
                  width: width,
                ),
                (width) => FilterDropdownField(
                  icon: _envelopeIcon,
                  label: 'Envelope',
                  placeholder: 'All envelopes',
                  options: envelopeTypes,
                  value: selectedEnvelopeType,
                  onChanged: onEnvelopeTypeChanged,
                  width: width,
                ),
                (width) => FilterDropdownField(
                  icon: _itemTypeIcon,
                  label: 'Item Type',
                  placeholder: 'All item types',
                  options: itemTypes,
                  value: selectedItemType,
                  onChanged: onItemTypeChanged,
                  width: width,
                ),
              ],
            ),
            const SizedBox(height: kFilterRowSpacing),

            // When and how much. The dates still read widest, but the value
            // fields name the figure they bound, so they no longer get the
            // smallest share.
            FilterFieldRow(
              useRow: layout.availableWidth >= _valueRowBreakpoint,
              layout: layout,
              flexes: const [2, 2, 3, 3],
              fieldBuilders: [
                (width) => FilterNumberField(
                  controller: minimumValueController,
                  icon: _minValueIcon,
                  label: 'From Estimated Value',
                  placeholder: 'No minimum',
                  onChanged: onMinValueChanged,
                  width: width,
                ),
                (width) => FilterNumberField(
                  controller: maximumValueController,
                  icon: _maxValueIcon,
                  label: 'To Estimated Value (RM)',
                  placeholder: 'No maximum',
                  onChanged: onMaxValueChanged,
                  width: width,
                ),
                (width) => FilterDateField(
                  icon: _endorsedDateIcon,
                  label: 'RFC Endorsed Date',
                  selectedRange: endorsedDateFilter,
                  onChanged: onEndorsedDateChanged,
                  width: width,
                ),
                (width) => FilterDateField(
                  icon: _closingDateIcon,
                  label: 'Tender Closing Date',
                  selectedRange: closingDateFilter,
                  onChanged: onClosingDateChanged,
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
