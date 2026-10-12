// lib/reports/widgets/tender_summary/tender_filter_panel.dart
import 'package:etender_reports/reports/widgets/shared/filter_fields.dart';
import 'package:flutter/material.dart';

/// Filters for the tender/quotation summary report: what kind of document
/// it is, how it is run and who owns it, what it is worth, and the four
/// dates it passes through.
class TenderFilterPanel extends StatelessWidget {
  const TenderFilterPanel({
    super.key,
    required this.minimumValueController,
    required this.maximumValueController,
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
    required this.endorsedDateFilter,
    required this.onEndorsedDateChanged,
    required this.publishedDateFilter,
    required this.onPublishedDateChanged,
    required this.openingDateFilter,
    required this.onOpeningDateChanged,
    required this.closingDateFilter,
    required this.onClosingDateChanged,
    required this.onFiltersReset,
  });

  final TextEditingController minimumValueController;
  final TextEditingController maximumValueController;
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

  final DateTimeRange? endorsedDateFilter;

  /// The record carries this as floatingDate; everything people see calls
  /// it Published.
  final DateTimeRange? publishedDateFilter;
  final ValueChanged<DateTimeRange?> onPublishedDateChanged;
  final DateTimeRange? openingDateFilter;
  final ValueChanged<DateTimeRange?> onOpeningDateChanged;
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
  static const Icon _minValueIcon = Icon(Icons.arrow_downward, size: 18);
  static const Icon _maxValueIcon = Icon(Icons.arrow_upward, size: 18);
  static const Icon _endorsedDateIcon = Icon(Icons.event_available, size: 18);
  static const Icon _closingDateIcon = Icon(Icons.event_busy, size: 18);
  // The same glyph the Published Date column heading uses.
  static const Icon _publishedDateIcon = Icon(
    Icons.campaign_outlined,
    size: 18,
  );
  static const Icon _openingDateIcon = Icon(Icons.drafts_outlined, size: 18);

  @override
  Widget build(BuildContext context) {
    return FilterPanelShell(
      onReset: onFiltersReset,
      builder: (context, layout) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Five, five and four. Fourteen filters will not fit three rows
            // of four, so this panel alone runs on a five-cell rhythm:
            // every edge lands on a fifth, and the short last row keeps the
            // four dates together rather than splitting them.
            //
            // The groups stay whole - division and department, the two
            // value bounds, the four dates - so no pair is split across a
            // row break.
            //
            // What kind of document it is, and where it has reached.
            FilterFieldRow(
              useRow: layout.availableWidth >= _rowBreakpoint,
              layout: layout,
              flexes: const [1, 1, 1, 1, 1],
              gridSpans: const [1, 1, 1, 1, 1],
              fieldBuilders: [
                (width) => FilterMultiSelectField(
                  icon: _statusIcon,
                  label: 'Tender Overall Status',
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

            // How it is run, who owns it, and what it is worth.
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
                (width) => FilterNumberField(
                  controller: minimumValueController,
                  icon: _minValueIcon,
                  label: 'From RFC Estimated Value (RM)',
                  placeholder: 'No minimum',
                  onChanged: onMinValueChanged,
                  width: width,
                ),
                (width) => FilterNumberField(
                  controller: maximumValueController,
                  icon: _maxValueIcon,
                  label: 'To RFC Estimated Value (RM)',
                  placeholder: 'No maximum',
                  onChanged: onMaxValueChanged,
                  width: width,
                ),
              ],
            ),
            const SizedBox(height: kFilterRowSpacing),

            // When it happened, in the order the table shows the dates.
            FilterFieldRow(
              useRow: layout.availableWidth >= _rowBreakpoint,
              layout: layout,
              flexes: const [1, 1, 1, 1],
              gridSpans: const [1, 1, 1, 1],
              fieldBuilders: [
                (width) => FilterDateField(
                  icon: _endorsedDateIcon,
                  label: 'RFC Endorsed Date',
                  selectedRange: endorsedDateFilter,
                  onChanged: onEndorsedDateChanged,
                  width: width,
                ),
                (width) => FilterDateField(
                  icon: _publishedDateIcon,
                  label: 'Published Date',
                  selectedRange: publishedDateFilter,
                  onChanged: onPublishedDateChanged,
                  width: width,
                ),
                (width) => FilterDateField(
                  icon: _openingDateIcon,
                  label: 'Tender Opening Date',
                  selectedRange: openingDateFilter,
                  onChanged: onOpeningDateChanged,
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
