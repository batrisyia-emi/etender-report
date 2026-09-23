// lib/reports/widgets/filter_fields.dart
//
// Shared building blocks for the report filter panels: the panel shell, the
// tappable selection field, the dropdown field and the multi-select dialog.
// Both FilterPanel and VendorFilterPanel are assembled from these, so styling
// and behaviour only need changing in one place.
import 'package:etender_reports/shared/app_colors.dart';
import 'package:etender_reports/shared/utils/formatters.dart';
import 'package:flutter/material.dart';

/// Horizontal gap between fields on the same row.
const double kFilterFieldSpacing = 8;

/// Vertical gap between rows of fields. Deliberately larger than the
/// horizontal gap so the rows read as separate groups.
const double kFilterRowSpacing = 16;
const Color kFilterAccentColor = AppColors.accent;
const Color kFilterValueColor = AppColors.heading;
const Color kFilterPlaceholderColor = AppColors.placeholder;
const Color kFilterBorderColor = AppColors.border;
const Color kFilterFillColor = AppColors.fill;
const Color kFilterHeaderColor = AppColors.panelHeader;

const InputDecorationTheme kFilterInputTheme = InputDecorationTheme(
  isDense: true,
  filled: true,
  fillColor: kFilterFillColor,
  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
  prefixIconColor: kFilterAccentColor,
  // Tightens the space reserved for the leading icon so more of the selected
  // value is visible in narrow cells.
  prefixIconConstraints: BoxConstraints(minWidth: 30, minHeight: 30),
  labelStyle: TextStyle(fontSize: 13),
  floatingLabelStyle: TextStyle(fontSize: 12, color: kFilterAccentColor),
  border: OutlineInputBorder(borderSide: BorderSide(color: kFilterBorderColor)),
  enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(color: kFilterBorderColor),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(color: AppColors.focus, width: 1.5),
  ),
);

/// Column count for the reflowing grid, driven by the panel's own width.
int filterColumnsFor(double width) {
  if (width >= 980) return 4;
  if (width >= 720) return 3;
  if (width >= 470) return 2;
  return 1;
}

/// Measurements handed to a panel body so it can lay itself out.
class FilterLayout {
  const FilterLayout({
    required this.availableWidth,
    required this.fieldWidth,
    required this.columns,
  });

  factory FilterLayout.of(double availableWidth) {
    final columns = filterColumnsFor(availableWidth);
    final fieldWidth =
        ((availableWidth - kFilterFieldSpacing * (columns - 1)) / columns)
            .floorToDouble();
    return FilterLayout(
      availableWidth: availableWidth,
      fieldWidth: fieldWidth,
      columns: columns,
    );
  }

  final double availableWidth;
  final double fieldWidth;
  final int columns;

  /// Width of a field spanning [cells] grid cells, capped at the column count.
  double span(int cells) {
    final used = cells > columns ? columns : cells;
    return fieldWidth * used + kFilterFieldSpacing * (used - 1);
  }
}

/// One selection reads in full; several read as "First +2" so the field still
/// fits its cell.
String describeFilterSelection(Set<String> selectedValues, String placeholder) {
  if (selectedValues.isEmpty) return placeholder;
  final values = selectedValues.toList();
  if (values.length == 1) return values.first;
  return '${values.first} +${values.length - 1}';
}

/// Returns the new selection, or null when the dialog was cancelled.
Future<Set<String>?> showFilterMultiSelectDialog({
  required BuildContext context,
  required String title,
  required List<String> options,
  required Set<String> selectedValues,
}) {
  final temporarySelection = Set<String>.from(selectedValues);
  return showDialog<Set<String>>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            if (options.isEmpty) {
              return const Text('No options available.');
            }
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: options.map((option) {
                  return CheckboxListTile(
                    value: temporarySelection.contains(option),
                    title: Text(option),
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (checked) {
                      setDialogState(() {
                        if (checked == true) {
                          temporarySelection.add(option);
                        } else {
                          temporarySelection.remove(option);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, <String>{}),
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, temporarySelection),
            child: const Text('Apply'),
          ),
        ],
      );
    },
  );
}

/// [width] is null when a field sits inside an [Expanded].
Widget _constrain({required double? width, required Widget child}) {
  return width == null ? child : SizedBox(width: width, child: child);
}

/// A tappable field styled like the text inputs: floating label on top, the
/// current selection as the value, leading icon.
class FilterSelectionField extends StatelessWidget {
  const FilterSelectionField({
    super.key,
    required this.icon,
    required this.label,
    required this.valueText,
    required this.hasSelection,
    required this.onTap,
    this.width,
  });

