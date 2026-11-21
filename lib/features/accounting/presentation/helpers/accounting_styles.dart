import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_fonts.dart';

/// The text styles of the accounting screens: Tajawal in the app's navy, the
/// same family and weights the pharmacy home and products pages use.
abstract class AccountingStyles {
  /// The look of the accounting forms' text fields: dense, an 8px corner, a grey
  /// border that turns teal when focused. [hint], [suffix] and [prefixText] are
  /// what each form adds.
  static InputDecoration inputDecoration({String? hint, Widget? suffix, String? prefixText}) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.r),
      borderSide: BorderSide(color: color),
    );
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: muted.copyWith(fontSize: 13.sp),
      suffixIcon: suffix,
      prefixText: prefixText,
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      enabledBorder: border(AppColors.cardBorder),
      focusedBorder: border(AppColors.mainTeal),
    );
  }

  static TextStyle get sectionTitle => AppFonts.tajawal(
    TextStyle(fontSize: 16.sp, height: 1.4, color: AppColors.onboardingText),
    FontWeight.w700,
  );

  static TextStyle get cardTitle => AppFonts.tajawal(
    TextStyle(fontSize: 14.sp, height: 1.4, color: AppColors.onboardingText),
    FontWeight.w700,
  );

  static TextStyle get body => AppFonts.tajawal(
    TextStyle(fontSize: 13.sp, height: 1.5, color: AppColors.onboardingText),
    FontWeight.w500,
  );

  /// Supporting lines: Medium Tajawal in the app's muted blue-grey, dark enough
  /// to read on white (the pale #98ADB3 it was made in washed out).
  static TextStyle get muted => AppFonts.tajawal(
    TextStyle(fontSize: 12.sp, height: 1.5, color: AppColors.authTextMuted),
    FontWeight.w500,
  );

  static TextStyle get label => AppFonts.tajawal(
    TextStyle(fontSize: 12.sp, height: 1.4, color: AppColors.authTextMuted),
    FontWeight.w500,
  );

  /// A figure on a card: Bold in the app's blue.
  static TextStyle get amount => AppFonts.tajawal(
    TextStyle(fontSize: 18.sp, height: 1.3, color: AppColors.mainTeal),
    FontWeight.w700,
  );

  static TextStyle get bigAmount => AppFonts.tajawal(
    TextStyle(fontSize: 28.sp, height: 1.2, color: AppColors.mainTeal),
    FontWeight.w800,
  );
}
