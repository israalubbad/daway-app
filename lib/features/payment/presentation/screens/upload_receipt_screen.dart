import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../core/helpers/image_source_picker.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/widgets/app_custom_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/dashed_border_box.dart';
import '../../../patient/presentation/widgets/patient_sub_screen_header.dart';
import '../../domain/entities/payment.dart';
import '../cubit/payment_cubit.dart';

class UploadReceiptArgs {
  final int orderId;
  final PaymentBank bank;

  const UploadReceiptArgs({required this.orderId, required this.bank});
}

/// "ارفع اشعار التحويل": the receipt photo of the transfer, or its details
/// typed by hand. Sending only puts the payment under review.
class UploadReceiptScreen extends StatelessWidget {
  final UploadReceiptArgs args;

  const UploadReceiptScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PaymentCubit>(param1: args.orderId)..load(),
      child: _UploadReceiptView(args: args),
    );
  }
}

class _UploadReceiptView extends StatefulWidget {
  final UploadReceiptArgs args;

  const _UploadReceiptView({required this.args});

  @override
  State<_UploadReceiptView> createState() => _UploadReceiptViewState();
}

class _UploadReceiptViewState extends State<_UploadReceiptView> {
  late final TextEditingController _holder;
  late final TextEditingController _amount;
  File? _receipt;
  bool _manual = false;
  late int _manualBankId;

  @override
  void initState() {
    super.initState();
    _holder = TextEditingController();
    _amount = TextEditingController();
    _manualBankId = widget.args.bank.id;
  }

  @override
  void dispose() {
    _holder.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt() async {
    final file = await pickImageFromSourceSheet(context);
    if (file != null && mounted) setState(() => _receipt = file);
  }

  void _submit(PaymentState state) {
    final summary = state.summary;
    if (summary == null) return;
    final cubit = context.read<PaymentCubit>();
    final reference = 'DAWAY-${widget.args.orderId}';

    if (_manual) {
      final holder = _holder.text.trim();
      final amount = double.tryParse(_amount.text.trim().replaceAll(',', '.'));
      if (holder.isEmpty) return AppSnackbar.show(context, 'أدخل اسم صاحب الحساب');
      if (amount == null || amount <= 0) return AppSnackbar.show(context, 'أدخل مبلغ التحويل');
      cubit.submitReceipt(
        bankId: _manualBankId,
        amount: amount,
        senderName: holder,
        transferReference: reference,
        receipt: _receipt,
      );
      return;
    }

    final total = summary.grandTotal;
    final sender = state.patientName;
    if (_receipt == null) return AppSnackbar.show(context, 'أرفق صورة إشعار التحويل');
    if (total == null) return AppSnackbar.show(context, 'تعذر تحديد المبلغ، أعد تحميل الصفحة');
    if (sender == null) return AppSnackbar.show(context, 'تعذر تحديد اسم المحوِّل، حاول مرة أخرى');
    cubit.submitReceipt(
      bankId: widget.args.bank.id,
      amount: total,
      senderName: sender,
      transferReference: reference,
      receipt: _receipt,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<PaymentCubit, PaymentState>(
          listenWhen: (previous, current) =>
              previous.messageId != current.messageId || previous.submitted != current.submitted,
          listener: (context, state) {
            if (state.submitted) {
              Navigator.of(context).pushReplacementNamed(
                Routes.orderTrackingScreen,
                arguments: widget.args.orderId,
              );
            } else if (state.message != null) {
              AppSnackbar.show(context, state.message!);
            }
          },
          builder: (context, state) {
            final banks = state.summary?.banks ?? [widget.args.bank];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    children: [
                      const PatientSubScreenHeader(
                        title: 'ارفع اشعار التحويل',
                        description: 'ارفع صورة إشعار التحويل لتأكيد الدفع',
                      ),
                      SizedBox(height: 32.h),
                      _SelectedBank(bank: widget.args.bank),
                      SizedBox(height: 32.h),
                      Text(
                        _manual ? 'اكتب بيانات التحويل لإتمام الطلب' : 'رفع إشعار الدفع',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 16.sp, color: AppColors.onboardingText),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        _manual
                            ? 'أدخل بيانات التحويل يدويًا بدلاً من رفع إشعار الدفع.'
                            : 'قم برفع صورة إشعار التحويل لتأكيد عملية الدفع.',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 12.sp, color: AppColors.authInputBorder),
                      ),
                      SizedBox(height: 16.h),
                      if (!_manual)
                        _UploadBox(file: _receipt, onTap: _pickReceipt)
                      else
                        _ManualFields(
                          banks: banks,
                          bankId: _manualBankId,
                          onBankChanged: (id) => setState(() => _manualBankId = id),
                          holder: _holder,
                          amount: _amount,
                        ),
                      SizedBox(height: 16.h),
                      _ProblemToggle(
                        value: _manual,
                        onChanged: (v) => setState(() => _manual = v),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 24.h),
                  child: AppCustomButton(
                    text: 'إتمام الطلب',
                    isLoading: state.isBusy,
                    onPressed: () => _submit(state),
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

class _SelectedBank extends StatelessWidget {
  final PaymentBank bank;

  const _SelectedBank({required this.bank});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.permissionIconBg,
        border: Border.all(color: AppColors.iconBlueBorder),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'طريقة الدفع المختارة',
                  style: TextStyle(fontSize: 12.sp, color: AppColors.authInputBorder),
                ),
                SizedBox(height: 2.h),
                Text(
                  bank.name,
                  style: TextStyle(fontSize: 16.sp, color: AppColors.onboardingText),
                ),
              ],
            ),
          ),
          Icon(Icons.credit_card_outlined, color: AppColors.mainTeal, size: 24.sp),
        ],
      ),
    );
  }
}

