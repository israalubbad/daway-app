import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/helpers/image_source_picker.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_fonts.dart';
import '../../../../core/theming/app_text_styles.dart';
import '../../../../core/widgets/app_custom_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../cubit/payment_cubit.dart';
import '../cubit/payment_state.dart';
import '../widgets/patient_sub_screen_header.dart';
import 'order_confirmation_screen.dart';

import '../../../../core/localization/translations.dart';

/// "ارفع اشعار التحويل" — the receipt picture of the transfer, or, for a
/// patient who cannot upload it, the transfer details typed in by hand.
class PaymentReceiptScreen extends StatefulWidget {
  final String pharmacyName;

  const PaymentReceiptScreen({super.key, required this.pharmacyName});

  /// Shares the [PaymentCubit] of the payment-method screen, so the chosen
  /// bank and the order's amount carry over.
  static Route<void> route({
    required PaymentCubit cubit,
    required String pharmacyName,
  }) {
    return MaterialPageRoute<void>(
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: PaymentReceiptScreen(pharmacyName: pharmacyName),
      ),
    );
  }

  @override
  State<PaymentReceiptScreen> createState() => _PaymentReceiptScreenState();
}

class _PaymentReceiptScreenState extends State<PaymentReceiptScreen> {
  late final TextEditingController _holderController;
  late final TextEditingController _amountController;
  File? _receipt;
  bool _hasProblem = false;
  String? _bankName;

  @override
  void initState() {
    super.initState();
    _holderController = TextEditingController();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _holderController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt() async {
    final file = await pickImageFromSourceSheet(context);
    if (file == null || !mounted) return;
    setState(() => _receipt = file);
  }

  Future<void> _submit() async {
    final cubit = context.read<PaymentCubit>();
    final String? error;
    if (_hasProblem) {
      final holder = _holderController.text.trim();
      final amount = double.tryParse(
        _amountController.text.trim().replaceAll(',', '.'),
      );
      if (_bankName == null ||
          holder.isEmpty ||
          amount == null ||
          amount <= 0) {
        AppSnackbar.show(context, 'أكمل بيانات التحويل أولاً'.tr);
        return;
      }
      error = await cubit.reportTransferDetails(
        bankName: _bankName!,
        accountHolder: holder,
        amount: amount,
      );
    } else {
      if (_receipt == null) {
        AppSnackbar.show(context, 'ارفع صورة إشعار التحويل أولاً'.tr);
        return;
      }
      error = await cubit.submitReceipt(_receipt!.path);
    }
    if (!mounted) return;
    if (error != null) {
      AppSnackbar.show(context, error);
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      OrderConfirmationScreen.route(
        orderId: cubit.orderId,
        pharmacyName: widget.pharmacyName,
      ),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<PaymentCubit, PaymentState>(
          builder: (context, state) {
            if (state is! PaymentReady) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: PatientSubScreenHeader(
                    title: 'ارفع اشعار التحويل'.tr,
                    description: 'ارفع صورة إشعار التحويل لتأكيد الدفع'.tr,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 24.h),
                        _SelectedMethod(name: state.selectedBank?.name ?? ''),
                        SizedBox(height: 56.h),
                        Text(
                          _hasProblem
                              ? 'اكتب بيانات التحويل لإتمام الطلب'.tr
                              : 'رفع إشعار الدفع'.tr,
                          textAlign: TextAlign.right,
                          style: _headingStyle,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          _hasProblem
                              ? 'أدخل بيانات التحويل يدويًا بدلًا من رفع الإشعار.'.tr
                              : 'قم برفع صورة إشعار التحويل لتأكيد عملية الدفع.'.tr,
                          textAlign: TextAlign.right,
                          style: _bodyStyle,
                        ),
                        SizedBox(height: 16.h),
                        if (_hasProblem)
                          _ManualFields(
                            bankNames: [
                              for (final bank in state.payment.banks) bank.name,
                            ],
                            bankName: _bankName,
                            onBankChanged: (value) =>
                                setState(() => _bankName = value),
                            holderController: _holderController,
                            amountController: _amountController,
                          )
                        else
                          _UploadArea(file: _receipt, onTap: _pickReceipt),
                        SizedBox(height: 16.h),
                        _ProblemToggle(
                          value: _hasProblem,
                          onChanged: (value) =>
                              setState(() => _hasProblem = value),
                        ),
                        SizedBox(height: 16.h),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 24.h),
                  child: AppCustomButton(
                    text: 'إتمام الطلب'.tr,
                    isLoading: state.isSubmitting,
                    onPressed: _submit,
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

TextStyle get _headingStyle => AppFonts.tajawal(
  TextStyle(fontSize: 18.sp, height: 27 / 18, color: AppColors.onboardingText),
  FontWeight.w500,
);

TextStyle get _bodyStyle => AppFonts.tajawal(
  TextStyle(
    fontSize: 14.sp,
    height: 22.4 / 14,
    color: AppColors.paymentLabelText,
  ),
  FontWeight.w400,
);

/// "طريقة الدفع المختارة": 64 tall, the bank's name under a muted caption,
/// and the card mark at the end.
class _SelectedMethod extends StatelessWidget {
  final String name;

  const _SelectedMethod({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 64.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.permissionIconBg,
        border: Border.all(color: AppColors.iconBlueBorder),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'طريقة الدفع المختارة'.tr,
                style: AppFonts.tajawal(
                  TextStyle(
                    fontSize: 12.sp,
                    height: 18 / 12,
                    color: AppColors.paymentLabelText,
                  ),
                  FontWeight.w400,
                ),
              ),
              Text(
                name,
                style: AppFonts.tajawal(
                  TextStyle(
                    fontSize: 14.sp,
                    height: 21 / 14,
                    color: AppColors.onboardingText,
                  ),
                  FontWeight.w500,
                ),
              ),
            ],
          ),
          SvgPicture.asset(
            'assets/icons/payment_card_icon.svg',
            width: 20.r,
            height: 20.r,
          ),
        ],
      ),
    );
  }
}

/// The receipt drop area: 259 tall, dashed 2px border, 24 padding, the upload
/// mark in a 64 circle with 8 between it and the texts.
class _UploadArea extends StatelessWidget {
  final File? file;
  final VoidCallback onTap;

