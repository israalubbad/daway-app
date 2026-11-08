import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theming/app_colors.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_custom_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../cubit/cash_cubit.dart';
import '../helpers/accounting_format.dart';
import '../helpers/accounting_styles.dart';

/// "تسجيل حركة صندوق": deposit or withdrawal, amount and reason. The movement
/// cannot be taken back, so saving first asks to confirm the amount.
class AddCashMovementSheet extends StatefulWidget {
  final CashCubit cubit;

  /// The balance now, to warn about a withdrawal that is more than it.
  final double balance;

  const AddCashMovementSheet({super.key, required this.cubit, required this.balance});

  static Future<void> show(BuildContext context, {required CashCubit cubit, required double balance}) {
    return AppBottomSheet.show<void>(
      context,
      builder: (_) => AddCashMovementSheet(cubit: cubit, balance: balance),
    );
  }

  @override
  State<AddCashMovementSheet> createState() => _AddCashMovementSheetState();
}

class _AddCashMovementSheetState extends State<AddCashMovementSheet> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  bool _isDeposit = true;
  bool _isSaving = false;
  String? _error;

  double get _amount => double.tryParse(_amountController.text.trim()) ?? 0;

  bool get _canSave => _amount > 0 && _reasonController.text.trim().isNotEmpty && !_isSaving;

  bool get _exceedsBalance => !_isDeposit && _amount > widget.balance;

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'تأكيد ${_isDeposit ? 'إيداع' : 'سحب'} ${formatMoney(_amount)}؟',
          style: AccountingStyles.cardTitle,
        ),
        content: Text(
          'سيتم تسجيل الحركة في دفتر الصندوق فوراً ولا يمكن التراجع عنها.',
          style: AccountingStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });
    final error = await widget.cubit.record(
      isDeposit: _isDeposit,
      amount: _amount,
      reason: _reasonController.text,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _isSaving = false;
        _error = error;
      });
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('تم تسجيل الحركة')));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: AppBottomSheet(
        padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 24.h),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text('تسجيل حركة صندوق', style: AccountingStyles.sectionTitle)),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'إغلاق',
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text('النوع', style: AccountingStyles.label),
              SizedBox(height: 6.h),
              Row(
                children: [
                  Expanded(child: _TypeButton(label: 'إيداع', selected: _isDeposit, onTap: () => setState(() => _isDeposit = true))),
                  SizedBox(width: 8.w),
                  Expanded(child: _TypeButton(label: 'سحب', selected: !_isDeposit, onTap: () => setState(() => _isDeposit = false))),
                ],
              ),
              SizedBox(height: 12.h),
              Text('المبلغ', style: AccountingStyles.label),
              SizedBox(height: 6.h),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.right,
                onChanged: (_) => setState(() {}),
                decoration: _decoration(hint: '0.00', prefix: '₪'),
              ),
              if (_exceedsBalance)
                Padding(
                  padding: EdgeInsets.only(top: 6.h),
                  child: Text(
                    'المبلغ أكبر من الرصيد الحالي (${formatMoney(widget.balance)})',
                    style: AccountingStyles.label.copyWith(color: AppColors.statLowStock),
                  ),
                ),
              SizedBox(height: 12.h),
              Text('سبب الحركة', style: AccountingStyles.label),
              SizedBox(height: 6.h),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                onChanged: (_) => setState(() {}),
                decoration: _decoration(hint: 'اذكر سبب الحركة (إلزامي)'),
              ),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: AppColors.productLowStockTint,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18.r, color: AppColors.statLowStock),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'سيتم تسجيل الحركة في دفتر الصندوق فوراً ولا يمكن التراجع عنها.',
                        style: AccountingStyles.label,
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                SizedBox(height: 8.h),
                Text(_error!, style: AccountingStyles.label.copyWith(color: AppColors.logoutRed)),
              ],
              SizedBox(height: 16.h),
              AppCustomButton(
                text: 'تسجيل',
                isLoading: _isSaving,
                backgroundColor: _canSave ? AppColors.mainTeal : AppColors.borderGrey,
                onPressed: _canSave ? _save : () => AppSnackbar.show(context, 'أدخل المبلغ وسبب الحركة'),
              ),
              SizedBox(height: 8.h),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('إلغاء', style: AccountingStyles.body.copyWith(color: AppColors.mainTeal)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration({required String hint, String? prefix}) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.r),
      borderSide: BorderSide(color: color),
    );
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: AccountingStyles.muted.copyWith(fontSize: 13.sp),
      prefixText: prefix == null ? null : '$prefix ',
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      enabledBorder: border(AppColors.cardBorder),
      focusedBorder: border(AppColors.mainTeal),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.permissionIconBg : Colors.white,
          border: Border.all(color: selected ? AppColors.mainTeal : AppColors.cardBorder),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          label,
          style: AccountingStyles.body.copyWith(color: selected ? AppColors.mainTeal : null),
        ),
      ),
    );
  }
}
