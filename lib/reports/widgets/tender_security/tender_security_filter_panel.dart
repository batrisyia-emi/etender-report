// lib/reports/widgets/tender_security/tender_security_filter_panel.dart
import 'package:etender_reports/reports/models/tender_security_filters.dart';
import 'package:etender_reports/reports/widgets/shared/filter_fields.dart';
import 'package:flutter/material.dart';

/// Filters for the Tender Security report: the document, the tenderer, how
/// the security was lodged, and which of the named views to show.
class TenderSecurityFilterPanel extends StatelessWidget {
  const TenderSecurityFilterPanel({
    super.key,
    required this.tenderNoController,
    required this.onTenderNoChanged,
    required this.vendorController,
    required this.onVendorChanged,
    required this.paymentTypes,
    required this.paymentTypeLabels,
    required this.selectedPaymentType,
    required this.onPaymentTypeChanged,
    required this.views,
    required this.selectedView,
    required this.onViewChanged,
    required this.onFiltersReset,
  });

  final TextEditingController tenderNoController;
  final ValueChanged<String> onTenderNoChanged;

  final TextEditingController vendorController;
  final ValueChanged<String> onVendorChanged;

  final List<String> paymentTypes;

  /// Wire value to label: the dropdown stores `BANK_GUARANTEE` and shows
  /// "Bank Guarantee".
  final Map<String, String> paymentTypeLabels;
  final String? selectedPaymentType;
  final ValueChanged<String?> onPaymentTypeChanged;

  final List<String> views;
  final String selectedView;
  final ValueChanged<String> onViewChanged;

  final VoidCallback onFiltersReset;

  /// 960 across every report's filter panel, so they all reflow together.
  static const double _rowBreakpoint = 960;

  static const Icon _viewIcon = Icon(Icons.filter_alt_outlined, size: 18);
  static const Icon _instrumentIcon = Icon(Icons.payments_outlined, size: 18);

  @override
  Widget build(BuildContext context) {
    return FilterPanelShell(
      subtitle: 'Refine securities',
      onReset: onFiltersReset,
      builder: (context, layout) {
        // One row of four equal cells, so the edges fall at 25%, 50% and
        // 75% like every other panel.
        return FilterFieldRow(
          useRow: layout.availableWidth >= _rowBreakpoint,
          layout: layout,
          fieldBuilders: [
            (width) => FilterSearchField(
              controller: tenderNoController,
              onChanged: onTenderNoChanged,
              label: 'Tender / Quotation No',
              width: width,
            ),
            (width) => FilterSearchField(
              controller: vendorController,
              onChanged: onVendorChanged,
              label: 'Name of tenderer',
              width: width,
            ),
            (width) => FilterDropdownField(
              icon: _instrumentIcon,
              label: 'Payment Type',
              placeholder: 'All payment types',
              options: paymentTypes,
              optionLabels: paymentTypeLabels,
              value: selectedPaymentType,
              onChanged: onPaymentTypeChanged,
              width: width,
            ),
            // Not a multi-select: each view is a whole question about a
            // row, and asking two at once ("expired" and "refunded") asks
            // for nothing. "All" is the way back.
            (width) => FilterDropdownField(
              icon: _viewIcon,
              label: 'Show',
              placeholder: TenderSecurityView.all.label,
              options: views,
              value: selectedView,
              onChanged: (value) =>
                  onViewChanged(value ?? TenderSecurityView.all.label),
              width: width,
            ),
          ],
        );
      },
    );
  }
}
