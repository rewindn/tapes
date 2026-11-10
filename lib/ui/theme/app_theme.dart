import 'package:flutter/material.dart';
import 'package:tapes/constants/app_colors.dart';

class AppTheme {
  static const String headingFont = 'PlayfairDisplay';

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.tapeGold)
        .copyWith(primary: AppColors.tapeGold, onPrimary: AppColors.textDark);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: headingFont,
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        headlineMedium: TextStyle(
          fontFamily: headingFont,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
        titleLarge: TextStyle(
          fontFamily: headingFont,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      ),
    );
  }
}
