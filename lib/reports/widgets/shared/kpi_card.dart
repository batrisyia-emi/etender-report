// lib/reports/widgets/shared/kpi_card.dart
//
// Reusable metric card and its proportional grid. Each report composes its
// own set of cards; this file knows nothing about tenders, vendors or RFCs.
import 'package:flutter/material.dart';

const Color kKpiHeading = Color(0xFF8095AD);
const Color kKpiValue = Color(0xFF1F2D3D);
const Color kKpiMuted = Color(0xFF6B7A8F);
const Color kKpiBorder = Color(0xFFD8E3F0);
const Color kKpiAccent = Color(0xFF315B91);

const Color kKpiGreenText = Color(0xFF15803D);
const Color kKpiGreenTint = Color(0xFFECFDF3);
const Color kKpiOrangeText = Color(0xFFB45309);
const Color kKpiOrangeTint = Color(0xFFFFF7ED);
const Color kKpiBlueText = Color(0xFF1D4ED8);
const Color kKpiBlueTint = Color(0xFFEFF6FF);
const Color kKpiRedText = Color(0xFFB91C1C);
const Color kKpiRedTint = Color(0xFFFEF2F2);
const Color kKpiGreyText = Color(0xFF475569);
const Color kKpiGreyTint = Color(0xFFF1F5F9);

/// Every card is 1/N of the available width, where N is however many fit at
/// [minCardWidth]. No breakpoints to maintain.
///
/// Cards are laid out as chunked rows rather than a Wrap so that every card
/// in a row is the same height: IntrinsicHeight sizes the row to its tallest
/// card and stretch makes the others match. A Wrap sizes each child
/// independently, which leaves ragged card bottoms whenever one footer wraps
/// to a second line.
class KpiCardRow extends StatelessWidget {
  const KpiCardRow({
    super.key,
    required this.cards,
    this.spacing = 12,
    this.minCardWidth = 230,
  });

  final List<Widget> cards;
  final double spacing;
  final double minCardWidth;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            ((constraints.maxWidth + spacing) / (minCardWidth + spacing))
                .floor()
                .clamp(1, cards.length);

        if (columns == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < cards.length; index++) ...[
                if (index > 0) SizedBox(height: spacing),
                cards[index],
              ],
            ],
          );
        }

        final rows = <List<Widget>>[];
        for (var start = 0; start < cards.length; start += columns) {
          final end = (start + columns).clamp(0, cards.length);
          rows.add(cards.sublist(start, end));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) ...[
              if (rowIndex > 0) SizedBox(height: spacing),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var index = 0; index < columns; index++) ...[
                      if (index > 0) SizedBox(width: spacing),
                      // Empty slots keep the last row's cards the same width
                      // as every other row's.
                      Expanded(
                        child: index < rows[rowIndex].length
                            ? rows[rowIndex][index]
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// White card: small muted header, large value, optional footer slot, tinted
/// icon. Lifts on hover when [onTap] is set.
class KpiCard extends StatefulWidget {
  const KpiCard({
    super.key,
    required this.header,
    required this.value,
    required this.icon,
    this.iconTint = kKpiGreyTint,
    this.iconColor = kKpiGreyText,
    this.footer,
    this.onTap,
  });

  final String header;
  final String value;
  final IconData icon;
  final Color iconTint;
  final Color iconColor;
  final Widget? footer;
  final VoidCallback? onTap;

  @override
  State<KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<KpiCard> {
  bool _hovered = false;

  bool get _interactive => widget.onTap != null;

  @override
  Widget build(BuildContext context) {
    final lifted = _interactive && _hovered;

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      constraints: const BoxConstraints(minHeight: 84),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: lifted ? kKpiAccent : kKpiBorder),
        boxShadow: [
          BoxShadow(
            color: kKpiValue.withValues(alpha: lifted ? 0.12 : 0.05),
            blurRadius: lifted ? 14 : 6,
            offset: Offset(0, lifted ? 4 : 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Two lines rather than one: a header long enough to
                    // name its report as well as its metric does not fit
                    // across a 230px card, and silently ellipsising it hides
                    // the part that distinguishes the card.
                    Text(
                      widget.header,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: kKpiHeading,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: kKpiValue,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                height: 28,
                width: 28,
                decoration: BoxDecoration(
                  color: widget.iconTint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(widget.icon, size: 16, color: widget.iconColor),
              ),
            ],
          ),
          if (widget.footer != null) ...[
            const SizedBox(height: 8),
            widget.footer!,
          ],
        ],
      ),
    );

    if (!_interactive) return card;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(onTap: widget.onTap, child: card),
    );
  }
}

/// Single helper line, with an optional leading icon.
class KpiFooterText extends StatelessWidget {
  const KpiFooterText(
    this.text, {
    super.key,
    this.icon,
    this.color = kKpiMuted,
  });

  final String text;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: color, fontSize: 11),
    );

    if (icon == null) return label;

    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Expanded(child: label),
      ],
    );
  }
}

/// "+12% vs last month" — green for a rise, red for a fall.
class KpiTrendFooter extends StatelessWidget {
  const KpiTrendFooter({
    super.key,
    required this.percent,
    this.caption = 'vs last month',
  });

  final double percent;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final rising = percent >= 0;
    final color = rising ? kKpiGreenText : kKpiRedText;
    final rounded = percent.abs() % 1 == 0
        ? percent.abs().toStringAsFixed(0)
        : percent.abs().toStringAsFixed(1);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: rising ? kKpiGreenTint : kKpiRedTint,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Icon(
                rising ? Icons.trending_up : Icons.trending_down,
                size: 12,
                color: color,
              ),
              const SizedBox(width: 3),
              Text(
                '${rising ? '+' : '-'}$rounded%',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: kKpiMuted, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

/// One soft badge per label, e.g. a status or category breakdown.
class KpiBadge {
  const KpiBadge(this.label, this.text, this.tint);

  final String label;
  final Color text;
  final Color tint;

  static KpiBadge green(String label) =>
      KpiBadge(label, kKpiGreenText, kKpiGreenTint);
  static KpiBadge orange(String label) =>
      KpiBadge(label, kKpiOrangeText, kKpiOrangeTint);
  static KpiBadge blue(String label) =>
      KpiBadge(label, kKpiBlueText, kKpiBlueTint);
  static KpiBadge red(String label) =>
      KpiBadge(label, kKpiRedText, kKpiRedTint);
  static KpiBadge grey(String label) =>
      KpiBadge(label, kKpiGreyText, kKpiGreyTint);
}

class KpiBadgeFooter extends StatelessWidget {
  const KpiBadgeFooter({super.key, required this.badges, this.maxVisible = 3});

  final List<KpiBadge> badges;

  /// Beyond this the rest collapse into a "+N more" chip.
  ///
  /// Cards in a row are matched to the tallest, so an uncapped footer on one
  /// card stretches every card beside it. Three is about what fits on two
  /// lines in a quarter-width card.
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) return const KpiFooterText('No records');

    final visible = badges.take(maxVisible).toList();
    final hidden = badges.length - visible.length;
    final shown = [...visible, if (hidden > 0) KpiBadge.grey('+$hidden more')];

    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: shown.map((badge) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: badge.tint,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            badge.label,
            style: TextStyle(
              color: badge.text,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }
}
