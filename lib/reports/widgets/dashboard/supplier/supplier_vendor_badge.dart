// lib/reports/widgets/dashboard/supplier/supplier_vendor_badge.dart
//
// Who the signed-in supplier is: name, supplier ID and the categories they
// bid in.
//
// All three are read off the supplier's own participation rows rather than
// from a stored profile. The records already carry `supplierName` and
// `tenderCategory`, so a separate profile object would be a second copy of
// the same facts — and the one this page used to take held an invented
// performance score beside them.
import 'package:etender_reports/reports/widgets/dashboard/dashboard_primitives.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_theme.dart';
import 'package:flutter/material.dart';

class SupplierVendorBadge extends StatelessWidget {
  const SupplierVendorBadge({
    super.key,
    required this.supplierName,
    required this.supplierId,
    required this.categories,
  });

  final String supplierName;
  final String supplierId;

  /// The tender categories this supplier has actually bid in, derived from
  /// their rows.
  final Set<String> categories;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DashTheme.headerTint,
        border: Border.all(color: DashTheme.border),
        borderRadius: BorderRadius.circular(DashTheme.radius),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          const Icon(
            Icons.storefront_outlined,
            size: 22,
            color: DashTheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  supplierName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: DashTheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  '\$supplierId · Registered Supplier',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: DashTheme.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final category in categories)
                DashPill(label: category, color: DashTheme.accent),
            ],
          ),
        ],
      ),
    );
  }
}
