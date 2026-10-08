// lib/reports/widgets/dashboard/supplier/supplier_my_bid_dashboard.dart
//
// The supplier's "My Bid" page: their own participation requests, grouped
// by the four stages a request moves through.
//
// The stage cards and their tiles live in supplier_bid_stage_cards.dart.
// This file decides which records belong to the signed-in supplier, counts
// them by status, and lays the header out.
import 'package:etender_reports/reports/models/status/supplier_status.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_period.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_theme.dart';
import 'package:etender_reports/reports/widgets/dashboard/supplier/supplier_bid_stage_cards.dart';
import 'package:etender_reports/reports/widgets/dashboard/supplier/supplier_vendor_badge.dart';
import 'package:etender_reports/shared/utils/formatters.dart';
import 'package:flutter/material.dart';

class SupplierMyBidDashboard extends StatefulWidget {
  const SupplierMyBidDashboard({
    super.key,
    required this.supplierId,
    required this.records,
  });

  /// Which supplier is signed in. The only fact here that does not come
  /// from the records themselves.
  final String supplierId;

  /// Every supplier's rows; the signed-in supplier's are picked out here.
  ///
  /// Scoping in the widget is a stand-in. A real backend has to return only
  /// this supplier's rows — see known issue 3 in the README.
  final List<Map<String, dynamic>> records;

  @override
  State<SupplierMyBidDashboard> createState() => _SupplierMyBidDashboardState();
}

class _SupplierMyBidDashboardState extends State<SupplierMyBidDashboard> {
  DashPeriod _period = DashPeriod.thisMonth;

  /// The statuses where the supplier has something to do next.
  static const Set<SupplierStatus> _needsAction = {
    SupplierStatus.requestApproved,
    SupplierStatus.requestRejected,
    SupplierStatus.pendingPayment,
    SupplierStatus.participated,
    SupplierStatus.draft,
  };

  /// Every row belonging to the signed-in supplier, whatever its date.
  ///
  /// The badge reads from these rather than the filtered set: who the
  /// supplier is does not change when they pick a shorter period.
  List<Map<String, dynamic>> get _ownRecords => widget.records
      .where((r) => r['supplierId']?.toString() == widget.supplierId)
      .toList();

  /// This supplier's rows closing inside the selected window.
  List<Map<String, dynamic>> _visibleRecords(DateTime now) {
    return _ownRecords.where((record) {
      final closing = DateTime.tryParse(
        record['closingDate']?.toString() ?? '',
      );
      return _period.contains(closing);
    }).toList();
  }

  /// The four stages, in the order a request passes through them.
  List<SupplierBidStage> _stages(int Function(SupplierStatus) count) => [
    SupplierBidStage('1', 'Request to Participate', [
      SupplierBidStat(
        label: 'Participation Requested',
        value: count(SupplierStatus.participationRequested),
        hint: 'Awaiting approval',
        color: DashTheme.warning,
        icon: Icons.back_hand_outlined,
      ),
      SupplierBidStat(
        label: 'Request Approved',
        value: count(SupplierStatus.requestApproved),
        hint: 'Proceed to buy document',
        color: DashTheme.accent,
        icon: Icons.check_circle_outline,
      ),
      SupplierBidStat(
        label: 'Request Rejected',
        value: count(SupplierStatus.requestRejected),
        hint: 'View rejected remarks',
        color: DashTheme.danger,
        icon: Icons.cancel_outlined,
      ),
    ]),
    SupplierBidStage('2', 'Document Purchase', [
      SupplierBidStat(
        label: 'Pending Payment',
        value: count(SupplierStatus.pendingPayment),
        hint: 'Complete document payment',
        color: DashTheme.danger,
        icon: Icons.credit_card_outlined,
      ),
      SupplierBidStat(
        label: 'Paid',
        value: count(SupplierStatus.paid),
        hint: 'Document downloadable',
        color: DashTheme.success,
        icon: Icons.receipt_long_outlined,
      ),
    ]),
    SupplierBidStage('3', 'Participation', [
      SupplierBidStat(
        label: 'Participated',
        value: count(SupplierStatus.participated),
        hint: 'Prepare your bid',
        color: DashTheme.purple,
        icon: Icons.flag_outlined,
      ),
      SupplierBidStat(
        label: 'Not Participate',
        value: count(SupplierStatus.notParticipate),
        hint: 'Not bidding',
        color: DashTheme.muted,
        icon: Icons.remove_circle_outline,
      ),
    ]),
    SupplierBidStage('4', 'Bid Submission', [
      SupplierBidStat(
        label: 'Draft',
        value: count(SupplierStatus.draft),
        hint: 'Submit before closing',
        color: DashTheme.warning,
        icon: Icons.edit_outlined,
      ),
      SupplierBidStat(
        label: 'Submitted',
        value: count(SupplierStatus.submitted),
        hint: 'Bid documents received',
        color: DashTheme.success,
        icon: Icons.send_outlined,
      ),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final own = _ownRecords;
    final records = _visibleRecords(now);

    // Both read off the supplier's own rows: the name is the same on every
    // one of them, and the categories are the ones they have bid in.
    final supplierName = own.isEmpty
        ? ''
        : own.first['supplierName']?.toString() ?? '';
    final categories = <String>{
      for (final record in own)
        if (record['tenderCategory']?.toString() case final c?)
          if (c.isNotEmpty) c,
    };

    int count(SupplierStatus status) => records
        .where((r) => SupplierStatus.fromWire(r['status']) == status)
        .length;

    final actionCount = _needsAction.fold<int>(
      0,
      (sum, status) => sum + count(status),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SupplierVendorBadge(
          supplierName: supplierName,
          supplierId: widget.supplierId,
          categories: categories,
        ),
        const SizedBox(height: 20),
        DashPeriodSelector(
          selected: _period,
          onChanged: (period) => setState(() => _period = period),
        ),
        const SizedBox(height: 20),
        _MyBidHeader(actionCount: actionCount, asOf: now),
        const SizedBox(height: 16),
        SupplierBidStageGrid(stages: _stages(count)),
      ],
    );
  }
}

/// The page title, what needs doing, and when the figures are from.
class _MyBidHeader extends StatelessWidget {
  const _MyBidHeader({required this.actionCount, required this.asOf});

  final int actionCount;
  final DateTime asOf;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 10,
      children: [
        const Text(
          'My Bid',
          style: TextStyle(
            color: DashTheme.text,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (actionCount > 0) _ActionBadge(count: actionCount),
            Text(
              'Prototype data as of ${formatDateOnly(asOf.toIso8601String())}',
              style: const TextStyle(color: DashTheme.muted, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}

/// Shown only when something is waiting on the supplier, so its presence
/// is itself the signal.
class _ActionBadge extends StatelessWidget {
  const _ActionBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: DashTheme.tintOf(DashTheme.warning),
        borderRadius: BorderRadius.circular(DashTheme.radius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flag_outlined, size: 16, color: DashTheme.warning),
          const SizedBox(width: 8),
          Text(
            count == 1
                ? '1 response needs your action'
                : '$count responses need your action',
            style: const TextStyle(
              color: DashTheme.warning,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
