// lib/reports/views/cards/vendor_kpi_cards.dart
import 'package:etender_reports/shared/utils/formatters.dart';
import 'package:flutter/material.dart';

import 'package:etender_reports/reports/models/vendor_metrics.dart';
import 'package:etender_reports/reports/widgets/shared/kpi_card.dart';

/// Anything the funnel counts is also a filter, so each of those three
/// cards taps through to its own slice — and taps again to clear it.
const Set<String> kVendorSubmittedStatuses = {'Submitted', 'Late'};

/// The procurement metrics for vendor participation: the invitation ->
/// purchase -> submission funnel, competition level, and equity mix.
List<Widget> buildVendorKpiCards({
  required List<Map<String, dynamic>> records,
  VoidCallback? onInvitedTap,
  VoidCallback? onParticipatedTap,
  VoidCallback? onPurchasedTap,
  VoidCallback? onSubmittedTap,
}) {
  final invited = vendorInvitedCount(records);
  final participated = vendorParticipatedCount(records);
  final purchased = vendorPurchasedCount(records);
  final submitted = vendorSubmittedCount(records);

  /// The funnel is records -> invited -> participated -> purchased ->
  /// submitted, each step a subset of the one before it. Invitations read
  /// against every record, participation against the invited, and both the
  /// purchases and the bids against the vendors that took part.
  String outOf(int part, int whole) => whole == 0 ? '-' : '$part of $whole';

  return [
    KpiCard(
      header: 'VENDOR RECORDS',
      value: formatNumber(records.length, decimals: 0),
      icon: Icons.groups_outlined,
    ),
    KpiCard(
      header: 'INVITATIONS SENT',
      value: formatNumber(invited, decimals: 0),
      icon: Icons.mail_outline,
      iconTint: kKpiBlueTint,
      iconColor: kKpiBlueText,
      onTap: invited == 0 ? null : onInvitedTap,
      footer: KpiFooterText('${outOf(invited, records.length)} vendors'),
    ),
    KpiCard(
      header: 'VENDORS PARTICIPATED',
      value: formatNumber(participated, decimals: 0),
      icon: Icons.how_to_reg_outlined,
      iconTint: kKpiBlueTint,
      iconColor: kKpiBlueText,
      onTap: participated == 0 ? null : onParticipatedTap,
      // Measured against the invited, not every record: a vendor that was
      // never sent an invitation had none to take up.
      footer: KpiFooterText(
        '${outOf(participated, invited)} took up the invite',
      ),
    ),
    KpiCard(
      header: 'DOCS PURCHASED',
      value: formatNumber(purchased, decimals: 0),
      icon: Icons.shopping_cart_outlined,
      onTap: purchased == 0 ? null : onPurchasedTap,
      // The document only unlocks once a vendor clicks participate, so the
      // buyers are a subset of the participants, not of the invited.
      footer: KpiFooterText(
        '${outOf(purchased, participated)} participants bought it',
      ),
    ),
    KpiCard(
      header: 'SUBMISSIONS',
      value: formatNumber(submitted, decimals: 0),
      icon: Icons.inbox_outlined,
      iconTint: kKpiGreenTint,
      iconColor: kKpiGreenText,
      onTap: submitted == 0 ? null : onSubmittedTap,
      // A submission only comes from a vendor that took the invitation up,
      // so this reads against the participants rather than the invited.
      footer: KpiFooterText('${outOf(submitted, participated)} participants'),
    ),
  ];
}
