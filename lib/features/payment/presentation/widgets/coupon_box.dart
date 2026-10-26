import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theming/app_colors.dart';
import '../cubit/coupon_cubit.dart';

/// "كود الخصم" on the checkout page: the label at the right, the code typed at
/// the left, then "تطبيق" to have the server check it against the order total.
/// The code is only sent with the order once it has been accepted.
class CouponBox extends StatefulWidget {
  final double orderTotal;

  const CouponBox({super.key, required this.orderTotal});

  @override
  State<CouponBox> createState() => _CouponBoxState();
}

class _CouponBoxState extends State<CouponBox> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CouponCubit, CouponState>(
      builder: (context, state) {
        final applied = state.appliedCode != null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              height: 56.h,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.cardBorder),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Text(
                    'كود الخصم',
                    style: TextStyle(fontSize: 16.sp, color: AppColors.onboardingText),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      readOnly: applied,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.left,
                      decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                      style: TextStyle(fontSize: 14.sp, color: AppColors.authTextMuted),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: state.isChecking
                        ? null
                        : () {
                            final cubit = context.read<CouponCubit>();
                            if (applied) {
                              cubit.remove();
                              _controller.clear();
                            } else {
                              cubit.apply(_controller.text, orderTotal: widget.orderTotal);
                            }
                          },
                    child: state.isChecking
                        ? SizedBox(
                            width: 18.w,
                            height: 18.w,
                            child: const CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            applied ? 'إزالة' : 'تطبيق',
                            style: TextStyle(fontSize: 14.sp, color: AppColors.mainTeal),
                          ),
                  ),
                ],
              ),
            ),
            if (state.error != null) ...[
              SizedBox(height: 6.h),
              Text(
                state.error!,
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 12.sp, color: AppColors.logoutRed),
              ),
            ],
          ],
        );
      },
    );
  }
}
