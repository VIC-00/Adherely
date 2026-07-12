import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    AppColors.isDark = false; // ensure tokens resolve to light values
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.medBlue),
      scaffoldBackgroundColor: AppColors.canvasBg,
      splashFactory: InkRipple.splashFactory,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.ink900,
        displayColor: AppColors.ink900,
        fontFamily: 'Inter',
      ),
    );
  }

  static ThemeData get dark {
    AppColors.isDark = true; // ensure tokens resolve to dark values
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.medBlue, brightness: Brightness.dark),
      scaffoldBackgroundColor: AppColors.canvasBg,
      splashFactory: InkRipple.splashFactory,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.ink900,
        displayColor: AppColors.ink900,
        fontFamily: 'Inter',
      ),
    );
  }
}
