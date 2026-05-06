import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract class AppTextStyles {
  static const _base = TextStyle(
    color: AppColors.textPrimary,
    letterSpacing: 0,
    decorationColor: AppColors.textPrimary,
  );

  // Display
  static final displayLarge  = _base.copyWith(fontSize: 32, fontWeight: FontWeight.w800, height: 1.2);
  static final displayMedium = _base.copyWith(fontSize: 26, fontWeight: FontWeight.w700, height: 1.25);

  // Headings
  static final h1 = _base.copyWith(fontSize: 22, fontWeight: FontWeight.w700, height: 1.3);
  static final h2 = _base.copyWith(fontSize: 18, fontWeight: FontWeight.w600, height: 1.3);
  static final h3 = _base.copyWith(fontSize: 16, fontWeight: FontWeight.w600, height: 1.35);

  // Body
  static final bodyLarge  = _base.copyWith(fontSize: 15, fontWeight: FontWeight.w400, height: 1.55);
  static final bodyMedium = _base.copyWith(fontSize: 13, fontWeight: FontWeight.w400, height: 1.5);
  static final bodySmall  = _base.copyWith(fontSize: 11, fontWeight: FontWeight.w400, height: 1.45);

  // Labels
  static final labelLarge  = _base.copyWith(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.1);
  static final labelMedium = _base.copyWith(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.2);
  static final labelSmall  = _base.copyWith(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.3);

  // Variants
  static final secondary = bodyMedium.copyWith(color: AppColors.textSecondary);
  static final hint      = bodySmall.copyWith(color: AppColors.textHint);
  static final disabled  = bodyMedium.copyWith(color: AppColors.textDisabled);
  static final link      = bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w500);
}