// lib/reports/widgets/dashboard/supplier/supplier_bid_stage_cards.dart
//
// The four numbered stages on the supplier's My Bid page, and the stat
// tiles inside them.
//
// A stage is one step of the journey a participation request makes:
// request, pay, decide, submit. The numbering is the point — it tells a
// supplier what comes next, which a flat row of counters would not.
import 'package:etender_reports/reports/widgets/dashboard/dashboard_theme.dart';
import 'package:etender_reports/shared/utils/formatters.dart';
import 'package:flutter/material.dart';

/// One numbered stage, holding the statuses that belong to it.
class SupplierBidStage {
  const SupplierBidStage(this.number, this.title, this.stats);

  final String number;
  final String title;
  final List<SupplierBidStat> stats;
}

/// One status within a stage: how many, and what the supplier does next.
class SupplierBidStat {
  const SupplierBidStat({
    required this.label,
    required this.value,
    required this.hint,
    required this.color,
    required this.icon,
  });

  final String label;
  final int value;

  /// The action this count implies, not a description of the status. A
  /// supplier reading "3 Pending Payment" needs to know to go and pay.
  final String hint;

  final Color color;
  final IconData icon;
}

/// A stage as a card: numbered heading over its stat tiles.
class SupplierBidStageCard extends StatelessWidget {
  const SupplierBidStageCard({
    super.key,
    required this.stage,
    this.tilesPerLine = 2,
  });

  final SupplierBidStage stage;

  /// How many tiles sit side by side before wrapping.
  ///
  /// Set by [SupplierBidStageGrid] and the same for every card, which is
  /// what keeps the tiles a uniform size: a stage holding three tiles shows
  /// two and then one, rather than squeezing three into the width its
  /// neighbours give to two.
  final int tilesPerLine;

  /// The card's own padding, left and right.
  static const double padding = 14;

  /// Between two tiles, across or down.
  static const double tileGap = 10;

  /// DashTheme.cardDecoration draws Border.all, which defaults to 1px and
  /// comes out of the card's own width. Leaving it out of the sums below
  /// overflows every card by exactly 2px.
  static const double border = 1;

  /// Everything in a card that is not a tile or a gap between tiles.
  static const double chrome = (padding + border) * 2;

  /// The tiles split into lines of at most [tilesPerLine].
  List<List<SupplierBidStat>> get lines => [
    for (var start = 0; start < stage.stats.length; start += tilesPerLine)
      stage.stats.sublist(
        start,
        (start + tilesPerLine).clamp(0, stage.stats.length),
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final rows = lines;

    return Container(
      decoration: DashTheme.cardDecoration,
      padding: const EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: DashTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  stage.number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stage.title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DashTheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: DashTheme.border),
          const SizedBox(height: 12),
          for (var r = 0; r < rows.length; r++) ...[
            if (r > 0) const SizedBox(height: tileGap),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < tilesPerLine; i++) ...[
                    if (i > 0) const SizedBox(width: tileGap),
                    // A short last line keeps its tiles the width of the
                    // ones above rather than stretching to fill.
                    Expanded(
                      child: i < rows[r].length
                          ? SupplierBidStatTile(stat: rows[r][i])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One count, its label and the action it implies.
///
/// A zero is greyed rather than hidden: "nothing pending payment" is worth
/// seeing, and a tile that disappeared would shift the ones beside it.
class SupplierBidStatTile extends StatelessWidget {
  const SupplierBidStatTile({super.key, required this.stat});

  final SupplierBidStat stat;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(DashTheme.radius),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: DashTheme.tintOf(stat.color).withValues(alpha: 0.45),
        border: Border(top: BorderSide(color: stat.color, width: 3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: DashTheme.card,
                    borderRadius: BorderRadius.circular(DashTheme.radius),
                  ),
                  child: Icon(stat.icon, size: 17, color: stat.color),
                ),
                const Spacer(),
                Text(
                  formatNumber(stat.value, decimals: 0),
                  style: TextStyle(
                    color: stat.value == 0 ? DashTheme.muted : stat.color,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              stat.label,
              style: const TextStyle(
                color: DashTheme.text,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              stat.hint,
              style: TextStyle(color: stat.color, fontSize: 11, height: 1.3),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Lays the stages out as equal cards.
///
/// Every card is the same width, every tile is the same width, and the one
/// stage holding three tiles wraps the third onto a second line instead of
/// taking more room than its neighbours. Those three facts cannot all hold
/// if a card stretches to fit whatever it contains, which is why the tiles
/// per line are decided here and handed down rather than left to each card.
class SupplierBidStageGrid extends StatelessWidget {
  const SupplierBidStageGrid({super.key, required this.stages});

  final List<SupplierBidStage> stages;

  /// Stage counts per row to try, widest first.
  ///
  /// Four or two, never three: the stages pair up as request-then-pay and
  /// decide-then-submit, and a three-wide row would split those pairs.
  static const List<int> columnChoices = [4, 2, 1];

  /// Tiles sit two abreast wherever there is room for it, so the three-tile
  /// stage always reads as two-then-one and the two-tile stages always fill
  /// their line exactly. One abreast is the fallback on a phone.
  static const int tilesPerLine = 2;

  /// Below this a tile is too narrow for its label.
  static const double minTileWidth = 116;

  /// What one card measures when [columns] of them share [available].
  static double cardWidthFor(double available, int columns) =>
      (available - (columns - 1) * DashTheme.gap) / columns;

  /// The tile width that [columns] cards would give, at [perLine] abreast.
  static double tileWidthFor(double available, int columns, int perLine) {
    final inner =
        cardWidthFor(available, columns) -
        SupplierBidStageCard.chrome -
        (perLine - 1) * SupplierBidStageCard.tileGap;
    return inner / perLine;
  }

  /// The widest layout whose tiles still clear [minTileWidth].
  ///
  /// Falls back to one tile per line before it gives up, so a narrow phone
  /// still gets readable tiles rather than a squeezed pair.
  (int columns, int perLine) layoutFor(double available) {
    for (final columns in columnChoices) {
      if (tileWidthFor(available, columns, tilesPerLine) >= minTileWidth) {
        return (columns, tilesPerLine);
      }
    }
    return (1, 1);
  }

  @override
  Widget build(BuildContext context) {
    if (stages.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final (columns, perLine) = layoutFor(constraints.maxWidth);
        final rows = [
          for (var start = 0; start < stages.length; start += columns)
            stages.sublist(start, (start + columns).clamp(0, stages.length)),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var r = 0; r < rows.length; r++) ...[
              if (r > 0) const SizedBox(height: DashTheme.gap),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < columns; i++) ...[
                      if (i > 0) const SizedBox(width: DashTheme.gap),
                      Expanded(
                        child: i < rows[r].length
                            ? SupplierBidStageCard(
                                stage: rows[r][i],
                                tilesPerLine: perLine,
                              )
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
