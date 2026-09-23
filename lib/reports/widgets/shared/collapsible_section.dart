// lib/reports/widgets/shared/collapsible_section.dart
import 'package:flutter/material.dart';

/// A slim header strip with a chevron that hides its child. Used to fold the
/// overview cards away when the table needs the height.
///
/// Lighter than FilterPanelShell on purpose: the cards carry their own
/// borders, so a second frame around them would read as clutter.
class CollapsibleSection extends StatefulWidget {
  const CollapsibleSection({
    super.key,
    required this.title,
    required this.child,
    this.icon = Icons.insights_outlined,
    this.collapsedSummary,
    this.initiallyExpanded = true,
  });

  final String title;
  final Widget child;
  final IconData icon;

  /// Shown in the header while collapsed, e.g. "8 metrics hidden".
  final String? collapsedSummary;

  final bool initiallyExpanded;

  static const Color _accent = Color(0xFF315B91);
  static const Color _heading = Color(0xFF1F2D3D);
  static const Color _muted = Color(0xFF6B7A8F);

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(widget.icon, size: 15, color: CollapsibleSection._accent),
                const SizedBox(width: 6),
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: CollapsibleSection._heading,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                if (!_expanded && widget.collapsedSummary != null)
                  Expanded(
                    child: Text(
                      widget.collapsedSummary!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CollapsibleSection._muted,
                        fontSize: 11,
                      ),
                    ),
                  )
                else
                  const Spacer(),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: CollapsibleSection._accent,
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[const SizedBox(height: 8), widget.child],
      ],
    );
  }
}
