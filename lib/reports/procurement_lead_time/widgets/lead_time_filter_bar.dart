// lib/reports/procurement_lead_time/widgets/lead_time_filter_bar.dart
import 'package:etender_reports/reports/procurement_lead_time/lead_time_rules.dart';
import 'package:etender_reports/reports/procurement_lead_time/models/lead_time_query.dart';
import 'package:etender_reports/reports/widgets/shared/filter_fields.dart';
import 'package:etender_reports/shared/utils/formatters.dart';
import 'package:flutter/material.dart';

/// Below this window width the period chips become a dropdown. The same
/// width at which `ReportsShell` switches to its narrow-screen spacing.
const double kLeadTimeNarrowWidth = 600;

/// Received Date, Mode of Procurement, Document Type and Search.
///
/// Holds the unsubmitted values itself. A received date preset fills the
/// dates and searches straight away. Custom shows a date range field
/// instead, opened on the dates last searched, and waits for Search, which
/// validates with [validateLeadTimeDates] first. Errors appear once Search
/// has been pressed, then track every change, so fixing the range clears
/// its message without another press.
class LeadTimeFilterBar extends StatefulWidget {
  const LeadTimeFilterBar({
    super.key,
    required this.onSearch,
    required this.today,
    this.initialQuery,
    this.isSearching = false,
  });

  final ValueChanged<LeadTimeQuery> onSearch;

  /// What the presets count from. Passed in so a test can pin it.
  final DateTime today;

  /// The last search, so coming back to the report shows what produced the
  /// results under it.
  final LeadTimeQuery? initialQuery;

  final bool isSearching;

  @override
  State<LeadTimeFilterBar> createState() => _LeadTimeFilterBarState();
}

class _LeadTimeFilterBarState extends State<LeadTimeFilterBar> {
  late DateTime? _from = widget.initialQuery?.receivedFrom;
  late DateTime? _to = widget.initialQuery?.receivedTo;
  late DocumentTypeFilter _type =
      widget.initialQuery?.type ?? DocumentTypeFilter.tender;

  /// A mode code such as '7.2'; null for all modes.
  late String? _mode = widget.initialQuery?.procurementMode;
  late PeriodPreset _preset =
      widget.initialQuery?.preset ?? PeriodPreset.custom;

  bool _submitted = false;

  LeadTimeDateErrors get _errors =>
      _submitted ? validateLeadTimeDates(_from, _to) : (from: null, to: null);

  /// A preset fills both dates and searches at once. Custom only takes the
  /// selection and shows the range field, still holding the last dates.
  void _selectPeriod(PeriodPreset preset) {
    if (preset == PeriodPreset.custom) {
      setState(() => _preset = preset);
      return;
    }
    final query = LeadTimeQuery.forPreset(
      preset,
      today: widget.today,
      type: _type,
      procurementMode: _mode,
    );
    setState(() {
      _preset = preset;
      _from = query.receivedFrom;
      _to = query.receivedTo;
      _submitted = false;
    });
    widget.onSearch(query);
  }

  void _pickRange(DateTimeRange range) {
    setState(() {
      _from = range.start;
      _to = range.end;
    });
  }

  void _search() {
    setState(() => _submitted = true);
    final from = _from;
    final to = _to;
    if (!validateLeadTimeDates(from, to).isValid) return;
    widget.onSearch(
      LeadTimeQuery(
        receivedFrom: from!,
        receivedTo: to!,
        type: _type,
        procurementMode: _mode,
        preset: _preset,
      ),
    );
  }

  /// Back to how the report opens: the default period, Tender, searched.
  void _reset() {
    _type = DocumentTypeFilter.tender;
    _mode = null;
    _selectPeriod(LeadTimeRules.defaultPeriod);
  }

