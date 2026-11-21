import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../core/helpers/smart_date_formatter.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_text_styles.dart';
import '../../domain/entities/notification.dart';
import '../helpers/notification_display.dart';

/// One row of the pharmacy's notifications list, laid out like the patient's:
/// an icon box, a title/message/chip+time column and, while unread, a dot.
/// Full-bleed — the hairline divider under it runs edge to edge.
class PharmacyNotificationItem extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const PharmacyNotificationItem({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: notification.isRead
              ? null
              : AppColors.permissionIconBg.withValues(alpha: 0.6),
          border: Border(bottom: BorderSide(color: AppColors.authInputBorder, width: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40.w,
              height: 42.h,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.permissionIconBg,
                border: Border.all(color: AppColors.iconBlueBorder),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: SvgPicture.asset(
                notificationIconAssetFor(notification.type),
                width: 20.r,
                height: 20.r,
                colorFilter: const ColorFilter.mode(AppColors.mainTeal, BlendMode.srcIn),
              ),
            ),
            SizedBox(width: 11.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notificationTitleFor(notification.type),
                    textAlign: TextAlign.start,
                    style: AppTextStyles.notificationTitle,
                  ),
                  Text(
                    notification.message,
                    textAlign: TextAlign.start,
                    style: AppTextStyles.notificationBody,
                  ),
                  SizedBox(height: 7.h),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8.w,
                    runSpacing: 4.h,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppColors.permissionIconBg,
                          border: Border.all(color: AppColors.iconBlueBorder),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          notificationCategoryFor(notification.type),
                          style: AppTextStyles.notificationChip,
                        ),
                      ),
                      Text(
                        relativeTimeAr(notification.createdAt),
                        style: AppTextStyles.mutedCaption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!notification.isRead) ...[
              SizedBox(width: 8.w),
              Container(
                width: 8.r,
                height: 8.r,
                margin: EdgeInsets.only(top: 6.h),
                decoration: const BoxDecoration(
                  color: AppColors.mainTeal,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
