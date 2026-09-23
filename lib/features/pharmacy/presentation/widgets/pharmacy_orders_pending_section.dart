import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_snackbar.dart';

/// The "الطلبات" section on the pharmacy home screen. There is no orders
/// API yet, so this only reserves the section's place in the layout with a
/// "coming soon" placeholder instead of fabricating order data — replace
/// this with a real list once an orders endpoint exists.
class PharmacyOrdersPendingSection extends StatelessWidget {
  const PharmacyOrdersPendingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            TextButton(
              onPressed: () => AppSnackbar.show(context, 'قريباً'),
              child: Text(
                'عرض الكل',
                style: TextStyle(
                  color: AppColors.mainTeal,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.sp,
                ),
              ),
            ),
            const Spacer(),
            Text(
              'الطلبات',
              style: AppTextStyles.cardTitle.copyWith(fontSize: 16.sp),
              textAlign: TextAlign.right,
            ),
          ],
        ),
        SizedBox(height: 12.h),
        AppCard(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: Center(
            child: Text('ميزة الطلبات قريباً', style: AppTextStyles.cardDescription),
          ),
        ),
      ],
    );
  }
}
