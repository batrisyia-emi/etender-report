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
    required this.documentTypes,
    required this.selectedDocumentType,
    required this.onDocumentTypeChanged,
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

  final List<String> documentTypes;
  final String? selectedDocumentType;
  final ValueChanged<String?> onDocumentTypeChanged;

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

  /// Width at which a group of fields fits on a single row.
  ///
  /// One number per panel, not one per row. With separate breakpoints the
  /// rows flipped to the reflowing grid at different widths, so a window
  /// between them showed some rows as rows and others as a grid — which is
  /// most of what made the panels look untidy.
  ///
  /// 960, like the other four panels.
  ///
  /// It was briefly 1080, on the reasoning that a fifth of 960 is a narrow
  /// 185px. That was the wrong trade: above the breakpoint the three rows
  /// render as three rows, and below it the grid caps at four columns, so
  /// each five-cell row wraps as four plus one and the panel becomes six
  /// lines instead of three. A snug field beats a split row.
  static const double _rowBreakpoint = 960;

  static const Icon _statusIcon = Icon(Icons.flag_outlined, size: 18);
  static const Icon _categoryIcon = Icon(Icons.category_outlined, size: 18);
  static const Icon _modeIcon = Icon(Icons.gavel_outlined, size: 18);
  static const Icon _documentTypeIcon = Icon(
    Icons.description_outlined,
    size: 18,
  );
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
            // Three rows of five cells. Fourteen filters will not fit three
            // rows of four, so this panel alone runs on a five-cell rhythm:
            // search spans two, everything else takes one, and each row
            // comes to five. Every edge lands on a fifth, and row one's
            // edges are a subset of the other two's.
            //
            // The groups are kept whole - division/department/unit, the two
            // value bounds, the two dates - so no pair is split across a
            // row break.
            //
            // Find it: free text, where it has reached, what kind of
            // document, and what is being bought.
            FilterFieldRow(
              useRow: layout.availableWidth >= _rowBreakpoint,
              layout: layout,
              flexes: const [2, 1, 1, 1],
              gridSpans: const [2, 1, 1, 1],
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
                (width) => FilterDropdownField(
                  icon: _documentTypeIcon,
                  label: 'Document Type',
                  placeholder: 'Tenders and quotations',
                  options: documentTypes,
                  value: selectedDocumentType,
                  onChanged: onDocumentTypeChanged,
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

            // Where it sits in the organisation, and what it is worth.
            FilterFieldRow(
              useRow: layout.availableWidth >= _rowBreakpoint,
              layout: layout,
              flexes: const [1, 1, 1, 1, 1],
              gridSpans: const [1, 1, 1, 1, 1],
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
              ],
            ),
            const SizedBox(height: kFilterRowSpacing),

            // How it is run, and when it happened.
            FilterFieldRow(
              useRow: layout.availableWidth >= _rowBreakpoint,
              layout: layout,
              flexes: const [1, 1, 1, 1, 1],
              gridSpans: const [1, 1, 1, 1, 1],
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