class _UploadBox extends StatelessWidget {
  final File? file;
  final VoidCallback onTap;

  const _UploadBox({required this.file, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DashedBorderBox(
        color: AppColors.iconBlueBorder,
        backgroundColor: AppColors.permissionIconBg,
        radius: 8.r,
        strokeWidth: 2,
        dashLength: 6,
        gapLength: 6,
        child: SizedBox(
          height: 260.h,
          width: double.infinity,
          child: file != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: Image.file(file!, fit: BoxFit.cover),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64.w,
                      height: 64.w,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFE1EEF6),
                      ),
                      child: Center(
                        child: SvgPicture.asset('assets/icons/upload_icon.svg', width: 28.w),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'اضغط لرفع إشعار التحويل',
                      style: TextStyle(fontSize: 14.sp, color: AppColors.onboardingText),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'PNG, JPG',
                      style: TextStyle(fontSize: 12.sp, color: AppColors.authInputBorder),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ProblemToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ProblemToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: value ? AppColors.permissionIconBg : Colors.white,
          border: Border.all(color: value ? AppColors.iconBlueBorder : AppColors.cardBorder),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'لديك مشكلة في رفع الإشعار؟',
                style: TextStyle(fontSize: 14.sp, color: AppColors.onboardingText),
              ),
            ),
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                color: value ? AppColors.mainTeal : Colors.white,
                borderRadius: BorderRadius.circular(4.r),
                border: value ? null : Border.all(color: AppColors.cardBorder),
              ),
              child: value ? Icon(Icons.check, color: Colors.white, size: 14.sp) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualFields extends StatelessWidget {
  final List<PaymentBank> banks;
  final int bankId;
  final ValueChanged<int> onBankChanged;
  final TextEditingController holder;
  final TextEditingController amount;

  const _ManualFields({
    required this.banks,
    required this.bankId,
    required this.onBankChanged,
    required this.holder,
    required this.amount,
  });

  Widget _label(String text) => Padding(
        padding: EdgeInsets.only(bottom: 8.h),
        child: Text(
          text,
          textAlign: TextAlign.right,
          style: TextStyle(fontSize: 14.sp, color: AppColors.onboardingText),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label('اسم البنك'),
        DropdownButtonFormField<int>(
          initialValue: banks.any((b) => b.id == bankId) ? bankId : null,
          hint: const Text('اختر البنك'),
          items: [
            for (final bank in banks) DropdownMenuItem(value: bank.id, child: Text(bank.name)),
          ],
          onChanged: (id) {
            if (id != null) onBankChanged(id);
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: AppColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: AppColors.cardBorder),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        _label('اسم صاحب الحساب'),
        AppTextField(controller: holder, hintText: 'أدخل اسم صاحب الحساب'),
        SizedBox(height: 16.h),
        _label('المبلغ'),
        AppTextField(
          controller: amount,
          hintText: 'أدخل مبلغ التحويل',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
        ),
      ],
    );
  }
}
