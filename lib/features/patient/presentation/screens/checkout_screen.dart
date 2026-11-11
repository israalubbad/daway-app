import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../core/helpers/api_result.dart';
import '../../../../core/helpers/price_formatter.dart';
import '../../../../core/models/picked_location.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_text_styles.dart';
import '../../../../core/widgets/app_custom_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/profile_load_error.dart';
import '../../domain/entities/cart_item.dart';
import '../cubit/checkout_cubit.dart';
import '../cubit/checkout_state.dart';
import '../widgets/patient_sub_screen_header.dart';
import 'payment_method_screen.dart';

import '../../../../core/localization/translations.dart';

/// "أكمل طلبك" — delivery address, coupon and the order summary, before the
/// order is created and paid. [items] are the cart lines being ordered (all
/// from one pharmacy: see the cart screen).
class CheckoutScreen extends StatelessWidget {
  final List<CartItem> items;

  const CheckoutScreen({super.key, required this.items});

  static Route<void> route(List<CartItem> items) =>
      MaterialPageRoute<void>(builder: (_) => CheckoutScreen(items: items));

  double get _subtotal => items.total;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CheckoutCubit>(param1: _subtotal),
      child: _CheckoutView(items: items),
    );
  }
}

class _CheckoutView extends StatefulWidget {
  final List<CartItem> items;

  const _CheckoutView({required this.items});

  @override
  State<_CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<_CheckoutView> {
  late final TextEditingController _couponController;

  @override
  void initState() {
    super.initState();
    _couponController = TextEditingController();
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  String get _pharmacyName =>
      widget.items.isEmpty ? '' : widget.items.first.pharmacyName;

  Future<void> _applyCoupon(BuildContext context) async {
    final error = await context.read<CheckoutCubit>().applyCoupon(
      _couponController.text,
    );
    if (!context.mounted) return;
    AppSnackbar.show(context, error ?? 'تم تطبيق كود الخصم'.tr);
  }

  void _removeCoupon(BuildContext context) {
    _couponController.clear();
    context.read<CheckoutCubit>().removeCoupon();
  }

  Future<void> _addAddress(BuildContext context) async {
    final cubit = context.read<CheckoutCubit>();
    final location = await Navigator.of(
      context,
    ).pushNamed<PickedLocation>(Routes.locationPickerScreen);
    if (location == null) return;
    final error = await cubit.addAddress(location);
    if (error != null && context.mounted) AppSnackbar.show(context, error);
  }

  Future<void> _chooseAddress(BuildContext context, CheckoutReady state) async {
    if (state.addresses.isEmpty) return _addAddress(context);
    final cubit = context.read<CheckoutCubit>();
    final picked = await showModalBottomSheet<int>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (_) => _AddressSheet(state: state),
    );
    if (picked == null) return;
    if (picked == _addNewAddress) {
      if (context.mounted) await _addAddress(context);
      return;
    }
    cubit.selectAddress(picked);
  }

  Future<void> _next(BuildContext context) async {
    final cubit = context.read<CheckoutCubit>();
    final result = await cubit.submit();
    if (result == null || !context.mounted) return;
    switch (result) {
      case Success(:final data):
        // The order now exists on the server and the cart is empty, so the cart
        // and this screen are dropped: going back from payment lands on the
        // home screen, and the order can be resumed from "طلباتي".
        Navigator.of(context).pushAndRemoveUntil(
          PaymentMethodScreen.route(orderId: data, pharmacyName: _pharmacyName),
          (route) => route.isFirst,
        );
      case ApiError(:final failure):
        AppSnackbar.show(context, failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: PatientSubScreenHeader(
                title: 'أكمل طلبك'.tr,
                description: 'راجع تفاصيل الطلب واختر طريقة الدفع والتوصيل.'.tr,
              ),
            ),
            Expanded(
              child: BlocBuilder<CheckoutCubit, CheckoutState>(
                builder: (context, state) => switch (state) {
                  CheckoutLoading() => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  CheckoutLoadFailure(:final message) => ProfileLoadError(
                    message: message,
                    onRetry: () => context.read<CheckoutCubit>().load(),
                  ),
                  CheckoutReady() => _buildReady(context, state),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReady(BuildContext context, CheckoutReady state) {
    final address = state.selectedAddress;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 24.h),
                Text(
                  'التوصيل'.tr,
                  textAlign: TextAlign.start,
                  style: AppTextStyles.profileFieldLabel,
                ),
                SizedBox(height: 16.h),
                const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _DeliveryButton(),
                ),
                SizedBox(height: 16.h),
                _InfoCard(
                  label: 'العنوان'.tr,
                  onTap: () => _chooseAddress(context, state),
                  value: address == null
                      ? 'اختر عنوان التوصيل'.tr
                      : (address.address.isEmpty
                            ? address.label.tr
                            : address.address),
                ),
                SizedBox(height: 16.h),
                _CouponCard(
                  controller: _couponController,
                  appliedCode: state.couponCode,
                  isApplying: state.isApplyingCoupon,
                  onApply: () => _applyCoupon(context),
                  onRemove: () => _removeCoupon(context),
                ),
                SizedBox(height: 16.h),
                _SummaryCard(items: widget.items),
                SizedBox(height: 16.h),
                _TotalsCard(
                  state: state,
                  onRetryQuote: () => context.read<CheckoutCubit>().refreshQuote(),
                ),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 24.h),
          child: AppCustomButton(
            text: 'التالي'.tr,
            // Also held while the price is read: an order is only confirmed
            // against the total the patient can see.
            isLoading: state.isSubmitting || state.isQuoting,
            onPressed: () {
              if (state.selectedAddressId == null) {
                AppSnackbar.show(context, 'اختر عنوان التوصيل أولاً'.tr);
                return;
              }
              _next(context);
            },
          ),
        ),
      ],
    );
  }
}

