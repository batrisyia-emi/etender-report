// lib/reports/widgets/erfc_filter_panel.dart
import 'package:etender_reports/reports/widgets/shared/filter_fields.dart';
import 'package:flutter/material.dart';

/// Filters for the eRFC report: search by RFC number or division, then
/// division, procurement mode, status and submission window.
class ErfcFilterPanel extends StatelessWidget {
  const ErfcFilterPanel({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.divisions,
    required this.selectedDivisions,
    required this.onDivisionsChanged,
    required this.units,
    required this.selectedUnits,
    required this.onUnitsChanged,
    required this.procurementModes,
    required this.selectedProcurementModes,
    required this.onProcurementModesChanged,
    required this.statuses,
    required this.selectedStatuses,
    required this.onStatusesChanged,
    required this.submissionDateFilter,
    required this.onSubmissionDateChanged,
    required this.overdueOnly,
    required this.onOverdueOnlyChanged,
    required this.onFiltersReset,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  final List<String> divisions;
  final Set<String> selectedDivisions;
  final ValueChanged<Set<String>> onDivisionsChanged;

  final List<String> units;
  final Set<String> selectedUnits;
  final ValueChanged<Set<String>> onUnitsChanged;

  final List<String> procurementModes;
  final Set<String> selectedProcurementModes;
  final ValueChanged<Set<String>> onProcurementModesChanged;

  final List<String> statuses;
  final Set<String> selectedStatuses;
  final ValueChanged<Set<String>> onStatusesChanged;

  final DateTimeRange? submissionDateFilter;
  final ValueChanged<DateTimeRange?> onSubmissionDateChanged;

  final bool overdueOnly;
  final ValueChanged<bool> onOverdueOnlyChanged;

  final VoidCallback onFiltersReset;

  /// Width at which search plus three fields fit on one row.
  static const double _rowBreakpoint = 960;

  static const Icon _divisionIcon = Icon(Icons.account_tree_outlined, size: 18);
  static const Icon _unitIcon = Icon(Icons.groups_outlined, size: 18);
  static const Icon _modeIcon = Icon(Icons.gavel_outlined, size: 18);
  static const Icon _statusIcon = Icon(Icons.flag_outlined, size: 18);
  static const Icon _submissionDateIcon = Icon(Icons.calendar_today, size: 18);

  @override
  Widget build(BuildContext context) {
    return FilterPanelShell(
      subtitle: 'Refine RFCs',
      onReset: onFiltersReset,
      builder: (context, layout) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Find it: free text, where it has reached, how it is run.
            FilterFieldRow(
              useRow: layout.availableWidth >= _rowBreakpoint,
              layout: layout,
              // Search spans two cells, so this row fills exactly four.
              flexes: const [2, 1, 1],
              gridSpans: const [2, 1, 1],
              fieldBuilders: [
                (width) => FilterSearchField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  label: 'Search RFC or division',
                  width: width,
                ),
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
                  icon: _modeIcon,
                  label: 'Mode of Procurement',
                  placeholder: 'All modes',
                  options: procurementModes,
                  selectedValues: selectedProcurementModes,
                  onChanged: onProcurementModesChanged,
                  width: width,
                ),
              ],
            ),
            const SizedBox(height: kFilterRowSpacing),

            // Where it sits, then when it landed. Divisions and Units belong
            // together; splitting them across rows was the odd one out.
            Row(
              children: [
                SizedBox(
                  width: layout.span(1),
                  child: FilterMultiSelectField(
                    icon: _divisionIcon,
                    label: 'Divisions',
                    placeholder: 'All divisions',
                    options: divisions,
                    selectedValues: selectedDivisions,
                    onChanged: onDivisionsChanged,
                  ),
                ),
                const SizedBox(width: kFilterFieldSpacing),
                SizedBox(
                  width: layout.span(1),
                  child: FilterMultiSelectField(
                    icon: _unitIcon,
                    label: 'Units',
                    placeholder: 'All units',
                    options: units,
                    selectedValues: selectedUnits,
                    onChanged: onUnitsChanged,
                  ),
                ),
                const SizedBox(width: kFilterFieldSpacing),
                SizedBox(
                  width: layout.span(1),
                  child: FilterDateField(
                    icon: _submissionDateIcon,
                    label: 'Submission Date',
                    selectedRange: submissionDateFilter,
                    onChanged: onSubmissionDateChanged,
                  ),
                ),
                const SizedBox(width: kFilterFieldSpacing),
                // Aging shortcut: in-flight RFCs past the overdue threshold.
                Flexible(
                  child: FilterChip(
                    avatar: Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: overdueOnly ? Colors.white : kFilterAccentColor,
                    ),
                    label: const Text('Overdue only'),
                    selected: overdueOnly,
                    showCheckmark: false,
                    onSelected: onOverdueOnlyChanged,
                    backgroundColor: kFilterFillColor,
                    selectedColor: kFilterAccentColor,
                    labelStyle: TextStyle(
                      color: overdueOnly ? Colors.white : kFilterValueColor,
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
