// lib/reports/widgets/shared/table_heading.dart
import 'package:etender_reports/shared/app_colors.dart';
import 'package:flutter/material.dart';

/// A column heading with a small icon ahead of its label.
///
/// The icon is decoration, not information. Every one of them repeats what
/// the words beside it already say, so no column depends on anyone reading
/// a pictogram correctly, and a heading still works for a screen reader.
/// What it buys is a landmark: these tables run to eighteen columns and
/// three thousand pixels, and an icon is quicker to find your place by on
/// the way back than a word you have to read first.
///
/// Wrap a [SortableHeader] with the default constructor; use [label] for a
/// column that cannot be sorted.
class TableHeading extends StatelessWidget {
  const TableHeading({super.key, required this.icon, required this.child});

  /// A plain heading, for a column with no sort on it.
  TableHeading.label(IconData icon, String text, {Key? key})
    : this(
        key: key,
        icon: icon,
        child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
      );

  final IconData icon;

  /// The heading itself — a [Text], or a `SortableHeader`.
  final Widget child;

  /// What the icon costs a column: the glyph plus the gap after it.
  ///
  /// Every table's width arithmetic has to find this from somewhere, so it
  /// is named here rather than appearing as a bare 20 in six files.
  static const double width = 20;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.tableHeadingText),
        const SizedBox(width: 6),
        Flexible(child: child),
      ],
    );
  }
}
