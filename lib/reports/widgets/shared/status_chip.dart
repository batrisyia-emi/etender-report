// lib/reports/widgets/status_chip.dart
import 'package:flutter/material.dart';

/// Text and background for a chip.
typedef ChipColors = ({Color text, Color background});

/// The chip colours the three tables were each defining for themselves.
class ChipPalette {
  const ChipPalette._();

  static ChipColors get green =>
      (text: Colors.green.shade700, background: Colors.green.shade50);
  static ChipColors get blue =>
      (text: Colors.blue.shade700, background: Colors.blue.shade50);
  static ChipColors get orange =>
      (text: Colors.orange.shade700, background: Colors.orange.shade50);
  static ChipColors get grey =>
      (text: Colors.grey.shade700, background: Colors.grey.shade100);
  static ChipColors get red =>
      (text: Colors.red.shade700, background: Colors.red.shade50);
  static ChipColors get indigo =>
      (text: Colors.indigo.shade600, background: Colors.indigo.shade50);
  static ChipColors get blueGrey =>
      (text: Colors.blueGrey.shade600, background: Colors.blueGrey.shade50);
}

/// Soft rounded label used for statuses in every report table.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.colors});

  final String label;
  final ChipColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: colors.text,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }
}
