import 'package:flutter/material.dart';

/// Color tokens mirrored 1:1 from the Figma Make design (index.css :root).
class AppColors {
  AppColors._();

  static const Color medBlue = Color(0xFF3B82F6);
  static const Color medBlueLight = Color(0xFFEFF6FF);
  static const Color medBlueDark = Color(0xFF1D4ED8);

  static const Color medGreen = Color(0xFF22C55E);
  static const Color medGreenLight = Color(0xFFF0FDF4);
  static const Color medGreenBorder = Color(0xFF86EFAC);

  static const Color medRed = Color(0xFFEF4444);
  static const Color medRedLight = Color(0xFFFEF2F2);
  static const Color medRedBorder = Color(0xFFFCA5A5);

  static const Color medOrange = Color(0xFFF97316);
  static const Color medPurple = Color(0xFF8B5CF6);
  static const Color medTeal = Color(0xFF0D9488);

  // NOTE: isDark is a mutable static that must be set at the top of every
  // screen's build() via:
  //   AppColors.isDark = Theme.of(context).brightness == Brightness.dark;
  // This pattern is intentional for this app's single-theme-at-a-time usage.
  static bool isDark = false;

  static Color get canvasBg => isDark ? const Color(0xFF111827) : const Color(0xFFF0F4F8);
  static Color get screenBg => isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC);
  static Color get cardBg   => isDark ? const Color(0xFF1F2937) : Colors.white;

  static Color get ink900 => isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
  static Color get ink700 => isDark ? const Color(0xFFE5E7EB) : const Color(0xFF374151);
  static Color get ink500 => isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
  static Color get ink400 => isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
  static Color get hairline => isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6);
  static Color get border   => isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
}
