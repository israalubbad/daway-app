import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_text_styles.dart';
import '../../../../core/widgets/app_custom_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/profile_load_error.dart';
import '../../domain/entities/checkout_flow.dart';
import '../../domain/entities/order.dart';
import '../cubit/order_tracking_cubit.dart';

import '../../../../core/localization/translations.dart';

/// "تم تأكيد الطلب" — the order number and where the order is now.
class OrderConfirmationScreen extends StatelessWidget {
  final int orderId;
  final String pharmacyName;

  const OrderConfirmationScreen({
    super.key,
    required this.orderId,
    required this.pharmacyName,
  });

  static Route<void> route({
    required int orderId,
    required String pharmacyName,
  }) {
    return MaterialPageRoute<void>(
      builder: (_) =>
          OrderConfirmationScreen(orderId: orderId, pharmacyName: pharmacyName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OrderTrackingCubit>(param1: orderId),
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 32.h),
                Text(
                  'تم تأكيد طلبك'.tr,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.authScreenTitle,
                ),
                SizedBox(height: 8.h),
                Text(
                  'تابع حالة طلبك من هنا.'.tr,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.authScreenSubtitle,
                ),
                SizedBox(height: 24.h),
                Expanded(
                  child: SingleChildScrollView(
                    child: BlocBuilder<OrderTrackingCubit, OrderTrackingState>(
                      builder: (context, state) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _OrderHeader(
                            orderId: orderId,
                            pharmacyName: pharmacyName,
                            status: state is OrderTrackingLoaded
                                ? state.tracking.status
                                : null,
                            awaitingPayment:
                                state is OrderTrackingLoaded &&
                                !state.paymentApproved,
                          ),
                          SizedBox(height: 16.h),
                          switch (state) {
                            OrderTrackingLoading() => Padding(
                              padding: EdgeInsets.symmetric(vertical: 48.h),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            OrderTrackingFailure(:final message) =>
                              ProfileLoadError(
                                message: message,
                                onRetry: () =>
                                    context.read<OrderTrackingCubit>().load(),
                              ),
                            OrderTrackingLoaded(
                              :final tracking,
                              :final paymentApproved,
                            ) =>
                              _Timeline(
                                tracking: tracking,
                                paymentApproved: paymentApproved,
                              ),
                          },
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                AppCustomButton(
                  text: 'نبّهني عند اقتراب الطلب'.tr,
                  trailingIcon: Icons.notifications_none,
                  onPressed: () =>
                      AppSnackbar.show(context, 'سيصلك إشعار عند اقتراب طلبك'.tr),
                ),
                SizedBox(height: 8.h),
                AppCustomButton(
                  text: 'العودة للرئيسية'.tr,
                  backgroundColor: Colors.white,
                  textColor: AppColors.onboardingText,
                  borderColor: AppColors.cardBorder,
                  onPressed: () =>
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        Routes.patientHomeScreen,
                        (route) => false,
                      ),
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _statusLabel(OrderStatus status) => switch (status) {
  OrderStatus.pending => 'قيد المراجعة'.tr,
  OrderStatus.confirmed => 'تم التأكيد'.tr,
  OrderStatus.preparing => 'قيد التجهيز'.tr,
  OrderStatus.outForDelivery => 'في الطريق'.tr,
  OrderStatus.delivered => 'تم التسليم'.tr,
  OrderStatus.cancelled => 'ملغي'.tr,
};

class _OrderHeader extends StatelessWidget {
  final int orderId;
  final String pharmacyName;
  final OrderStatus? status;
  final bool awaitingPayment;

  const _OrderHeader({
    required this.orderId,
    required this.pharmacyName,
    required this.status,
    required this.awaitingPayment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: AppColors.permissionIconBg,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              color: AppColors.mainTeal,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pharmacyName.isNotEmpty)
                  Text(pharmacyName, style: AppTextStyles.cartItemPharmacyName),
                SizedBox(height: 4.h),
                Text('طلب #{0}'.trArgs([orderId]), style: AppTextStyles.cartItemName),
              ],
            ),
          ),
          if (status != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.permissionIconBg,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Text(
                awaitingPayment ? 'بانتظار تأكيد الدفع'.tr : _statusLabel(status!),
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTeal,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Step {
  final String title;
  final String? subtitle;
  final OrderStatus status;

  const _Step(this.title, this.subtitle, this.status);
}

// The stages of an order, in order; a step is done once the order has reached
// its status.
List<_Step> get _steps => [
  _Step(
    'تم تأكيد طلبك'.tr,
    'تم استلام طلبك من قبل الصيدلية'.tr,
    OrderStatus.confirmed,
  ),
  _Step('تم استلام طلبك'.tr, 'جاري تجهيز الأدوية'.tr, OrderStatus.preparing),
  _Step('في الطريق إليك'.tr, 'المندوب في طريقه إليك'.tr, OrderStatus.outForDelivery),
  _Step('تم تسليم طلبك بنجاح'.tr, null, OrderStatus.delivered),
];

const _progress = [
  OrderStatus.pending,
  OrderStatus.confirmed,
  OrderStatus.preparing,
  OrderStatus.outForDelivery,
  OrderStatus.delivered,
];

class _Timeline extends StatelessWidget {
  final OrderTracking tracking;

  final bool paymentApproved;

  const _Timeline({required this.tracking, required this.paymentApproved});

  bool _done(int index) {
    if (tracking.status.isCancelled) return false;
    // "تم تأكيد طلبك" is the admin approving the transfer.
    if (index == 0 && !paymentApproved) return false;
    final reached = _progress.indexOf(tracking.status);
    final status = _steps[index].status;
    return reached >= _progress.indexOf(status);
  }

  String? _time(int index) {
    final status = _steps[index].status;
    final at = tracking.timeOf(status);
    if (at == null) return null;
    final hour = at.hour % 12 == 0 ? 12 : at.hour % 12;
    return '$hour:${at.minute.toString().padLeft(2, '0')} ${at.hour < 12 ? 'ص' : 'م'}';
  }

  @override
  Widget build(BuildContext context) {
    // The step in progress is the first one not done yet.
    final current = List.generate(
      _steps.length,
      (i) => i,
    ).firstWhere((i) => !_done(i), orElse: () => -1);
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          for (var i = 0; i < _steps.length; i++)
            _TimelineRow(
              step: _steps[i],
              time: _time(i),
              done: _done(i),
              active: i == current && !tracking.status.isCancelled,
              isLast: i == _steps.length - 1,
            ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final _Step step;
  final String? time;
  final bool done;
  final bool active;
  final bool isLast;

  const _TimelineRow({
    required this.step,
    required this.time,
    required this.done,
    required this.active,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final highlighted = done || active;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 36.r,
                height: 36.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? AppColors.mainTeal : Colors.white,
                  border: Border.all(
                    color: highlighted
                        ? AppColors.mainTeal
                        : AppColors.cardBorder,
                    width: 1.03,
                  ),
                ),
                child: done
                    ? Icon(Icons.check, color: Colors.white, size: 20.sp)
                    : active
                    ? Center(
                        child: Container(
                          width: 10.w,
                          height: 10.w,
                          decoration: const BoxDecoration(
                            color: AppColors.mainTeal,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: done ? AppColors.mainTeal : AppColors.cardBorder,
                  ),
                ),
            ],
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: AppTextStyles.cartItemName.copyWith(
                      color: highlighted
                          ? AppColors.onboardingText
                          : AppColors.productSecondaryText,
                    ),
                  ),
                  if (step.subtitle != null && highlighted) ...[
                    SizedBox(height: 6.h),
                    Text(
                      step.subtitle!,
                      style: AppTextStyles.cartItemPharmacyName,
                    ),
                  ],
                  if (time != null) ...[
                    SizedBox(height: 6.h),
                    Text(
                      time!,
                      style: AppTextStyles.cartItemPharmacyName.copyWith(
                        color: AppColors.mainTeal,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
