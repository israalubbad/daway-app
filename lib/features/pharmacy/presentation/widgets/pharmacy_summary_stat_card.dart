import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_text_styles.dart';

/// One of the two large cards at the top of the pharmacy home screen
/// (إجمالي المبيعات الشهرية / إجمالي المنتجات) — a label, a big number, and
/// an optional trailing arrow that drills into that stat's own screen.
class PharmacySummaryStatCard extends StatelessWidget {
  final String label;
  final String value;
  final bool showArrow;
  final VoidCallback? onTap;

  const PharmacySummaryStatCard({
    super.key,
    required this.label,
    required this.value,
    this.showArrow = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 133.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 17.h),
        decoration: BoxDecoration(
          color: AppColors.permissionIconBg,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppColors.iconBlueBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.pharmacySummaryCardLabel,
            ),
            Expanded(
              child: Center(
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.pharmacySummaryCardValue,
                ),
              ),
            ),
            if (showArrow)
              Align(
                alignment: Alignment.centerLeft,
                child: Icon(
                  Icons.arrow_back,
                  size: 18.sp,
                  color: AppColors.mainTeal,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
