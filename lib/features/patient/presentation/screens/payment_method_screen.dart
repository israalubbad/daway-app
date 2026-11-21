import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../core/helpers/price_formatter.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_fonts.dart';
import '../../../../core/theming/app_text_styles.dart';
import '../../../../core/widgets/app_custom_button.dart';
import '../../../../core/widgets/profile_load_error.dart';
import '../../domain/entities/checkout_flow.dart';
import '../cubit/payment_cubit.dart';
import '../cubit/payment_state.dart';
import '../widgets/patient_sub_screen_header.dart';
import 'order_confirmation_screen.dart';
import 'payment_receipt_screen.dart';

import '../../../../core/localization/translations.dart';

/// "طريقة الدفع" — the banks / wallets the order's total can be transferred
/// to, as listed by the server, and the amount to pay.
class PaymentMethodScreen extends StatelessWidget {
  final int orderId;
  final String pharmacyName;

  const PaymentMethodScreen({
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
          PaymentMethodScreen(orderId: orderId, pharmacyName: pharmacyName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PaymentCubit>(param1: orderId)..startPolling(),
      child: _PaymentMethodView(orderId: orderId, pharmacyName: pharmacyName),
    );
  }
}

class _PaymentMethodView extends StatelessWidget {
  final int orderId;
  final String pharmacyName;

  const _PaymentMethodView({required this.orderId, required this.pharmacyName});

  void _pay(BuildContext context, PaymentReady state) {
    final cubit = context.read<PaymentCubit>();
    // A receipt is already under review: nothing more to pay for.
    if (!state.payment.canSubmitReceipt) {
      Navigator.of(context).pushAndRemoveUntil(
        OrderConfirmationScreen.route(
          orderId: orderId,
          pharmacyName: pharmacyName,
        ),
        (route) => route.isFirst,
      );
      return;
    }
    Navigator.of(context).push(
      PaymentReceiptScreen.route(cubit: cubit, pharmacyName: pharmacyName),
    );
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
              child: BlocListener<PaymentCubit, PaymentState>(
                // An order that is already paid (or whose receipt is already in)
                // has nothing to pay: show where it stands instead.
                listenWhen: (previous, current) =>
                    _isSettled(current) && !_isSettled(previous),
                listener: (context, state) =>
                    Navigator.of(context).pushReplacement(
                      OrderConfirmationScreen.route(
                        orderId: orderId,
                        pharmacyName: pharmacyName,
                      ),
                    ),
                child: BlocBuilder<PaymentCubit, PaymentState>(
                  builder: (context, state) => switch (state) {
                    PaymentLoading() => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    PaymentLoadFailure(:final message) => ProfileLoadError(
                      message: message,
                      onRetry: () => context.read<PaymentCubit>().load(),
                    ),
                    PaymentReady() => _buildReady(context, state),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static bool _isSettled(PaymentState state) =>
      state is PaymentReady &&
      !state.awaitingAdmin &&
      (state.payment.isApproved || !state.payment.canSubmitReceipt);

  Widget _buildReady(BuildContext context, PaymentReady state) {
    if (state.awaitingAdmin) {
      return _AwaitingAdmin(
        onRefresh: () => context.read<PaymentCubit>().refresh(),
      );
    }
    final cubit = context.read<PaymentCubit>();
    final banks = state.payment.banks;
    final fee = state.payment.deliveryFee;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 24.h),
                _PriceCard(
                  deliveryFee: fee,
                  grandTotal: state.payment.grandTotal,
                ),
                SizedBox(height: 24.h),
                Text(
                  'طريقة الدفع'.tr,
                  textAlign: TextAlign.start,
                  style: AppTextStyles.profileFieldLabel,
                ),
                SizedBox(height: 16.h),
                if (banks.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.h),
                    child: Text(
                      'لا توجد طرق دفع متاحة حالياً'.tr,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.emptyStateSubtitle,
                    ),
                  ),
                for (final bank in banks) ...[
                  BankOptionCard(
                    bank: bank,
                    selected: bank.id == state.selectedBankId,
                    onTap: () => cubit.selectBank(bank.id),
                  ),
                  SizedBox(height: 16.h),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 24.h),
          child: AppCustomButton(
            text: state.payment.canSubmitReceipt
                ? 'ادفع {0} \$'.trArgs([formatPrice(state.payment.grandTotal)])
                : 'تتبع الطلب'.tr,
            onPressed: () => _pay(context, state),
          ),
        ),
      ],
    );
  }
}

