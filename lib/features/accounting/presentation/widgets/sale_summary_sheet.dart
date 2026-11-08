import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theming/app_colors.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_custom_button.dart';
import '../../domain/entities/accounting_overview.dart';
import '../cubit/new_sale_cubit.dart';
import '../cubit/new_sale_state.dart';
import '../helpers/accounting_format.dart';
import '../helpers/accounting_styles.dart';

/// "ملخص الفاتورة": customer, the totals, what was paid, what remains and how.
/// Pops with true once the sale is saved.
class SaleSummarySheet extends StatefulWidget {
  final NewSaleCubit cubit;

  const SaleSummarySheet({super.key, required this.cubit});

  static Future<bool?> show(BuildContext context, NewSaleCubit cubit) {
    return AppBottomSheet.show<bool>(
      context,
      builder: (_) => SaleSummarySheet(cubit: cubit),
    );
  }

  @override
  State<SaleSummarySheet> createState() => _SaleSummarySheetState();
}

class _SaleSummarySheetState extends State<SaleSummarySheet> {
  late final TextEditingController _customerController;
  late final TextEditingController _paidController;

  @override
  void initState() {
    super.initState();
    final state = widget.cubit.state;
    _customerController = TextEditingController(text: state.customerName ?? '');
    _paidController = TextEditingController(text: state.paid > 0 ? state.paid.toString() : '');
  }

  @override
  void dispose() {
    _customerController.dispose();
    _paidController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    final total = widget.cubit.state.total;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('إتمام البيع بإجمالي ${formatMoney(total)}؟', style: AccountingStyles.cardTitle),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('تأكيد')),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.cubit.submit();
    if (mounted && widget.cubit.state.completed) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: AppBottomSheet(
        padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 24.h),
        child: BlocBuilder<NewSaleCubit, NewSaleState>(
          bloc: widget.cubit,
          builder: (context, state) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('ملخص الفاتورة', style: AccountingStyles.sectionTitle)),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'إغلاق',
                      ),
                    ],
                  ),
                  _Field(
                    label: 'العميل',
                    child: TextField(
                      controller: _customerController,
                      onChanged: widget.cubit.customerChanged,
                      decoration: _decoration('زائر نقدي'),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _Row('المجموع الفرعي', formatMoney(state.subtotal)),
                  _Row('الخصم', '−${formatMoney(0)}'),
                  _Row('الضريبة', 'غير مدعومة في النظام الحالي', ltr: false),
                  const Divider(),
                  _Row('الإجمالي', formatMoney(state.total), strong: true),
                  SizedBox(height: 12.h),
                  _Field(
                    label: 'المدفوع',
                    child: TextField(
                      controller: _paidController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.right,
                      onChanged: widget.cubit.paidChanged,
                      decoration: _decoration('0.00'),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  _Row('المتبقي', formatMoney(state.remaining)),
                  SizedBox(height: 12.h),
                  Text('طريقة الدفع', style: AccountingStyles.label),
                  SizedBox(height: 6.h),
                  Wrap(
                    spacing: 8.w,
                    children: [
                      for (final method in PaymentMethod.values)
                        ChoiceChip(
                          label: Text(paymentMethodLabel(method)),
                          selected: state.method == method,
                          onSelected: (_) => widget.cubit.methodChanged(method),
                        ),
                    ],
                  ),
                  if (state.errorMessage != null) ...[
                    SizedBox(height: 8.h),
                    Text(
                      state.errorMessage!,
                      style: AccountingStyles.label.copyWith(color: AppColors.logoutRed),
                    ),
                  ],
                  SizedBox(height: 16.h),
                  AppCustomButton(
                    text: 'إتمام البيع',
                    isLoading: state.isSaving,
                    backgroundColor: state.canSubmit ? AppColors.mainTeal : AppColors.borderGrey,
                    onPressed: state.canSubmit ? _complete : () {},
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.r),
      borderSide: BorderSide(color: color),
    );
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: AccountingStyles.muted.copyWith(fontSize: 13.sp),
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      enabledBorder: border(AppColors.cardBorder),
      focusedBorder: border(AppColors.mainTeal),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final Widget child;

  const _Field({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: AccountingStyles.label),
        SizedBox(height: 6.h),
        child,
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;
  final bool ltr;

  const _Row(this.label, this.value, {this.strong = false, this.ltr = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AccountingStyles.body)),
          Text(
            value,
            textDirection: ltr ? TextDirection.ltr : null,
            style: strong ? AccountingStyles.amount : (ltr ? AccountingStyles.body : AccountingStyles.muted),
          ),
        ],
      ),
    );
  }
}

