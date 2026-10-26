import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../core/helpers/price_formatter.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/widgets/app_custom_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/profile_load_error.dart';
import '../../../patient/presentation/widgets/patient_sub_screen_header.dart';
import '../../domain/entities/payment.dart';
import '../cubit/payment_cubit.dart';
import '../widgets/bank_logo.dart';
import 'upload_receipt_screen.dart';

/// "طريقة الدفع": the banks and wallets the patient can transfer to, then
/// "ادفع X" with the amount of the server (never computed here).
class PaymentMethodScreen extends StatelessWidget {
  final int orderId;

  const PaymentMethodScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PaymentCubit>(param1: orderId)..load(),
      child: _PaymentMethodView(orderId: orderId),
    );
  }
}

class _PaymentMethodView extends StatefulWidget {
  final int orderId;

  const _PaymentMethodView({required this.orderId});

  @override
  State<_PaymentMethodView> createState() => _PaymentMethodViewState();
}

class _PaymentMethodViewState extends State<_PaymentMethodView> {
  int? _selectedBankId;

  void _pay(PaymentSummary summary) {
    final bank = summary.banks.where((b) => b.id == _selectedBankId).firstOrNull;
    if (bank == null) {
      AppSnackbar.show(context, 'اختر طريقة الدفع');
      return;
    }
    Navigator.of(context).pushNamed(
      Routes.uploadReceiptScreen,
      arguments: UploadReceiptArgs(orderId: widget.orderId, bank: bank),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<PaymentCubit, PaymentState>(
          builder: (context, state) {
            final summary = state.summary;
            if (state.isLoading && summary == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (summary == null) {
              return ProfileLoadError(
                message: state.loadError ?? 'تعذر تحميل بيانات الدفع',
                onRetry: () => context.read<PaymentCubit>().load(),
              );
            }
            final total = summary.grandTotal;
            return Column(
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
                      SizedBox(height: 32.h),
                      Text(
                        'طريقة الدفع',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 18.sp, color: AppColors.onboardingText),
                      ),
                      SizedBox(height: 16.h),
                      if (!summary.canSubmitReceipt)
                        _AlreadySent(orderId: widget.orderId)
                      else if (summary.banks.isEmpty)
                        Text(
                          'لا توجد طرق دفع متاحة حالياً',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14.sp, color: AppColors.grey),
                        )
                      else
                        for (final bank in summary.banks)
                          _BankOption(
                            bank: bank,
                            selected: bank.id == _selectedBankId,
                            onTap: () => setState(() => _selectedBankId = bank.id),
                          ),
                    ],
                  ),
                ),
                if (summary.canSubmitReceipt)
                  Padding(
                    padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 24.h),
                    child: AppCustomButton(
                      text: total == null ? 'ادفع' : 'ادفع \$${formatPrice(total)}',
                      onPressed: () => _pay(summary),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AlreadySent extends StatelessWidget {
  final int orderId;

  const _AlreadySent({required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'تم إرسال إشعار التحويل وهو قيد المراجعة من الإدارة.',
          textAlign: TextAlign.right,
          style: TextStyle(fontSize: 14.sp, color: AppColors.authTextMuted),
        ),
        SizedBox(height: 16.h),
        AppCustomButton(
          text: 'تتبع الطلب',
          onPressed: () =>
              Navigator.of(context).pushNamed(Routes.orderTrackingScreen, arguments: orderId),
        ),
      ],
    );
  }
}

class _BankOption extends StatelessWidget {
  final PaymentBank bank;
  final bool selected;
  final VoidCallback onTap;

  const _BankOption({required this.bank, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final detail = bank.accountNumber ?? bank.iban;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? AppColors.iconBlueBorder : AppColors.cardBorder,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            BankLogo(logoUrl: bank.logoUrl, size: 64.w),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bank.name,
                    style: TextStyle(fontSize: 14.sp, color: AppColors.onboardingText),
                  ),
                  if (detail != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      detail,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(fontSize: 14.sp, color: AppColors.authInputBorder),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              width: 24.w,
              height: 24.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.mainTeal : Colors.white,
                border: selected ? null : Border.all(color: AppColors.cardBorder),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
