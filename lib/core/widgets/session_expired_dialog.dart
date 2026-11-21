import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theming/app_colors.dart';
import '../theming/app_text_styles.dart';

import '../../core/localization/translations.dart';

/// Blocking dialog telling the user their session ended. The only way out is
/// the button, which the caller turns into "go to login".
class SessionExpiredDialog extends StatelessWidget {
  const SessionExpiredDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SessionExpiredDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        child: Padding(
          padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'انتهت الجلسة'.tr,
                textAlign: TextAlign.center,
                style: AppTextStyles.confirmSheetTitle,
              ),
              SizedBox(height: 12.h),
              Text(
                'انتهت صلاحية جلستك، يرجى تسجيل الدخول مرة أخرى للمتابعة.'.tr,
                textAlign: TextAlign.center,
                style: AppTextStyles.confirmSheetMessage,
              ),
              SizedBox(height: 24.h),
              SizedBox(
                height: 52.h,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainTeal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: Text('إعادة تسجيل الدخول'.tr, style: AppTextStyles.sheetButtonLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