  final Icon icon;
  final String label;
  final String valueText;
  final bool hasSelection;
  final VoidCallback onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return _constrain(
      width: width,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: InputDecorator(
          isEmpty: false,
          decoration: InputDecoration(labelText: label, prefixIcon: icon),
          child: Text(
            valueText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: TextStyle(
              fontSize: 13,
              color: hasSelection ? kFilterValueColor : kFilterPlaceholderColor,
              fontWeight: hasSelection ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

/// Single-select dropdown. A null [value] means no filter, shown as
/// [placeholder] (e.g. "All statuses").
class FilterDropdownField extends StatelessWidget {
  const FilterDropdownField({
    super.key,
    required this.icon,
    required this.label,
    required this.placeholder,
    required this.options,
    required this.value,
    required this.onChanged,
    this.width,
    this.optionLabels,
    this.optionSubtitles,
  });

  final Icon icon;
  final String label;
  final String placeholder;
  final List<String> options;
  final String? value;
  final ValueChanged<String?> onChanged;
  final double? width;

  /// Shorter text to show in place of the raw value, keyed by value. Used
  /// where the stored wording is too long for a closed dropdown.
  final Map<String, String>? optionLabels;

  /// A second, quieter line under each option in the open menu — a contract
  /// value threshold, a definition, a count. Not shown when closed.
  final Map<String, String>? optionSubtitles;

  String _labelFor(String option) => optionLabels?[option] ?? option;

  @override
  Widget build(BuildContext context) {
    // Guards against a stale value that is no longer in the option list.
    final safeValue = options.contains(value) ? value : null;

    return _constrain(
      width: width,
      child: InputDecorator(
        isEmpty: false,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon,
          // Slightly tighter than the shared theme so the dropdown lines up
          // with the text fields.
          contentPadding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String?>(
            value: safeValue,
            isExpanded: true,
            isDense: true,
            itemHeight: 52,
            icon: const Icon(Icons.arrow_drop_down, size: 18),
            style: const TextStyle(fontSize: 13, color: kFilterValueColor),
            selectedItemBuilder: (context) => [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  placeholder,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: kFilterPlaceholderColor),
                ),
              ),
              ...options.map(
                (option) => Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _labelFor(option),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(
                  placeholder,
                  style: const TextStyle(color: kFilterPlaceholderColor),
                ),
              ),
              ...options.map((option) {
                final subtitle = optionSubtitles?[option];
                return DropdownMenuItem<String?>(
                  value: option,
                  // selectedItemBuilder keeps the closed field to one line,
                  // so the subtitle only appears in the open menu.
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _labelFor(option),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: const TextStyle(
                            fontSize: 11,
                            color: kFilterPlaceholderColor,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

/// Opens the checkbox dialog and reports the new selection back.
class FilterMultiSelectField extends StatelessWidget {
  const FilterMultiSelectField({
    super.key,
    required this.icon,
    required this.label,
    required this.placeholder,
    required this.options,
    required this.selectedValues,
    required this.onChanged,
    this.width,
  });

  final Icon icon;
  final String label;
  final String placeholder;
  final List<String> options;
  final Set<String> selectedValues;
  final ValueChanged<Set<String>> onChanged;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return FilterSelectionField(
      icon: icon,
      label: label,
      valueText: describeFilterSelection(selectedValues, placeholder),
      hasSelection: selectedValues.isNotEmpty,
      width: width,
      onTap: () async {
        final result = await showFilterMultiSelectDialog(
          context: context,
          title: label,
          options: options,
          selectedValues: selectedValues,
        );
        if (result != null) onChanged(result);
      },
    );
  }
}

/// Opens a date range picker and reports the chosen range back.
class FilterDateField extends StatelessWidget {
  const FilterDateField({
    super.key,
    required this.icon,
    required this.label,
    required this.selectedRange,
    required this.onChanged,
    this.width,
  });

  final Icon icon;
  final String label;
  final DateTimeRange? selectedRange;
  final ValueChanged<DateTimeRange?> onChanged;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return FilterSelectionField(
      icon: icon,
      label: label,
      // formatDateRange already returns 'Any date range' for null.
      valueText: formatDateRange(selectedRange),
      hasSelection: selectedRange != null,
      width: width,
      onTap: () async {
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          initialDateRange: selectedRange,
        );
        onChanged(range);
      },
    );
  }
}

class FilterSearchField extends StatelessWidget {
  const FilterSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.label = 'Search records',
    this.width,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String label;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return _constrain(
      width: width,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.search, size: 18),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class FilterNumberField extends StatelessWidget {
  const FilterNumberField({
    super.key,
    required this.controller,
    required this.icon,
    required this.label,
    required this.placeholder,
    required this.onChanged,
    this.allowDecimal = true,
    this.width,
  });

  final TextEditingController controller;
  final Icon icon;
  final String label;

  /// Shown while the field is empty (e.g. "No minimum"), in place of the
  /// label the select fields would be showing.
  final String placeholder;
  final ValueChanged<String> onChanged;
  final bool allowDecimal;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return _constrain(
      width: width,
      child: TextField(
        controller: controller,
        keyboardType: allowDecimal
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon,
          hintText: placeholder,
          hintStyle: const TextStyle(
            fontSize: 13,
            color: kFilterPlaceholderColor,
          ),
          // The select fields pin their label up with InputDecorator's
          // isEmpty: false. A real TextField needs telling, or the label
          // sits full-size in the box until you type.
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

/// The bordered panel with the blue header and the themed body.
/// [builder] receives the measured layout.
///
/// "Clear filters" lives in the header rather than in a row of its own, and
/// the body collapses, so the panel costs as little vertical space as
/// possible.
class FilterPanelShell extends StatefulWidget {
  const FilterPanelShell({
    super.key,
    required this.builder,
    required this.onReset,
    this.title = 'Filters',
    this.subtitle = 'Refine records',
    this.initiallyExpanded = true,
  });

  final Widget Function(BuildContext context, FilterLayout layout) builder;
  final VoidCallback onReset;
  final String title;
  final String subtitle;
  final bool initiallyExpanded;

  @override
  State<FilterPanelShell> createState() => _FilterPanelShellState();
}

class _FilterPanelShellState extends State<FilterPanelShell> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: kFilterBorderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context)
            .copyWith(inputDecorationTheme: kFilterInputTheme),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(left: 12, right: 6),
              decoration: const BoxDecoration(color: kFilterHeaderColor),
              child: Row(
                children: [
                  const Icon(Icons.tune, size: 15, color: kFilterAccentColor),
                  const SizedBox(width: 6),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: kFilterValueColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.refresh, size: 15),
                    label: const Text('Clear', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: kFilterAccentColor,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: const Size(0, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: widget.onReset,
                  ),
                  IconButton(
                    icon: Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                    ),
                    color: kFilterAccentColor,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 30,
                    ),
                    tooltip: _expanded ? 'Hide filters' : 'Show filters',
                    onPressed: () => setState(() => _expanded = !_expanded),
                  ),
                ],
              ),
            ),
            if (_expanded)
              Padding(
                padding: const EdgeInsets.all(10),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return widget.builder(
                      context,
                      FilterLayout.of(constraints.maxWidth),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Lays children out in one row of [Expanded]s when [useRow] is true,
/// otherwise in the reflowing grid at [FilterLayout.fieldWidth].
/// [flexes] applies only to the row form.
class FilterFieldRow extends StatelessWidget {
  const FilterFieldRow({
    super.key,
    required this.useRow,
    required this.layout,
    required this.fieldBuilders,
    this.flexes = const [],
    this.gridSpans = const [],
  });

  final bool useRow;
  final FilterLayout layout;

  /// Each builder receives a width: null in row form, a cell width in grid
  /// form.
  final List<Widget Function(double? width)> fieldBuilders;
  final List<int> flexes;
  final List<int> gridSpans;

  int _flexAt(int index) => index < flexes.length ? flexes[index] : 1;

  int _spanAt(int index) => index < gridSpans.length ? gridSpans[index] : 1;

  @override
  Widget build(BuildContext context) {
    if (useRow) {
      return Row(
        children: [
          for (var index = 0; index < fieldBuilders.length; index++) ...[
            if (index > 0) const SizedBox(width: kFilterFieldSpacing),
            Expanded(flex: _flexAt(index), child: fieldBuilders[index](null)),
          ],
        ],
      );
    }

    return Wrap(
      spacing: kFilterFieldSpacing,
      runSpacing: kFilterRowSpacing,
      children: [
        for (var index = 0; index < fieldBuilders.length; index++)
          fieldBuilders[index](layout.span(_spanAt(index))),
      ],
    );
  }
}