/// A bank / wallet row, 100 tall: its logo, name and account (or phone)
/// number, and a 24×24 radio at the far end.
class BankOptionCard extends StatelessWidget {
  final PaymentBank bank;
  final bool selected;
  final VoidCallback onTap;

  const BankOptionCard({
    super.key,
    required this.bank,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 100.h,
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.permissionIconBg : Colors.white,
          border: Border.all(
            color: selected ? AppColors.iconBlueBorder : AppColors.cardBorder,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            BankLogo(name: bank.name),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bank.name,
                    style: AppFonts.tajawal(
                      TextStyle(
                        fontSize: 14.sp,
                        height: 21 / 14,
                        color: AppColors.onboardingText,
                      ),
                      FontWeight.w500,
                    ),
                  ),
                  if (bank.accountNumber.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Text(
                      bank.accountNumber,
                      textDirection: TextDirection.ltr,
                      style: AppFonts.tajawal(
                        TextStyle(
                          fontSize: 12.sp,
                          height: 18 / 12,
                          color: AppColors.paymentLabelText,
                        ),
                        FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              width: 24.r,
              height: 24.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.mainTeal : Colors.white,
                border: Border.all(color: AppColors.iconBlueBorder, width: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The logo of a known payment method (matched on its name), or the name's
/// first letter for one without a logo of its own.
class BankLogo extends StatelessWidget {
  final String name;

  const BankLogo({super.key, required this.name});

  /// The logo for a payment method known by name. Spaces, case and the
  /// Latin / Arabic spellings are ignored, since the name is typed by the admin.
  static String? assetFor(String name) {
    final key = name.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    if (key.contains('فلسطين') ||
        key.contains('palestine') ||
        key.contains('bop')) {
      return 'assets/images/banks/bank_of_palestine.png';
    }
    if (key.contains('بالباي') || key.contains('palpay')) {
      return 'assets/images/banks/palpay.png';
    }
    if (key.contains('جوال') ||
        key.contains('jawwal') ||
        key.contains('jawal')) {
      return 'assets/images/banks/jawwal_pay.png';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final asset = assetFor(name);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.r),
      child: SizedBox(
        width: 64.r,
        height: 64.r,
        child: asset != null
            ? Image.asset(asset, fit: BoxFit.cover)
            : ColoredBox(
                color: AppColors.permissionIconBg,
                child: Center(
                  child: Text(
                    name.trim().isEmpty ? '؟'.tr : name.trim().characters.first,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mainTeal,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

/// Shown after the order is sent, until the admin has priced the delivery and
/// approved the order. Nothing can be paid before that, so no banks are listed;
/// the screen re-checks by itself (see PaymentCubit.startPolling).
class _AwaitingAdmin extends StatelessWidget {
  final VoidCallback onRefresh;

  const _AwaitingAdmin({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 64.r,
            height: 64.r,
            decoration: const BoxDecoration(
              color: AppColors.uploadIconCircle,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.hourglass_top_rounded,
              color: AppColors.mainTeal,
              size: 28.sp,
            ),
          ),
          SizedBox(height: 24.h),
          Text('بانتظار موافقة الأدمن'.tr, style: AppTextStyles.emptyStateTitle),
          SizedBox(height: 12.h),
          Text(
            'سيحدد الأدمن سعر التوصيل ويوافق على طلبك، وبعدها تتمكن من الدفع. نحدّث هذه الصفحة تلقائياً.'.tr,
            textAlign: TextAlign.center,
            style: AppTextStyles.emptyStateSubtitle,
          ),
          const Spacer(),
          AppCustomButton(text: 'تحديث'.tr, onPressed: onRefresh),
          SizedBox(height: 8.h),
          AppCustomButton(
            text: 'العودة للرئيسية'.tr,
            backgroundColor: Colors.white,
            textColor: AppColors.onboardingText,
            borderColor: AppColors.cardBorder,
            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
              Routes.patientHomeScreen,
              (route) => false,
            ),
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }
}

/// The price the admin set for the delivery, and what the order comes to with
/// it — shown before the patient picks how to pay.
class _PriceCard extends StatelessWidget {
  final double? deliveryFee;
  final double grandTotal;

  const _PriceCard({required this.deliveryFee, required this.grandTotal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (deliveryFee != null) ...[
            Text(
              'سعر التوصيل : {0} \$'.trArgs([formatPrice(deliveryFee!)]),
              textAlign: TextAlign.start,
              style: AppTextStyles.cartItemPrice,
            ),
            SizedBox(height: 8.h),
          ],
          Text(
            'الإجمالي : {0} \$'.trArgs([formatPrice(grandTotal)]),
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
