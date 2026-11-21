import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// The look of the text fields of the sign-in and sign-up forms: white, an 8px
/// corner, a grey border that turns teal when focused and red on an error. The
/// forms add what is theirs (a suffix icon, a hint) with `copyWith`.
InputDecoration authFieldDecoration() {
  OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(8.r),
    borderSide: BorderSide(color: color, width: width),
  );

  return InputDecoration(
    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
    fillColor: Colors.white,
    filled: true,
    enabledBorder: border(AppColors.authInputBorder, 1.0),
    focusedBorder: border(AppColors.primaryTeal, 1.5),
    errorBorder: border(AppColors.authError, 1.0),
    focusedErrorBorder: border(AppColors.authError, 1.5),
    errorStyle: AppTextStyles.authFieldError,
  );
}
