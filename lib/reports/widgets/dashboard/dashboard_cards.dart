// lib/reports/widgets/dashboard/dashboard_cards.dart
//
// The two shapes the template builds its dashboard from:
//
//   .kcard  a tinted 46px icon square beside a value, a label and a delta
//   .card   a tinted header strip (.ch) over a body (.cb, or .cb0 for tables)
import 'package:flutter/material.dart';

import 'package:etender_reports/reports/widgets/dashboard/dashboard_theme.dart';

/// `.kcard` — the headline figures across the top of the page.
class DashKpiCard extends StatelessWidget {
  const DashKpiCard({
    super.key,
    required this.icon,
    required this.accent,
    required this.value,
    required this.label,
    this.note,
    this.noteColor,
  });

  final IconData icon;

  /// Drives both the icon and its tinted square, per `.kico.kb/.kg/.kw/.kr`.
  final Color accent;
  final String value;
  final String label;

  /// `.kdelta`, the small line under the label. Omitted when there is
  /// nothing worth saying.
  final String? note;
  final Color? noteColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DashTheme.cardDecoration,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: DashTheme.tintOf(accent),
              borderRadius: BorderRadius.circular(DashTheme.radius),
            ),
            child: Icon(icon, size: 22, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // A headline figure that ellipsises tells you nothing, so
                // a long one shrinks to fit its card instead.
                Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: DashTheme.text,
                        height: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: DashTheme.muted,
                  ),
                ),
                if (note != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    note!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: noteColor ?? DashTheme.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `.card` with its `.ch` header strip. [padded] is the `.cb` / `.cb0` split:
/// false lets a table run to the card's edges.
class DashCard extends StatelessWidget {
  const DashCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.padded = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DashTheme.cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: DashTheme.headerTint,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 17, color: DashTheme.primary),
                const SizedBox(width: 9),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: DashTheme.primary,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: DashTheme.muted,
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 10), trailing!],
              ],
            ),
          ),
          Padding(
            padding: padded
                ? const EdgeInsets.symmetric(horizontal: 18, vertical: 16)
                : EdgeInsets.zero,
            child: child,
          ),
        ],
      ),
    );
  }
}

/// The `3fr / 2fr` split the template uses for its main rows, stacking to one
/// column when the window is too narrow for both.
class DashSplitRow extends StatelessWidget {
  const DashSplitRow({
    super.key,
    required this.wide,
    required this.narrow,
    this.breakpoint = 900,
  });

  final Widget wide;
  final Widget narrow;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              wide,
              const SizedBox(height: DashTheme.gap),
              narrow,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: wide),
            const SizedBox(width: DashTheme.gap),
            Expanded(flex: 2, child: narrow),
          ],
        );
      },
    );
  }
}

/// The KPI row's responsive wrap: four across on a wide window, two when
/// it narrows, one on a phone. Both dashboards lay their headline figures
/// out with it, so they break at the same widths.
class DashCardGrid extends StatelessWidget {
  const DashCardGrid({super.key, required this.cards});

  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 4
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        final rows = <Widget>[];
        for (var start = 0; start < cards.length; start += columns) {
          final end = (start + columns).clamp(0, cards.length);
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = start; i < end; i++) ...[
                  if (i > start) const SizedBox(width: DashTheme.gap),
                  Expanded(child: cards[i]),
                ],
                // Keeps a short last row's cards the same width as the rest.
                for (var i = end; i < start + columns; i++) ...[
                  const SizedBox(width: DashTheme.gap),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: DashTheme.gap),
              IntrinsicHeight(child: rows[i]),
            ],
          ],
        );
      },
    );
  }
}
