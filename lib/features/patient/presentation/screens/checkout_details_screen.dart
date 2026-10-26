import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../core/helpers/price_formatter.dart';
import '../../../../core/models/picked_location.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/widgets/app_custom_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../payment/presentation/cubit/coupon_cubit.dart';
import '../../../payment/presentation/widgets/coupon_box.dart';
import '../../domain/entities/cart_item.dart';
import '../cubit/checkout_cubit.dart';
import '../cubit/checkout_state.dart';
import '../widgets/patient_sub_screen_header.dart';

/// "أكمل طلبك": delivery, address, coupon and the summary of the order, then
/// "التالي" creates the order and pops with its id so the cart can move on to
/// the payment. The delivery fee is decided by the server once the order
/// exists, so it is not part of the total shown here.
class CheckoutDetailsScreen extends StatelessWidget {
  final List<CartItem> items;

  const CheckoutDetailsScreen({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<CheckoutCubit>()),
        BlocProvider(create: (_) => getIt<CouponCubit>()),
      ],
      child: _CheckoutDetailsView(items: items),
    );
  }
}

class _CheckoutDetailsView extends StatelessWidget {
  final List<CartItem> items;

  const _CheckoutDetailsView({required this.items});

  double get _itemsTotal => items.fold(0, (sum, item) => sum + item.lineTotal);

  Future<void> _pickLocationAndSubmit(BuildContext context) async {
    final cubit = context.read<CheckoutCubit>();
    final location = await Navigator.of(context).pushNamed<PickedLocation>(
      Routes.locationPickerScreen,
    );
    if (!context.mounted) return;
    if (location == null) return;
    await cubit.submitWithNewAddress(location);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocListener<CheckoutCubit, CheckoutState>(
          listener: (context, state) {
            switch (state) {
              case CheckoutNeedsAddress():
                _pickLocationAndSubmit(context);
              case CheckoutSuccess(:final orderId):
                Navigator.of(context).pop(orderId);
              case CheckoutFailure(:final message):
                AppSnackbar.show(context, message);
              case CheckoutIdle():
              case CheckoutInProgress():
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  children: [
                    const PatientSubScreenHeader(
                      title: 'أكمل طلبك',
                      description: 'راجع تفاصيل الطلب واختر طريقة الدفع والتوصيل.',
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      'التوصيل',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 18.sp, color: AppColors.onboardingText),
                    ),
                    SizedBox(height: 16.h),
                    const _DeliveryChoice(),
                    SizedBox(height: 16.h),
                    const _AddressRow(),
                    SizedBox(height: 16.h),
                    CouponBox(orderTotal: _itemsTotal),
                    SizedBox(height: 16.h),
                    _OrderSummary(items: items),
                    SizedBox(height: 16.h),
                    _Totals(itemsTotal: _itemsTotal),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
                child: BlocBuilder<CheckoutCubit, CheckoutState>(
                  builder: (context, state) {
                    return AppCustomButton(
                      text: 'التالي',
                      isLoading: state is CheckoutInProgress,
                      onPressed: () {
                        final checkout = context.read<CheckoutCubit>();
                        checkout.couponCode = context.read<CouponCubit>().appliedCode;
                        checkout.start();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Delivery is the only option the API documents; picking up at the pharmacy
/// has no contract yet, so it answers "قريباً".
class _DeliveryChoice extends StatelessWidget {
  const _DeliveryChoice();

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, {required bool selected, VoidCallback? onTap}) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 40.h,
            decoration: BoxDecoration(
              color: selected ? AppColors.mainTeal : AppColors.permissionIconBg,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: selected ? Colors.white : AppColors.authInputBorder,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(
                  Icons.delivery_dining_outlined,
                  size: 22.sp,
                  color: selected ? Colors.white : AppColors.authInputBorder,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip('دليفري', selected: true),
        SizedBox(width: 16.w),
        chip(
          'استلام من الصيدلية',
          selected: false,
          onTap: () => AppSnackbar.show(context, 'قريباً'),
        ),
      ],
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Text('العنوان', style: TextStyle(fontSize: 16.sp, color: AppColors.onboardingText)),
          const Spacer(),
          Text('عنوانك الحالي', style: TextStyle(fontSize: 12.sp, color: AppColors.authTextMuted)),
        ],
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  final List<CartItem> items;

  const _OrderSummary({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ملخص الطلب',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 18.sp, color: AppColors.onboardingText),
          ),
          SizedBox(height: 16.h),
          for (final item in items)
            Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${item.medicineName}/ ',
                          style: TextStyle(fontSize: 14.sp, color: AppColors.onboardingText),
                        ),
                        TextSpan(
                          text: item.pharmacyName,
                          style: TextStyle(fontSize: 12.sp, color: AppColors.authTextMuted),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${formatPrice(item.price)} \$/الشريط × ${item.quantity} = ${formatPrice(item.lineTotal)} \$',
                    style: TextStyle(fontSize: 12.sp, color: AppColors.authInputBorder),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  final double itemsTotal;

  const _Totals({required this.itemsTotal});

  @override
  Widget build(BuildContext context) {
    final rowStyle = TextStyle(fontSize: 14.sp, color: AppColors.onboardingText);
    return BlocBuilder<CouponCubit, CouponState>(
      builder: (context, coupon) {
        final discount = coupon.appliedCode == null ? null : coupon.discount;
        final total = (itemsTotal - (discount ?? 0)).clamp(0, double.infinity);
        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('سعر الطلبات : \$${formatPrice(itemsTotal)}', style: rowStyle),
              SizedBox(height: 8.h),
              Text('دليفري : يُحسب بعد تأكيد الطلب', style: rowStyle),
              if (discount != null) ...[
                SizedBox(height: 8.h),
                Text('الخصم : \$${formatPrice(discount)}', style: rowStyle),
              ],
              SizedBox(height: 8.h),
              Text(
                'الإجمالي : \$${formatPrice(total.toDouble())}',
                style: TextStyle(fontSize: 20.sp, color: AppColors.onboardingText),
              ),
            ],
          ),
        );
      },
    );
  }
}
