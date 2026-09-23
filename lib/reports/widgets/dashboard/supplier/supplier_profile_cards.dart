// lib/reports/widgets/dashboard/supplier/supplier_profile_cards.dart
//
// The panels that describe the supplier itself: who the portal thinks
// they are, their headline figures, and the score behind them.
import 'package:flutter/material.dart';

import 'package:etender_reports/reports/models/supplier_dashboard_metrics.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_cards.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_primitives.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_theme.dart';
import 'package:etender_reports/shared/utils/formatters.dart';

class SupplierVendorBadge extends StatelessWidget {
  const SupplierVendorBadge({
    super.key,
    required this.profile,
    required this.categories,
  });

  final Map<String, dynamic> profile;
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
          Icon(Icons.storefront_outlined, size: 22, color: DashTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  profile['supplierName']?.toString() ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: DashTheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${profile['supplierId']} · Registered Supplier',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: DashTheme.muted,
                  ),
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

class SupplierKpiRow extends StatelessWidget {
  const SupplierKpiRow({
    super.key,
    required this.profile,
    required this.bids,
    required this.certificates,
    required this.tenders,
    required this.categories,
    required this.now,
  });

  final Map<String, dynamic> profile;
  final List<Map<String, dynamic>> bids;
  final List<Map<String, dynamic>> certificates;
  final List<Map<String, dynamic>> tenders;
  final Set<String> categories;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final open = supplierOpenTenders(tenders, now);
    final matching = supplierOpenTenders(tenders, now, categories: categories);
    final expiring = supplierDocumentsNeedingRenewal(certificates, now);
    final inPlay = supplierBidsInPlay(bids);
    final score = profile['performanceScore'] as int;

    return DashCardGrid(
      cards: [
        DashKpiCard(
          icon: Icons.article_outlined,
          accent: DashTheme.accent,
          value: formatNumber(open.length, decimals: 0),
          label: 'Open Tenders',
          note: '${matching.length} match your categories',
          noteColor: matching.isEmpty ? null : DashTheme.warning,
        ),
        DashKpiCard(
          icon: Icons.task_alt,
          accent: DashTheme.success,
          value: formatNumber(bids.length, decimals: 0),
          label: 'Bids Submitted',
          note: '$inPlay awaiting decision',
        ),
        DashKpiCard(
          icon: Icons.schedule,
          accent: DashTheme.danger,
          value: formatNumber(expiring.length, decimals: 0),
          label: 'Docs Expiring Soon',
          note: expiring.isEmpty ? 'All current' : 'Action required',
          noteColor: expiring.isEmpty ? DashTheme.success : DashTheme.danger,
        ),
        DashKpiCard(
          icon: Icons.speed_outlined,
          accent: DashTheme.purple,
          value: '$score%',
          label: 'Vendor Score',
          note: profile['scorePercentile']?.toString(),
        ),
      ],
    );
  }
}

class SupplierProfileHealthCard extends StatelessWidget {
  const SupplierProfileHealthCard({
    super.key,
    required this.profile,
    required this.certificates,
    required this.now,
    this.onViewDocuments,
  });

  final Map<String, dynamic> profile;
  final List<Map<String, dynamic>> certificates;
  final DateTime now;

  /// Omitted on the Profile tab, where Documents is one tab away anyway.
  final VoidCallback? onViewDocuments;

  /// The template colours each criterion by how close to full it is.
  static Color _bandOf(int percent) => percent >= 90
      ? DashTheme.success
      : percent >= 80
      ? DashTheme.accent
      : DashTheme.warning;

  @override
  Widget build(BuildContext context) {
    final score = profile['performanceScore'] as int;
    final breakdown = profile['scoreBreakdown'] as List;
    final expiring = supplierDocumentsNeedingRenewal(certificates, now);

    return DashCard(
      icon: Icons.verified_outlined,
      title: 'Vendor Score & Profile Health',
      subtitle: 'Based on PPP criteria',
      trailing: onViewDocuments == null
          ? null
          : DashButton(label: 'Documents', onTap: onViewDocuments!),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '$score',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: DashTheme.primary,
                  height: 1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 2, bottom: 2),
                child: Text(
                  '/ 100',
                  style: TextStyle(fontSize: 13, color: DashTheme.muted),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Vendor Performance Score',
                  style: TextStyle(fontSize: 11.5, color: DashTheme.muted),
                ),
              ),
              DashPill(
                label: profile['scoreTier']?.toString() ?? '',
                color: DashTheme.success,
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < breakdown.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            DashMeasureBar(
              label: (breakdown[i] as Map)['name'].toString(),
              valueLabel: '${(breakdown[i] as Map)['percent']}%',
              fraction: ((breakdown[i] as Map)['percent'] as int) / 100,
              color: _bandOf((breakdown[i] as Map)['percent'] as int),
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1, color: DashTheme.border),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Bumiputera status',
                  style: TextStyle(fontSize: 12, color: DashTheme.text),
                ),
              ),
              DashPill(
                label: profile['bumiputera'] == true ? 'Yes' : 'No',
                color: profile['bumiputera'] == true
                    ? DashTheme.success
                    : DashTheme.muted,
              ),
            ],
          ),
          if (expiring.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final document in expiring) ...[
              SupplierExpiringRow(certificate: document, now: now),
              const SizedBox(height: 6),
            ],
          ],
        ],
      ),
    );
  }
}

class SupplierExpiringRow extends StatelessWidget {
  const SupplierExpiringRow({
    super.key,
    required this.certificate,
    required this.now,
  });

  final Map<String, dynamic> certificate;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final days = supplierDaysToExpiry(certificate, now) ?? 0;
    final lapsed = days < 0;
    final color = days <= kSupplierExpiryCriticalDays
        ? DashTheme.danger
        : DashTheme.warning;

    return Row(
      children: [
        Icon(
          lapsed ? Icons.error_outline : Icons.warning_amber_outlined,
          size: 15,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            certificate['name']?.toString() ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.5, color: DashTheme.text),
          ),
        ),
        Text(
          lapsed ? 'Expired' : 'Expires in $days days',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