  const _UploadArea({required this.file, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: const _DashedBorderPainter(color: AppColors.iconBlueBorder),
        child: Container(
          height: 259.h,
          padding: EdgeInsets.all(24.r),
          decoration: BoxDecoration(
            color: AppColors.permissionIconBg,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: file != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(6.r),
                  child: Image.file(
                    file!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64.r,
                      height: 64.r,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.uploadIconCircle,
                        shape: BoxShape.circle,
                      ),
                      child: SvgPicture.asset(
                        'assets/icons/upload_icon.svg',
                        width: 28.r,
                        height: 28.r,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'اضغط لرفع إشعار التحويل'.tr,
                      style: AppFonts.tajawal(
                        TextStyle(
                          fontSize: 14.sp,
                          height: 22.4 / 14,
                          color: AppColors.onboardingText,
                        ),
                        FontWeight.w400,
                      ),
                    ),
                    Text(
                      'PNG أو JPG'.tr,
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
                ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;

  const _DashedBorderPainter({required this.color});

  static const _dash = 10.0;
  static const _gap = 8.03;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + _dash), paint);
        distance += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _ProblemToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ProblemToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 56.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: value ? AppColors.permissionIconBg : Colors.white,
          border: Border.all(
            color: value ? AppColors.iconBlueBorder : AppColors.cardBorder,
            width: 1.03,
          ),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'لديك مشكلة في رفع الإشعار؟'.tr,
                style: AppTextStyles.cartItemPharmacyName,
              ),
            ),
            Icon(
              value ? Icons.check_box : Icons.check_box_outline_blank,
              color: value ? AppColors.mainTeal : AppColors.cardBorder,
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualFields extends StatelessWidget {
  final List<String> bankNames;
  final String? bankName;
  final ValueChanged<String?> onBankChanged;
  final TextEditingController holderController;
  final TextEditingController amountController;

  const _ManualFields({
    required this.bankNames,
    required this.bankName,
    required this.onBankChanged,
    required this.holderController,
    required this.amountController,
  });

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      fontSize: 12.sp,
      color: AppColors.productSecondaryText,
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.r),
      borderSide: const BorderSide(color: AppColors.cardBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.r),
      borderSide: const BorderSide(color: AppColors.mainTeal),
    ),
  );

  Widget _label(String text) => Padding(
    padding: EdgeInsets.only(top: 16.h, bottom: 8.h),
    child: Text(text, textAlign: TextAlign.right, style: _bodyStyle),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label('اسم البنك'.tr),
        DropdownButtonFormField<String>(
          initialValue: bankName,
          isExpanded: true,
          decoration: _decoration('اختر البنك'.tr),
          items: [
            for (final name in bankNames)
              DropdownMenuItem(value: name, child: Text(name)),
          ],
          onChanged: onBankChanged,
        ),
        _label('اسم صاحب الحساب'.tr),
        TextField(
          controller: holderController,
          textAlign: TextAlign.right,
          decoration: _decoration('أدخل اسم صاحب الحساب'.tr),
        ),
        _label('المبلغ'.tr),
        TextField(
          controller: amountController,
          textAlign: TextAlign.right,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _decoration('أدخل مبلغ التحويل'.tr),
        ),
      ],
    );
  }
}
