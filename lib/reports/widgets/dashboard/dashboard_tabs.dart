// lib/reports/widgets/dashboard/dashboard_tabs.dart
//
// The template's `.stabs` strip: a row of labels over a 2px rule, the active
// one picked out in the primary colour with the rule carrying through under
// it. Scrolls sideways rather than wrapping when the window is narrow.
import 'package:flutter/material.dart';

import 'package:etender_reports/reports/widgets/dashboard/dashboard_theme.dart';

class DashTabs extends StatelessWidget {
  const DashTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    // The rule runs the full width behind the tabs, and the active tab's
    // own 2px border sits on top of it. CSS does this with a negative
    // margin; Flutter asserts margins are non-negative, so it is a Stack.
    return Stack(
      children: [
        Positioned.fill(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(height: 2, color: DashTheme.border),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                _Tab(
                  label: labels[i],
                  selected: i == selectedIndex,
                  onTap: () => onSelected(i),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? DashTheme.accent : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? DashTheme.accent : DashTheme.muted,
          ),
        ),
      ),
    );
  }
}