const _addNewAddress = -1;

/// The one delivery method: 112×40, filled, with the helmet mark. Pickup from
/// the pharmacy is not offered (the backend has no such order type).
class _DeliveryButton extends StatelessWidget {
  const _DeliveryButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112.w,
      height: 40.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.mainTeal,
        borderRadius: BorderRadius.circular(7.r),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/icons/motorcycle_helmet_icon.svg',
              width: 24.r,
              height: 24.r,
            ),
            SizedBox(width: 10.w),
            Text(
              'دليفري'.tr,
              style: TextStyle(fontSize: 14.sp, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _InfoCard({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 56.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            Text(label, style: AppTextStyles.profileFieldLabel),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: TextStyle(fontSize: 12.sp, color: AppColors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  final TextEditingController controller;
  final String? appliedCode;
  final bool isApplying;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  const _CouponCard({
    required this.controller,
    required this.appliedCode,
    required this.isApplying,
    required this.onApply,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final applied = appliedCode != null;
    return Container(
      height: 56.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Text('كود الخصم'.tr, style: AppTextStyles.profileFieldLabel),
          SizedBox(width: 12.w),
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: applied,
              textAlign: TextAlign.end,
              textDirection: TextDirection.ltr,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onApply(),
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.onboardingText,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'أدخل الكود'.tr,
                hintStyle: TextStyle(fontSize: 12.sp, color: AppColors.grey),
              ),
            ),
          ),
          if (isApplying)
            SizedBox(
              width: 18.w,
              height: 18.w,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          else
            GestureDetector(
              onTap: applied ? onRemove : onApply,
              child: Text(
                applied ? 'إزالة'.tr : 'تطبيق'.tr,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: applied ? AppColors.logoutRed : AppColors.mainTeal,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final List<CartItem> items;

  const _SummaryCard({required this.items});

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
            'ملخص الطلب'.tr,
            textAlign: TextAlign.start,
            style: AppTextStyles.profileFieldLabel,
          ),
          for (final item in items) ...[
            SizedBox(height: 16.h),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${item.medicineName}/ ',
                    style: AppTextStyles.cartItemName,
                  ),
                  TextSpan(
                    text: item.pharmacyName,
                    style: AppTextStyles.cartItemPharmacyName,
                  ),
                ],
              ),
              textAlign: TextAlign.start,
            ),
            SizedBox(height: 6.h),
            Text(
              '{0} \$/ الشريط × {1} = {2} \$'.trArgs([formatPrice(item.price), item.quantity, formatPrice(item.lineTotal)]),
              textAlign: TextAlign.start,
              style: AppTextStyles.cartItemPharmacyName,
            ),
          ],
        ],
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  final CheckoutReady state;
  final VoidCallback onRetryQuote;

  const _TotalsCard({required this.state, required this.onRetryQuote});

  /// The delivery line: the server's fee once it is quoted, and otherwise why
  /// there is none — still being read, could not be read (tap to retry), or
  /// not priced up front (no address yet, or the server prices it later).
  Widget _deliveryLine() {
    final quote = state.quote;
    if (quote != null) {
      return Text(
        'دليفري : {0} \$'.trArgs([formatPrice(quote.deliveryFee.toDouble())]),
        textAlign: TextAlign.start,
        style: AppTextStyles.cartItemPrice,
      );
    }
    if (state.isQuoting) {
      return Text(
        'دليفري : جارٍ الحساب...'.tr,
        textAlign: TextAlign.start,
        style: AppTextStyles.cartItemPrice,
      );
    }
    if (state.quoteError != null) {
      return GestureDetector(
        onTap: onRetryQuote,
        behavior: HitTestBehavior.opaque,
        child: Text(
          'دليفري : تعذر حساب الرسوم، اضغط لإعادة المحاولة'.tr,
          textAlign: TextAlign.start,
          style: AppTextStyles.cartItemPrice.copyWith(color: AppColors.logoutRed),
        ),
      );
    }
    return Text(
      'دليفري : يحدده الأدمن بعد إرسال الطلب'.tr,
      textAlign: TextAlign.start,
      style: AppTextStyles.cartItemPrice,
    );
  }

  @override
  Widget build(BuildContext context) {
    final shownDiscount = state.shownDiscount;
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
            'سعر الطلبات : {0} \$'.trArgs([formatPrice(state.quote?.subtotal ?? state.subtotal)]),
            textAlign: TextAlign.start,
            style: AppTextStyles.cartItemPrice,
          ),
          SizedBox(height: 8.h),
          _deliveryLine(),
          if (shownDiscount > 0) ...[
            SizedBox(height: 8.h),
            Text(
              'الخصم : {0} \$'.trArgs([formatPrice(shownDiscount)]),
              textAlign: TextAlign.start,
              style: AppTextStyles.cartItemPrice,
            ),
          ],
          SizedBox(height: 12.h),
          Text(
            'الاجمالي : {0} \$'.trArgs([formatPrice(state.grandTotal)]),
            textAlign: TextAlign.start,
            style: AppTextStyles.profileFieldLabel.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressSheet extends StatelessWidget {
  final CheckoutReady state;

  const _AddressSheet({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 24.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'اختر عنوان التوصيل'.tr,
            textAlign: TextAlign.start,
            style: AppTextStyles.profileFieldLabel,
          ),
          SizedBox(height: 12.h),
          for (final address in state.addresses)
            ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: () => Navigator.of(context).pop(address.id),
              title: Text(address.label.tr, textAlign: TextAlign.start),
              subtitle: Text(
                address.address,
                textAlign: TextAlign.start,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Icon(
                address.id == state.selectedAddressId
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: AppColors.mainTeal,
              ),
            ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            onTap: () => Navigator.of(context).pop(_addNewAddress),
            title: Text(
              'إضافة عنوان جديد'.tr,
              textAlign: TextAlign.start,
              style: TextStyle(color: AppColors.mainTeal),
            ),
            trailing: Icon(
              Icons.add_location_alt_outlined,
              color: AppColors.mainTeal,
            ),
          ),
        ],
      ),
    );
  }
}
