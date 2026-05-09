import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract class AppTextStyles {
  static const _base = TextStyle(
    color: AppColors.textPrimary,
    letterSpacing: 0,
    decorationColor: AppColors.textPrimary,
  );

  static final displayLarge  = _base.copyWith(fontSize: 50, fontWeight: FontWeight.w800, height: 1.1);
  static final displayMedium = _base.copyWith(fontSize: 42, fontWeight: FontWeight.w700, height: 1.2);

  static final h1 = _base.copyWith(fontSize: 24, fontWeight: FontWeight.w700, height: 1.3);
  static final h2 = _base.copyWith(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3);
  static final h3 = _base.copyWith(fontSize: 18, fontWeight: FontWeight.w600, height: 1.35);

  static final bodyLarge  = _base.copyWith(fontSize: 17, fontWeight: FontWeight.w400, height: 1.5);
  static final bodyMedium = _base.copyWith(fontSize: 15, fontWeight: FontWeight.w400, height: 1.5);
  static final bodySmall  = _base.copyWith(fontSize: 13, fontWeight: FontWeight.w400, height: 1.4);

  static final labelLarge  = _base.copyWith(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.1);
  static final labelMedium = _base.copyWith(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.2);
  static final labelSmall  = _base.copyWith(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.3);

  static final hint = bodyMedium.copyWith(color: AppColors.textHint, fontSize: 15);

  static final disabled = bodyMedium.copyWith(color: AppColors.textDisabled);

  static final link = bodyMedium.copyWith(
    color: AppColors.primary,
    fontWeight: FontWeight.w600,
    decoration: TextDecoration.underline,
  );

  static final secondary = bodyMedium.copyWith(color: AppColors.textSecondary);
}