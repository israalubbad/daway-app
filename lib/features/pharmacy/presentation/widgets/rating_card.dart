import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_fonts.dart';
import '../../../../core/theming/app_text_styles.dart';
import '../../domain/entities/rating.dart';

/// One review: the patient's name and star value on the first line, the
/// comment under them — a 1px #DCE6E9 card, radius 8, padding 12.
class RatingCard extends StatelessWidget {
  final Rating rating;

  const RatingCard({super.key, required this.rating});

  static const Color _badgeColor = Color(0xFFCAC842);

  @override
  Widget build(BuildContext context) {
    final comment = rating.comment;
    return Container(
      padding: EdgeInsets.all(12.r),
      constraints: BoxConstraints(minHeight: 106.h),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(top: 4.h, start: 8.w),
                  child: Text(
                    rating.patientName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                    style: AppFonts.tajawal(
                      TextStyle(
                        fontSize: 14.sp,
                        height: 21 / 14,
                        color: AppColors.onboardingText,
                      ),
                      FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: _badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  rating.stars.toStringAsFixed(1),
                  style: AppFonts.tajawal(
                    TextStyle(
                      fontSize: 12.sp,
                      height: 16.5 / 12,
                      color: _badgeColor,
                    ),
                    FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (comment != null && comment.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              comment,
              textAlign: TextAlign.start,
              style: AppTextStyles.cardDescription.copyWith(
                fontSize: 12.sp,
                color: AppColors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
