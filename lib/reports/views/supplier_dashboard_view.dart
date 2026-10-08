// lib/reports/views/supplier_dashboard_view.dart
//
// The supplier's own dashboard: where each of their participation requests
// stands. It wears DashTheme like the SE dashboard, so the two cannot
// drift apart.
//
// Everything on this page comes from the supplier participation dataset —
// the same rows the My Participation report reads. The only thing supplied
// from outside it is which supplier is signed in.
//
// No tab strip. The SE dashboard has one because it has five tabs to move
// between; this page has one view, and a strip holding a single tab that
// cannot be changed is decoration — it repeated the "My Bid" heading
// directly beneath it.
import 'package:etender_reports/data/mock/signed_in_supplier.dart';
import 'package:etender_reports/data/mock/supplier_records.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_theme.dart';
import 'package:etender_reports/reports/widgets/dashboard/supplier/supplier_my_bid_dashboard.dart';
import 'package:flutter/material.dart';

class SupplierDashboardView extends StatelessWidget {
  const SupplierDashboardView({super.key, required this.fillHeight});

  /// When true the page fills the window and scrolls inside it. Below that
  /// height the shell scrolls the whole page instead.
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    const panel = SupplierMyBidDashboard(
      supplierId: kSignedInSupplierId,
      records: kSupplierRecords,
    );

    if (!fillHeight) return panel;

    return const SingleChildScrollView(
      // The always-visible thumb is painted over the content, so without
      // this the right-hand card loses its border to it.
      padding: EdgeInsets.only(right: kDashScrollbarGutter),
      child: panel,
    );
  }
}
