// lib/shared/app_colors.dart
import 'package:flutter/material.dart';

/// Every hex literal that was repeated across the report widgets. Values are
/// unchanged — this only gives them one home.
class AppColors {
  const AppColors._();

  static const Color surface = Colors.white;

  static const Color border = Color(0xFFD8E3F0);
  static const Color divider = Color(0xFFE3EAF4);
  static const Color fill = Color(0xFFF8FAFD);
  static const Color focus = Color(0xFF3B82F6);

  static const Color panelHeader = Color(0xFFDCEAFE);
  static const Color accent = Color(0xFF315B91);
  static const Color heading = Color(0xFF1F2D3D);
  static const Color placeholder = Color(0xFF8FA3B8);
  static const Color muted = Color(0xFF6B7280);

  static const Color tableHeadingBackground = Color(0xFFF1F5FB);
  static const Color tableHeadingText = Color(0xFF2563EB);
  static const Color tableBodyText = Color(0xFF374151);
}
