// lib/reports/widgets/dashboard/dashboard_theme.dart
//
// The dashboard keeps the layout of docs/supplier-portal-template.html — the KPI row, the
// 3fr/2fr split, the tab strip, the tinted card header — but wears the same
// palette as the reports. Nothing here invents a colour: every value comes
// from AppColors or the KPI card constants the report cards already use, so
// the two halves of the app cannot drift apart.
import 'package:etender_reports/reports/widgets/shared/kpi_card.dart';
import 'package:etender_reports/shared/app_colors.dart';
import 'package:flutter/material.dart';

/// Width reserved down the right of a scrolling panel so the always-on
/// scrollbar thumb has somewhere to sit instead of covering the last
/// column's border.
const double kDashScrollbarGutter = 14;

class DashTheme {
  const DashTheme._();

  // ---- Semantic colours, mapped onto the reports' own ----

  /// Headers and the active tab, matching the report panels' title colour.
  static const Color primary = AppColors.heading;

  /// The accent the sidebar and filter fields already use.
  static const Color accent = AppColors.accent;

  static const Color success = kKpiGreenText;
  static const Color danger = kKpiRedText;
  static const Color warning = kKpiOrangeText;
  static const Color info = kKpiBlueText;
  static const Color purple = Color(0xFF4F46E5);

  static const Color background = AppColors.fill;
  static const Color card = AppColors.surface;
  static const Color border = AppColors.border;
  static const Color text = AppColors.heading;
  static const Color muted = kKpiMuted;

  /// The blue title strip on every report panel.
  static const Color headerTint = AppColors.panelHeader;

  /// The KPI cards pair each accent with a fixed pale tint rather than an
  /// alpha blend, so the dashboard uses the same pairs.
  static Color tintOf(Color color) => switch (color) {
    kKpiGreenText => kKpiGreenTint,
    kKpiRedText => kKpiRedTint,
    kKpiOrangeText => kKpiOrangeTint,
    kKpiBlueText => kKpiBlueTint,
    purple => const Color(0xFFEEF2FF),
    _ => kKpiGreyTint,
  };

  /// 6, to match ReportPanel rather than the template's 4.
  static const double radius = 6;
  static const double gap = 16;

  static BoxDecoration get cardDecoration => BoxDecoration(
    color: card,
    border: Border.all(color: border),
    borderRadius: BorderRadius.circular(radius),
  );
}
