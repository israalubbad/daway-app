import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/widgets/profile_load_error.dart';
import '../../../patient/presentation/widgets/patient_sub_screen_header.dart';
import '../cubit/tracking_cubit.dart';

/// "تتبع الطلب": the status timeline of the order, newest step last.
class OrderTrackingScreen extends StatelessWidget {
  final int orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  static String statusLabel(String status) => switch (status) {
        'pending' => 'قيد الانتظار',
        'confirmed' => 'تم تأكيد الطلب',
        'preparing' => 'قيد التجهيز',
        'out_for_delivery' => 'في الطريق إليك',
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
                  PatientSubScreenHeader(
                    title: 'تتبع الطلب',
                    description: 'الحالة الحالية: ${statusLabel(tracking.status)}',
                  ),
                  SizedBox(height: 24.h),
                  for (final step in tracking.steps)
                    Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: AppColors.mainTeal, size: 22.sp),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              statusLabel(step.status),
                              style: TextStyle(fontSize: 15.sp, color: AppColors.textDark),
                            ),
                          ),
                          if (step.at != null)
                            Text(
                              '${step.at!.year}/${step.at!.month}/${step.at!.day}',
                              style: TextStyle(fontSize: 12.sp, color: AppColors.grey),
                            ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
