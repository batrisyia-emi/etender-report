// lib/reports/widgets/dashboard/dashboard_primitives.dart
//
// The small pieces both dashboards are assembled from: a labelled bar, a
// tinted pill, an outlined or filled button, and the bar list the
// breakdown panels use. They lived twice, once in each dashboard, until
// the two files were split up.
import 'package:flutter/material.dart';

import 'package:etender_reports/reports/widgets/dashboard/dashboard_theme.dart';

class DashMeasureBar extends StatelessWidget {
  const DashMeasureBar({
    super.key,
    required this.label,
    required this.valueLabel,
    required this.fraction,
    required this.color,
  });

  final String label;
  final String valueLabel;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: DashTheme.text),
              ),
            ),
            Text(
              valueLabel,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(DashTheme.radius),
          child: LinearProgressIndicator(
            value: fraction.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: DashTheme.tintOf(color),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class DashButton extends StatelessWidget {
  const DashButton({
    super.key,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? DashTheme.accent : Colors.transparent,
      borderRadius: BorderRadius.circular(DashTheme.radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DashTheme.radius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            border: Border.all(
              color: filled ? DashTheme.accent : DashTheme.border,
            ),
            borderRadius: BorderRadius.circular(DashTheme.radius),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: filled ? Colors.white : DashTheme.accent,
            ),
          ),
        ),
      ),
    );
  }
}

class DashPill extends StatelessWidget {
  const DashPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: DashTheme.tintOf(color),
        borderRadius: BorderRadius.circular(DashTheme.radius),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class DashBarList extends StatelessWidget {
  const DashBarList({super.key, required this.rows, required this.total});

  final List<(String, int, Color)> rows;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          DashBar(
            label: rows[i].$1,
            count: rows[i].$2,
            total: total,
            color: rows[i].$3,
          ),
        ],
      ],
    );
  }
}

class DashBar extends StatelessWidget {
  const DashBar({
    super.key,
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  final String label;
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : count / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: DashTheme.text),
              ),
            ),
            Text(
              total == 0 ? '$count' : '$count of $total',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: DashTheme.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(DashTheme.radius),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            backgroundColor: DashTheme.tintOf(color),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
