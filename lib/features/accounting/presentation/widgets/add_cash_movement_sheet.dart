import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theming/app_colors.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_custom_button.dart';
import '../../domain/entities/cash_ledger.dart';
import '../cubit/cash_cubit.dart';
import '../helpers/accounting_format.dart';
import '../helpers/accounting_styles.dart';

import '../../../../core/localization/translations.dart';

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

  bool get _canSave =>
      CashMovementRules.isValid(amount: _amount, reason: _reasonController.text) && !_isSaving;

  bool get _exceedsBalance => CashMovementRules.exceedsBalance(
    isDeposit: _isDeposit,
    amount: _amount,
    balance: widget.balance,
  );

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
          'تأكيد {0} {1}؟'.trArgs([_isDeposit ? 'إيداع' : 'سحب', formatMoney(_amount)]),
          style: AccountingStyles.cardTitle,
        ),
        content: Text(
          'سيتم تسجيل الحركة في دفتر الصندوق فوراً ولا يمكن التراجع عنها.'.tr,
          style: AccountingStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('إلغاء'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('تأكيد'.tr),
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
      ..showSnackBar(SnackBar(content: Text('تم تسجيل الحركة'.tr)));
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
                  Expanded(child: Text('تسجيل حركة صندوق'.tr, style: AccountingStyles.sectionTitle)),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'إغلاق'.tr,
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text('النوع'.tr, style: AccountingStyles.label),
              SizedBox(height: 6.h),
              Row(
                children: [
                  Expanded(child: _TypeButton(label: 'إيداع'.tr, selected: _isDeposit, onTap: () => setState(() => _isDeposit = true))),
                  SizedBox(width: 8.w),
                  Expanded(child: _TypeButton(label: 'سحب'.tr, selected: !_isDeposit, onTap: () => setState(() => _isDeposit = false))),
                ],
              ),
              SizedBox(height: 12.h),
              Text('المبلغ'.tr, style: AccountingStyles.label),
              SizedBox(height: 6.h),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.start,
                onChanged: (_) => setState(() => _error = null),
                decoration: AccountingStyles.inputDecoration(hint: '0.00', prefixText: '₪ '),
              ),
              if (_exceedsBalance)
                Padding(
                  padding: EdgeInsets.only(top: 6.h),
                  child: Text(
                    'المبلغ أكبر من الرصيد الحالي ({0})'.trArgs([formatMoney(widget.balance)]),
                    style: AccountingStyles.label.copyWith(color: AppColors.statLowStock),
                  ),
                ),
              SizedBox(height: 12.h),
              Text('سبب الحركة'.tr, style: AccountingStyles.label),
              SizedBox(height: 6.h),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                onChanged: (_) => setState(() => _error = null),
                decoration: AccountingStyles.inputDecoration(hint: 'اذكر سبب الحركة (إلزامي)'.tr),
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
                        'سيتم تسجيل الحركة في دفتر الصندوق فوراً ولا يمكن التراجع عنها.'.tr,
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
                text: 'تسجيل'.tr,
                isLoading: _isSaving,
                backgroundColor: _canSave ? AppColors.mainTeal : AppColors.borderGrey,
                // Said under the fields: a snackbar would sit behind this sheet.
                onPressed: _canSave
                    ? _save
                    : () => setState(() => _error = 'أدخل المبلغ وسبب الحركة'.tr),
              ),
              SizedBox(height: 8.h),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('إلغاء'.tr, style: AccountingStyles.body.copyWith(color: AppColors.mainTeal)),
              ),
            ],
          ),
        ),
      ),
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
