// lib/reports/widgets/toc/toc_filter_panel.dart
import 'package:etender_reports/reports/widgets/shared/filter_fields.dart';
import 'package:flutter/material.dart';

/// Filters for the TOC report: the document number, a committee member,
/// tender or quotation, the derived status, and the closing window.
///
/// The member search is the one that earns its place — "which openings is
/// this officer sitting on?" is the question the workload panel answers in
/// aggregate and this answers for one person.
class TocFilterPanel extends StatelessWidget {
  const TocFilterPanel({
    super.key,
    required this.tenderNoController,
    required this.onTenderNoChanged,
    required this.memberController,
    required this.onMemberChanged,
    required this.documentTypes,
    required this.selectedDocumentType,
    required this.onDocumentTypeChanged,
    required this.statuses,
    required this.selectedStatuses,
    required this.onStatusesChanged,
    required this.envelopeTypes,
    required this.selectedEnvelopeType,
    required this.onEnvelopeTypeChanged,
    required this.closingDateFilter,
    required this.onClosingDateChanged,
    required this.onFiltersReset,
  });

  final TextEditingController tenderNoController;
  final ValueChanged<String> onTenderNoChanged;

  final TextEditingController memberController;
  final ValueChanged<String> onMemberChanged;

  final List<String> documentTypes;
  final String? selectedDocumentType;
  final ValueChanged<String?> onDocumentTypeChanged;

  final List<String> statuses;
  final Set<String> selectedStatuses;
  final ValueChanged<Set<String>> onStatusesChanged;

  /// Three of the eight statuses only occur under one arrangement, so
  /// narrowing by envelope narrows what the status list can contain.
  final List<String> envelopeTypes;
  final String? selectedEnvelopeType;
  final ValueChanged<String?> onEnvelopeTypeChanged;

  final DateTimeRange? closingDateFilter;
  final ValueChanged<DateTimeRange?> onClosingDateChanged;

  final VoidCallback onFiltersReset;

  /// Width at which a group of fields fits on a single row. 960 across
  /// every report's filter panel, so they all reflow together.
  static const double _rowBreakpoint = 960;

  static const Icon _typeIcon = Icon(Icons.description_outlined, size: 18);
  static const Icon _statusIcon = Icon(Icons.flag_outlined, size: 18);
  static const Icon _closingIcon = Icon(Icons.event_busy_outlined, size: 18);
  static const Icon _envelopeIcon = Icon(Icons.mail_outline, size: 18);

  @override
  Widget build(BuildContext context) {
    return FilterPanelShell(
      subtitle: 'Refine openings',
      onReset: onFiltersReset,
      builder: (context, layout) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Which opening: the number, then what kind and where it has
            // reached. Search spans two cells, so this row's edges fall at
            // 50% and 75%.
            FilterFieldRow(
              useRow: layout.availableWidth >= _rowBreakpoint,
              layout: layout,
              flexes: const [2, 1, 1],
              gridSpans: const [2, 1, 1],
              fieldBuilders: [
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
                (width) => FilterMultiSelectField(
                  icon: _statusIcon,
                  label: 'Status',
                  placeholder: 'All statuses',
                  options: statuses,
                  selectedValues: selectedStatuses,
                  onChanged: onStatusesChanged,
                  width: width,
                ),
              ],
            ),
            const SizedBox(height: kFilterRowSpacing),

            // Who is on it, how it takes bids, and when it closes. Same
            // [2, 1, 1] rhythm as the row above, so the edges line up at
            // 50% and 75%.
            FilterFieldRow(
              useRow: layout.availableWidth >= _rowBreakpoint,
              layout: layout,
              flexes: const [2, 1, 1],
              gridSpans: const [2, 1, 1],
              fieldBuilders: [
                // Name or staff ID; the filter tries both.
                (width) => FilterSearchField(
                  controller: memberController,
                  onChanged: onMemberChanged,
                  label: 'Committee member or staff ID',
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
                (width) => FilterDateField(
                  icon: _closingIcon,
                  label: 'Closing Date',
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
