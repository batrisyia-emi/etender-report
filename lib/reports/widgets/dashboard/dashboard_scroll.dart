// lib/reports/widgets/dashboard/dashboard_scroll.dart
import 'package:flutter/material.dart';

/// A horizontal scroller whose bar is always drawn, so it reads as
/// scrollable. The bar only appears once the content overflows.
class DashHorizontalScroll extends StatefulWidget {
  const DashHorizontalScroll({
    super.key,
    required this.child,
    this.barSpace = 14,
  });

  final Widget child;

  /// Room kept under the content so the bar does not sit on top of it.
  final double barSpace;

  @override
  State<DashHorizontalScroll> createState() => _DashHorizontalScrollState();
}

class _DashHorizontalScrollState extends State<DashHorizontalScroll> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scrollbar(
    controller: _controller,
    thumbVisibility: true,
    trackVisibility: true,
    child: SingleChildScrollView(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.only(bottom: widget.barSpace),
      child: widget.child,
    ),
  );
}