  @override
  Widget build(BuildContext context) {
    final errors = _errors;
    final narrow = MediaQuery.sizeOf(context).width < kLeadTimeNarrowWidth;

    return FilterPanelShell(
      title: 'Search criteria',
      onReset: _reset,
      builder: (context, layout) {
        // One width for every box in the form, so the period dropdown and
        // Document Type line up in a column. On a phone each box takes the
        // full width under its label.
        final contentWidth = narrow
            ? layout.availableWidth
            : layout.availableWidth - _FormRow.labelWidth - _FormRow.gap;
        final fieldWidth = narrow
            ? contentWidth
            : ((contentWidth - 3 * kFilterFieldSpacing) / 4).clamp(
                160.0,
                260.0,
              );

        final search = SizedBox(
          width: narrow ? double.infinity : null,
          child: FilledButton.icon(
            onPressed: widget.isSearching ? null : _search,
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Search'),
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _FormRow(
              label: 'Received Date',
              stacked: narrow,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (narrow)
                    _PeriodDropdown(
                      value: _preset,
                      width: fieldWidth,
                      onChanged: _selectPeriod,
                    )
                  else
                    _PeriodChips(value: _preset, onSelected: _selectPeriod),
                  // Only Custom has dates of the user's own to enter.
                  if (_preset == PeriodPreset.custom) ...[
                    const SizedBox(height: kFilterRowSpacing),
                    _DateRangeField(
                      from: _from,
                      to: _to,
                      errorText: errors.from ?? errors.to,
                      // As wide as two boxes, so both dates show in full.
                      width: narrow
                          ? fieldWidth
                          : fieldWidth * 2 + kFilterFieldSpacing,
                      onPicked: _pickRange,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: kFilterRowSpacing),
            // Like Document Type, waits for Search rather than re-running.
            _FormRow(
              label: 'Mode of Procurement',
              stacked: narrow,
              child: _ProcurementModeRadios(
                value: _mode,
                onChanged: (mode) => setState(() => _mode = mode),
              ),
            ),
            const SizedBox(height: kFilterRowSpacing),
            _FormRow(
              label: 'Document Type',
              stacked: narrow,
              child: narrow
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _DocumentTypeField(
                          value: _type,
                          onChanged: (type) => setState(() => _type = type),
                        ),
                        const SizedBox(height: kFilterRowSpacing),
                        search,
                      ],
                    )
                  // Search closes the form at its right edge.
                  : Row(
                      children: [
                        _DocumentTypeField(
                          value: _type,
                          width: fieldWidth,
                          onChanged: (type) => setState(() => _type = type),
                        ),
                        const Spacer(),
                        search,
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// One line of the search form: its label in a fixed column on the left
/// and the control beside it, so every row's options start at the same
/// place. [stacked] puts the label above instead, for phones.
class _FormRow extends StatelessWidget {
  const _FormRow({
    required this.label,
    required this.child,
    required this.stacked,
  });

  final String label;
  final Widget child;
  final bool stacked;

  /// Wide enough for 'Mode of Procurement' on one line.
  static const double labelWidth = 170;
  static const double gap = 12;

  @override
  Widget build(BuildContext context) {
    final text = Text(label, style: Theme.of(context).textTheme.labelLarge);
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [text, const SizedBox(height: 6), child],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: labelWidth,
          // Level with the first line of chips, radios or boxes.
          child: Padding(padding: const EdgeInsets.only(top: 9), child: text),
        ),
        const SizedBox(width: gap),
        Expanded(child: child),
      ],
    );
  }
}

/// One choice chip per received date preset, single selection.
class _PeriodChips extends StatelessWidget {
  const _PeriodChips({required this.value, required this.onSelected});

  final PeriodPreset value;
  final ValueChanged<PeriodPreset> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final preset in PeriodPreset.values)
          ChoiceChip(
            label: Text(preset.label),
            selected: preset == value,
            // No checkmark: it would widen the chip and shift the row
            // every time the selection moves.
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            selectedColor: scheme.primaryContainer,
            labelStyle: theme.textTheme.labelMedium?.copyWith(
              color: preset == value
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
              fontWeight: preset == value ? FontWeight.w600 : null,
            ),
            onSelected: (_) => onSelected(preset),
          ),
      ],
    );
  }
}

/// 'Mode of Procurement': All modes, or one of the five that are published.
/// Wraps onto further lines on a narrow screen.
class _ProcurementModeRadios extends StatelessWidget {
  const _ProcurementModeRadios({required this.value, required this.onChanged});

  /// A mode code, or null for all modes.
  final String? value;
  final ValueChanged<String?> onChanged;

  /// Stands in for null inside the group, which needs a value per button.
  static const String _allModes = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = [
      (value: _allModes, label: 'All modes'),
      for (final mode in LeadTimeRules.procurementModes)
        (value: mode.code, label: '${mode.code} ${mode.label}'),
    ];

    return RadioGroup<String>(
      groupValue: value ?? _allModes,
      onChanged: (selected) {
        if (selected == null) return;
        onChanged(selected == _allModes ? null : selected);
      },
      child: Wrap(
        spacing: 4,
        runSpacing: 0,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final option in options)
            // The label selects too, not only the small circle.
            InkWell(
              onTap: () =>
                  onChanged(option.value == _allModes ? null : option.value),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<String>(
                      value: option.value,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    // Wraps instead of overflowing when one label is
                    // wider than a phone's panel.
                    Flexible(
                      child: Text(
                        option.label,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The chips as one dropdown, for narrow screens. Same options, same
/// behaviour.
class _PeriodDropdown extends StatelessWidget {
  const _PeriodDropdown({
    required this.value,
    required this.onChanged,
    required this.width,
  });

  final PeriodPreset value;
  final ValueChanged<PeriodPreset> onChanged;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: InputDecorator(
        isEmpty: false,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.date_range_outlined, size: 18),
          contentPadding: EdgeInsets.fromLTRB(10, 6, 4, 6),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<PeriodPreset>(
            value: value,
            isDense: true,
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down, size: 18),
            style: Theme.of(context).textTheme.bodyMedium,
            items: [
              for (final preset in PeriodPreset.values)
                DropdownMenuItem(value: preset, child: Text(preset.label)),
            ],
            onChanged: (preset) {
              if (preset != null) onChanged(preset);
            },
          ),
        ),
      ),
    );
  }
}

/// The Custom received date range, both ends required, shown
/// dd.MM.yyyy – dd.MM.yyyy with its error underneath. One picker sets both
/// ends, so To can never come before From.
class _DateRangeField extends StatelessWidget {
  const _DateRangeField({
    required this.from,
    required this.to,
    required this.errorText,
    required this.onPicked,
    this.width,
  });

  final DateTime? from;
  final DateTime? to;
  final String? errorText;
  final ValueChanged<DateTimeRange> onPicked;
  final double? width;

  Future<void> _pick(BuildContext context) async {
    final from = this.from;
    final to = this.to;
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: from != null && to != null && !from.isAfter(to)
          ? DateTimeRange(start: from, end: to)
          : null,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Received Date',
    );
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final from = this.from;
    final to = this.to;
    final empty = from == null && to == null;
    String show(DateTime? date) => date == null ? '…' : formatDottedDate(date);
    final field = InkWell(
      onTap: () => _pick(context),
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        isEmpty: false,
        decoration: InputDecoration(
          labelText: 'From – To *',
          prefixIcon: const Icon(Icons.date_range_outlined, size: 18),
          errorText: errorText,
          errorMaxLines: 2,
        ),
        child: Text(
          empty ? 'Select a date range' : '${show(from)} – ${show(to)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: empty ? theme.colorScheme.onSurfaceVariant : null,
          ),
        ),
      ),
    );
    return width == null ? field : SizedBox(width: width, child: field);
  }
}

/// Tender / Quotation / All. Never empty, unlike the shared dropdown, which
/// always offers a "no filter" choice.
class _DocumentTypeField extends StatelessWidget {
  const _DocumentTypeField({
    required this.value,
    required this.onChanged,
    this.width,
  });

  final DocumentTypeFilter value;
  final ValueChanged<DocumentTypeFilter> onChanged;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final field = InputDecorator(
      isEmpty: false,
      decoration: const InputDecoration(
        // Tender or Quotation, read from the number prefix. The form row
        // beside it carries the name.
        prefixIcon: Icon(Icons.category_outlined, size: 18),
        contentPadding: EdgeInsets.fromLTRB(10, 6, 4, 6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DocumentTypeFilter>(
          value: value,
          isDense: true,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, size: 18),
          style: Theme.of(context).textTheme.bodyMedium,
          items: [
            for (final option in DocumentTypeFilter.values)
              DropdownMenuItem(value: option, child: Text(option.label)),
          ],
          onChanged: (option) {
            if (option != null) onChanged(option);
          },
        ),
      ),
    );
    return width == null ? field : SizedBox(width: width, child: field);
  }
}
