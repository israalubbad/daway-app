import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theming/app_colors.dart';
import '../../domain/entities/order.dart';

import '../../../../core/localization/translations.dart';

(String, Color) _labelAndColor(OrderStatus status) => switch (status) {
      OrderStatus.pending => ('قيد الانتظار'.tr, AppColors.orderInProgressColor),
      OrderStatus.confirmed => ('تم التأكيد'.tr, AppColors.orderInProgressColor),
      OrderStatus.preparing => ('قيد التحضير'.tr, AppColors.orderInProgressColor),
      OrderStatus.outForDelivery => ('في الطريق'.tr, AppColors.orderInProgressColor),
      OrderStatus.delivered => ('تم التوصيل'.tr, AppColors.orderCompletedColor),
      OrderStatus.cancelled => ('ملغي'.tr, AppColors.orderCancelledColor),
    };

/// The small colored pill on an order card showing its status.
class OrderStatusBadge extends StatelessWidget {
  final OrderStatus status;

  const OrderStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = _labelAndColor(status);
    return Container(
      height: 24.h,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4.r),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
