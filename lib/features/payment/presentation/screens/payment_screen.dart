import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../../core/helpers/image_source_picker.dart';
import '../../../../core/helpers/price_formatter.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_text_styles.dart';
import '../../../../core/widgets/app_custom_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/profile_load_error.dart';
import '../../../patient/presentation/widgets/patient_sub_screen_header.dart';
import '../../domain/entities/payment.dart';
import '../cubit/payment_cubit.dart';

/// "الدفع": how much to transfer and to which bank, then the transfer receipt
/// ("تم التأكيد"). Sending the receipt only puts the payment under review —
/// the admin approves it, so the screen says "قيد المراجعة", never "مدفوع".
class PaymentScreen extends StatelessWidget {
  final int orderId;

  const PaymentScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PaymentCubit>(param1: orderId)..load(),
      child: const _PaymentView(),
    );
  }
}

class _PaymentView extends StatelessWidget {
  const _PaymentView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<PaymentCubit, PaymentState>(
          listenWhen: (previous, current) =>
              current.message != null && previous.messageId != current.messageId,
          listener: (context, state) => AppSnackbar.show(context, state.message!),
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
            return ListView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              children: [
                const PatientSubScreenHeader(
                  title: 'الدفع',
                  description: 'حوّل المبلغ إلى أحد الحسابات ثم أرسل صورة الإشعار.',
                ),
                SizedBox(height: 24.h),
                _AmountCard(summary: summary),
                SizedBox(height: 16.h),
                _StatusBanner(summary: summary, busy: state.isBusy),
                if (summary.canSubmitReceipt) ...[
                  SizedBox(height: 24.h),
                  _ReceiptForm(summary: summary, busy: state.isBusy),
                ] else ...[
                  SizedBox(height: 24.h),
                  for (final bank in summary.banks) _BankCard(bank: bank),
                ],
                SizedBox(height: 32.h),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  final PaymentSummary summary;

  const _AmountCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final total = summary.grandTotal;
    final fee = summary.deliveryFee;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.permissionIconBg,
        border: Border.all(color: AppColors.iconBlueBorder),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('المبلغ المطلوب تحويله', textAlign: TextAlign.right, style: AppTextStyles.authSubtitle),
          SizedBox(height: 4.h),
          Text(
            total == null ? '—' : '${formatPrice(total)} ₪',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 22.sp, color: AppColors.textDark),
          ),
          if (fee != null) ...[
            SizedBox(height: 4.h),
            Text(
              'شامل رسوم التوصيل: ${formatPrice(fee)} ₪',
              textAlign: TextAlign.right,
              style: AppTextStyles.authSubtitle,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final PaymentSummary summary;
  final bool busy;

  const _StatusBanner({required this.summary, required this.busy});

  static String? _label(String status) => switch (status) {
        'under_review' => 'تم إرسال الإشعار وهو قيد المراجعة من الإدارة',
        'problem_reported' => 'تم إرسال بلاغ عن الدفع وهو قيد المراجعة',
        'pending' => null,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final label = _label(summary.status);
    if (label == null) return const SizedBox.shrink();
    final canReport = summary.status == 'under_review' && summary.latestSubmissionId != null;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, textAlign: TextAlign.right, style: TextStyle(fontSize: 14.sp, color: AppColors.textDark)),
          if (canReport)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: busy ? null : () => _askForProblem(context),
                child: Text('الإبلاغ عن مشكلة في الدفع', style: TextStyle(color: AppColors.logoutRed)),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _askForProblem(BuildContext context) async {
    final cubit = context.read<PaymentCubit>();
    final message = await showDialog<String>(
      context: context,
      builder: (_) => const _ProblemDialog(),
    );
    if (message != null) await cubit.reportProblem(message);
  }
}

class _ProblemDialog extends StatefulWidget {
  const _ProblemDialog();

  @override
  State<_ProblemDialog> createState() => _ProblemDialogState();
}

class _ProblemDialogState extends State<_ProblemDialog> {
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
    return AlertDialog(
      title: const Text('الإبلاغ عن مشكلة'),
      content: AppTextField(
        controller: _controller,
        hintText: 'اشرح المشكلة',
        maxLines: 4,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إلغاء')),
        TextButton(
          onPressed: () {
            final text = _controller.text.trim();
            if (text.isNotEmpty) Navigator.of(context).pop(text);
          },
          child: const Text('إرسال'),
        ),
      ],
    );
  }
}

class _BankCard extends StatelessWidget {
  final PaymentBank bank;
  final bool selected;
  final VoidCallback? onTap;

  const _BankCard({required this.bank, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final lines = [
      if (bank.accountHolder != null) 'اسم الحساب: ${bank.accountHolder}',
      if (bank.accountNumber != null) 'رقم الحساب: ${bank.accountNumber}',
      if (bank.iban != null) 'IBAN: ${bank.iban}',
      if (bank.notes != null) bank.notes!,
    ];
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: selected ? AppColors.mainTeal : AppColors.cardBorder,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(bank.name, textAlign: TextAlign.right, style: TextStyle(fontSize: 15.sp, color: AppColors.textDark)),
            for (final line in lines)
              Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: SelectableText(
                  line,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.authSubtitle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptForm extends StatefulWidget {
  final PaymentSummary summary;
  final bool busy;

  const _ReceiptForm({required this.summary, required this.busy});

  @override
  State<_ReceiptForm> createState() => _ReceiptFormState();
}

class _ReceiptFormState extends State<_ReceiptForm> {
  late final TextEditingController _sender;
  late final TextEditingController _reference;
  int? _bankId;
  File? _receipt;

  @override
  void initState() {
    super.initState();
    _sender = TextEditingController();
    _reference = TextEditingController();
    final banks = widget.summary.banks;
    if (banks.length == 1) _bankId = banks.single.id;
  }

  @override
  void dispose() {
    _sender.dispose();
    _reference.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt() async {
    final file = await pickImageFromSourceSheet(context);
    if (file != null && mounted) setState(() => _receipt = file);
  }

  void _submit() {
    final total = widget.summary.grandTotal;
    final bankId = _bankId;
    final receipt = _receipt;
    if (bankId == null) return AppSnackbar.show(context, 'اختر البنك الذي حوّلت إليه');
    if (_sender.text.trim().isEmpty) return AppSnackbar.show(context, 'اكتب اسم المحوِّل');
    if (_reference.text.trim().isEmpty) return AppSnackbar.show(context, 'اكتب رقم الحوالة');
    if (receipt == null) return AppSnackbar.show(context, 'أرفق صورة إشعار التحويل');
    if (total == null) return AppSnackbar.show(context, 'تعذر تحديد المبلغ، أعد تحميل الصفحة');

    context.read<PaymentCubit>().submitReceipt(
          bankId: bankId,
          amount: total,
          senderName: _sender.text.trim(),
          transferReference: _reference.text.trim(),
          receipt: receipt,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('اختر البنك الذي حوّلت إليه', textAlign: TextAlign.right, style: AppTextStyles.authSubtitle),
        SizedBox(height: 8.h),
        for (final bank in widget.summary.banks)
          _BankCard(
            bank: bank,
            selected: bank.id == _bankId,
            onTap: () => setState(() => _bankId = bank.id),
          ),
        SizedBox(height: 8.h),
        AppTextField(controller: _sender, hintText: 'اسم المحوِّل'),
        SizedBox(height: 12.h),
        AppTextField(controller: _reference, hintText: 'رقم الحوالة'),
        SizedBox(height: 12.h),
        AppCustomButton(
          text: _receipt == null ? 'إرفاق صورة الإشعار' : 'تغيير صورة الإشعار',
          onPressed: _pickReceipt,
          backgroundColor: Colors.white,
          textColor: AppColors.mainTeal,
          borderColor: AppColors.mainTeal,
        ),
        if (_receipt != null) ...[
          SizedBox(height: 12.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Image.file(_receipt!, height: 160.h, fit: BoxFit.cover),
          ),
        ],
        SizedBox(height: 24.h),
        AppCustomButton(text: 'تم التأكيد', isLoading: widget.busy, onPressed: _submit),
      ],
    );
  }
}
