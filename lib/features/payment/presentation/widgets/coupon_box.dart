import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/helpers/price_formatter.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../cubit/coupon_cubit.dart';

/// "كود الخصم" on the cart: validates the code against the order total and
/// shows the discount the server quotes. The code is only sent along with
/// checkout once it has been accepted.
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
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _controller,
                    hintText: 'كود الخصم',
                    readOnly: applied,
                    textInputAction: TextInputAction.done,
                  ),
                ),
                SizedBox(width: 8.w),
                TextButton(
                  onPressed: state.isChecking
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
                          style: TextStyle(color: AppColors.mainTeal),
                        ),
                ),
              ],
            ),
            if (applied && state.discount != null) ...[
              SizedBox(height: 6.h),
              Text(
                'تم تطبيق الكود، الخصم: ${formatPrice(state.discount!)} \$',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 12.sp, color: AppColors.mainTeal),
              ),
            ],
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
