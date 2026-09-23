import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_text_styles.dart';

/// One of the four small cards on the pharmacy home screen (التقييمات /
/// نافذ / مخزون منخفض / متوفرة) — a number over a category-colored label,
/// tinted with a faint wash of [categoryColor].
class PharmacyMiniStatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color categoryColor;
  final VoidCallback? onTap;

  const PharmacyMiniStatCard({
    super.key,
    required this.value,
    required this.label,
    required this.categoryColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 76.h,
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: categoryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12.r),
          border: Border(
            top: BorderSide(color: AppColors.cardBorder, width: 0.8),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.pharmacyMiniStatValue,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.miniStatLabel(categoryColor),
            ),
          ],
        ),
      ),
    );
  }
}
