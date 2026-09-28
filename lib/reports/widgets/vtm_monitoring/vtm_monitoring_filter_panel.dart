// lib/reports/widgets/vtm_monitoring/vtm_monitoring_filter_panel.dart
import 'package:etender_reports/reports/widgets/shared/filter_fields.dart';
import 'package:flutter/material.dart';

/// The seven filters the report spec names: the two numbers, what kind of
/// document, where it has reached, how it is being procured, whose it is,
/// and when the eRFC was endorsed.
class VtmMonitoringFilterPanel extends StatelessWidget {
  const VtmMonitoringFilterPanel({
    super.key,
    required this.erfcNoController,
    required this.onErfcNoChanged,
    required this.tenderNoController,
    required this.onTenderNoChanged,
    required this.documentTypes,
    required this.selectedDocumentType,
    required this.onDocumentTypeChanged,
    required this.statuses,
    required this.statusLabels,
    required this.selectedStatuses,
    required this.onStatusesChanged,
    required this.modes,
    required this.modeLabels,
    required this.selectedMode,
    required this.onModeChanged,
    required this.divisions,
    required this.selectedDivision,
    required this.onDivisionChanged,
    required this.endorsedDateFilter,
    required this.onEndorsedDateChanged,
    required this.onFiltersReset,
  });

  /// The key every row carries, so it leads.
  final TextEditingController erfcNoController;
  final ValueChanged<String> onErfcNoChanged;

  /// Only assigned once the document is approved, so this matches nothing
  /// on most rows in flight.
  final TextEditingController tenderNoController;
  final ValueChanged<String> onTenderNoChanged;

  final List<String> documentTypes;
  final String? selectedDocumentType;
  final ValueChanged<String?> onDocumentTypeChanged;

  final List<String> statuses;

  /// Code to label: the filter stores `VERIFIED_BY_EXEC` and shows
  /// "Verified by VTM Executive".
  final Map<String, String> statusLabels;
  final Set<String> selectedStatuses;
  final ValueChanged<Set<String>> onStatusesChanged;

  final List<String> modes;
  final Map<String, String> modeLabels;
  final String? selectedMode;
  final ValueChanged<String?> onModeChanged;

  final List<String> divisions;
  final String? selectedDivision;
  final ValueChanged<String?> onDivisionChanged;

  final DateTimeRange? endorsedDateFilter;
  final ValueChanged<DateTimeRange?> onEndorsedDateChanged;

  final VoidCallback onFiltersReset;

  /// 960 across every report's filter panel, so they all reflow together.
  static const double _rowBreakpoint = 960;

  static const Icon _typeIcon = Icon(Icons.description_outlined, size: 18);
  static const Icon _statusIcon = Icon(Icons.flag_outlined, size: 18);
  static const Icon _modeIcon = Icon(Icons.gavel_outlined, size: 18);
  static const Icon _divisionIcon = Icon(Icons.account_tree_outlined, size: 18);
  static const Icon _endorsedIcon = Icon(Icons.event_available, size: 18);

  @override
  Widget build(BuildContext context) {
    return FilterPanelShell(
      subtitle: 'Refine documents',
      onReset: onFiltersReset,
      builder: (context, layout) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Find it: the eRFC number spans two cells because it is the
            // key every row has, so this row's edges fall at 50% and 75%.
            FilterFieldRow(
              useRow: layout.availableWidth >= _rowBreakpoint,
              layout: layout,
              flexes: const [2, 1, 1],
              gridSpans: const [2, 1, 1],
              fieldBuilders: [
                (width) => FilterSearchField(
                  controller: erfcNoController,
                  onChanged: onErfcNoChanged,
                  label: 'eRFC No',
                  width: width,
                ),
                (width) => FilterSearchField(
                  controller: tenderNoController,
                  onChanged: onTenderNoChanged,
                  label: 'Tender / Quotation No',
                  width: width,
                ),
                (width) => FilterDropdownField(
                  icon: _typeIcon,
                  label: 'Document Type',
                  placeholder: 'Tenders and quotations',
                  options: documentTypes,
                  value: selectedDocumentType,
                  onChanged: onDocumentTypeChanged,
                  width: width,
                ),
              ],
            ),
            const SizedBox(height: kFilterRowSpacing),

            // Where it has reached, how it is run, whose it is, and when it
            // started. Four equal cells: edges at 25%, 50% and 75%.
            FilterFieldRow(
              useRow: layout.availableWidth >= _rowBreakpoint,
              layout: layout,
              fieldBuilders: [
                (width) => FilterMultiSelectField(
                  icon: _statusIcon,
                  label: 'Status',
                  placeholder: 'All statuses',
                  options: statuses,
                  optionLabels: statusLabels,
                  selectedValues: selectedStatuses,
                  onChanged: onStatusesChanged,
                  width: width,
                ),
                (width) => FilterDropdownField(
                  icon: _modeIcon,
                  label: 'Mode of Procurement',
                  placeholder: 'All modes',
                  options: modes,
                  optionLabels: modeLabels,
                  value: selectedMode,
                  onChanged: onModeChanged,
                  width: width,
                ),
                (width) => FilterDropdownField(
                  icon: _divisionIcon,
                  label: 'Division',
                  placeholder: 'All divisions',
                  options: divisions,
                  value: selectedDivision,
                  onChanged: onDivisionChanged,
                  width: width,
                ),
                (width) => FilterDateField(
                  icon: _endorsedIcon,
                  label: 'eRFC Endorsed Date',
                  selectedRange: endorsedDateFilter,
                  onChanged: onEndorsedDateChanged,
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
