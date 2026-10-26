import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/widgets/app_custom_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/profile_load_error.dart';
import '../../../patient/presentation/widgets/patient_sub_screen_header.dart';
import '../../domain/entities/payment.dart';
import '../cubit/tracking_cubit.dart';

/// "تتبع الطلب": the order and the steps it has been through. The server only
/// reports the status and its history, so the delivery estimate of the design
/// is not shown.
class OrderTrackingScreen extends StatelessWidget {
  final int orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  /// The steps of the design, in order, with the server status each stands for.
  static const steps = [
    TrackingStepSpec('confirmed', 'تم تأكيد طلبك', 'تم استلام طلبك من قبل الصيدلية'),
    TrackingStepSpec('preparing', 'تم استلام طلبك', 'جاري تجهيز الأدوية'),
    TrackingStepSpec('out_for_delivery', 'في الطريق إليك', 'المندوب في طريقه إليك'),
    TrackingStepSpec('delivered', 'تم تسليم طلبك بنجاح', null),
  ];

  static String statusLabel(String status) => switch (status) {
        'pending' => 'قيد الانتظار',
        'confirmed' => 'تم التأكيد',
        'preparing' => 'قيد التجهيز',
        'out_for_delivery' => 'جاري التوصيل',
        'delivered' => 'تم التسليم',
        'cancelled' => 'ملغي',
        _ => status,
      };

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TrackingCubit>(param1: orderId)..load(),
      child: Scaffold(
        body: SafeArea(
          child: BlocBuilder<TrackingCubit, TrackingState>(
            builder: (context, state) {
              final tracking = state.tracking;
              if (state.isLoading) return const Center(child: CircularProgressIndicator());
              if (tracking == null) {
                return ProfileLoadError(
                  message: state.error ?? 'تعذر تحميل تتبع الطلب',
                  onRetry: () => context.read<TrackingCubit>().load(),
                );
              }
              return ListView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                children: [
                  const PatientSubScreenHeader(
                    title: 'أكمل طلبك',
                    description: 'راجع تفاصيل الطلب واختر طريقة الدفع والتوصيل.',
                    showBackButton: false,
                  ),
                  SizedBox(height: 24.h),
                  _OrderHeader(orderId: orderId, status: tracking.status),
                  SizedBox(height: 16.h),
                  _Timeline(tracking: tracking),
                  SizedBox(height: 24.h),
                  AppCustomButton(
                    text: 'نبّهني عند اقتراب الطلب',
                    trailingIcon: Icons.notifications_none,
                    onPressed: () => AppSnackbar.show(context, 'قريباً'),
                  ),
                  SizedBox(height: 12.h),
                  AppCustomButton(
                    text: 'العودة للرئيسية',
                    backgroundColor: Colors.white,
                    textColor: AppColors.onboardingText,
                    borderColor: AppColors.cardBorder,
                    onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                      Routes.patientHomeScreen,
                      (_) => false,
                    ),
                  ),
                  SizedBox(height: 24.h),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class TrackingStepSpec {
  final String status;
  final String title;
  final String? subtitle;

  const TrackingStepSpec(this.status, this.title, this.subtitle);
}

class _OrderHeader extends StatelessWidget {
  final int orderId;
  final String status;

  const _OrderHeader({required this.orderId, required this.status});

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
            child: Icon(Icons.shopping_bag_outlined, color: AppColors.mainTeal, size: 22.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'طلب #$orderId',
              style: TextStyle(fontSize: 14.sp, color: AppColors.onboardingText),
            ),
          ),
          if (status.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.permissionIconBg,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Text(
                OrderTrackingScreen.statusLabel(status),
                style: TextStyle(fontSize: 12.sp, color: AppColors.mainTeal),
              ),
            ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  final OrderTracking tracking;

  const _Timeline({required this.tracking});

  static String _time(DateTime at) {
    final hour = at.hour % 12 == 0 ? 12 : at.hour % 12;
    final minute = at.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${at.hour < 12 ? 'ص' : 'م'}';
  }

  @override
  Widget build(BuildContext context) {
    const steps = OrderTrackingScreen.steps;
    final current = steps.indexWhere((s) => s.status == tracking.status);
    final last = steps.length - 1;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          if (tracking.status == 'cancelled')
            Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: Text(
                'تم إلغاء هذا الطلب',
                style: TextStyle(fontSize: 14.sp, color: AppColors.logoutRed),
              ),
            ),
          for (var i = 0; i < steps.length; i++)
            _TimelineRow(
              spec: steps[i],
              // The first step is reached as soon as the order is confirmed.
              done: current >= 0 && (i < current || current == last || (i == 0 && current >= 0)),
              isCurrent: current >= 1 && i == current && current != last,
              time: tracking.steps
                  .where((s) => s.status == steps[i].status && s.at != null)
                  .map((s) => _time(s.at!))
                  .firstOrNull,
              isLast: i == last,
            ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final TrackingStepSpec spec;
  final bool done;
  final bool isCurrent;
  final String? time;
  final bool isLast;

  const _TimelineRow({
    required this.spec,
    required this.done,
    required this.isCurrent,
    required this.time,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final reached = done || isCurrent;
    final subtitle = spec.subtitle;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done && !isCurrent ? AppColors.mainTeal : Colors.white,
                  border: Border.all(
                    color: reached ? AppColors.mainTeal : AppColors.cardBorder,
                    width: 2,
                  ),
                ),
                child: done && !isCurrent
                    ? Icon(Icons.check, color: Colors.white, size: 20.sp)
                    : isCurrent
                        ? Center(
                            child: Container(
                              width: 10.w,
                              height: 10.w,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.mainTeal,
                              ),
                            ),
                          )
                        : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: EdgeInsets.symmetric(vertical: 2.h),
                    color: done ? AppColors.mainTeal : AppColors.cardBorder,
                  ),
                ),
            ],
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 8.h, bottom: isLast ? 0 : 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    spec.title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: reached ? AppColors.onboardingText : AppColors.authInputBorder,
                    ),
                  ),
                  if (subtitle != null && reached) ...[
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12.sp, color: AppColors.authTextMuted),
                    ),
                  ],
                  if (time != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      time!,
                      style: TextStyle(fontSize: 12.sp, color: AppColors.mainTeal),
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
