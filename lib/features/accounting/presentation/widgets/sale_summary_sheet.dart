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

import '../../../../core/localization/translations.dart';

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
    _customerController = TextEditingController();
    final paid = state.paid;
    _paidController = TextEditingController(text: paid == null ? '' : paid.toString());
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
        title: Text('إتمام البيع بإجمالي {0}؟'.trArgs([formatMoney(total)]), style: AccountingStyles.cardTitle),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text('إلغاء'.tr)),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text('تأكيد'.tr)),
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
                      Expanded(child: Text('ملخص الفاتورة'.tr, style: AccountingStyles.sectionTitle)),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'إغلاق'.tr,
                      ),
                    ],
                  ),
                  _Field(
                    label: 'العميل'.tr,
                    child: state.customer == null
                        ? TextField(
                            controller: _customerController,
                            onChanged: widget.cubit.customerQueryChanged,
                            decoration: _decoration('زائر نقدي · اكتب اسماً لاختيار عميل'.tr),
                          )
                        : _SelectedCustomer(
                            name: state.customer!.name,
                            onClear: () {
                              widget.cubit.customerCleared();
                              _customerController.clear();
                            },
                          ),
                  ),
                  for (final customer in state.customerResults)
                    InkWell(
                      onTap: () => widget.cubit.customerSelected(customer),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        child: Row(
                          children: [
                            Expanded(child: Text(customer.name, style: AccountingStyles.body)),
                            if (customer.balance > 0)
                              Text(
                                'عليه {0}'.trArgs([formatMoney(customer.balance)]),
                                textDirection: TextDirection.rtl,
                                style: AccountingStyles.muted,
                              ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(height: 12.h),
                  _Row('المجموع الفرعي'.tr, formatMoney(state.subtotal)),
                  _Row('الخصم'.tr, '−${formatMoney(0)}'),
                  _Row('الضريبة'.tr, 'غير مدعومة في النظام الحالي'.tr, ltr: false),
                  const Divider(),
                  _Row('الإجمالي'.tr, formatMoney(state.total), strong: true),
                  SizedBox(height: 12.h),
                  _Field(
                    label: 'المدفوع'.tr,
                    child: TextField(
                      controller: _paidController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.start,
                      onChanged: widget.cubit.paidChanged,
                      // Left empty, the backend decides: everything for a cash
                      // sale, nothing for a sale on credit.
                      decoration: _decoration(
                        state.method == PaymentMethod.credit ? '0.00' : state.total.toStringAsFixed(2),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  _Row('المتبقي'.tr, formatMoney(state.remaining)),
                  SizedBox(height: 12.h),
                  Text('طريقة الدفع'.tr, style: AccountingStyles.label),
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
                    text: 'إتمام البيع'.tr,
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

/// The customer already chosen for the invoice, with a button to drop it.
class _SelectedCustomer extends StatelessWidget {
  final String name;
  final VoidCallback onClear;

  const _SelectedCustomer({required this.name, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.permissionIconBg,
        border: Border.all(color: AppColors.iconBlueBorder),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Expanded(child: Text(name, style: AccountingStyles.cardTitle)),
          GestureDetector(
            onTap: onClear,
            child: Icon(Icons.close_rounded, size: 18.r, color: AppColors.mainTeal),
          ),
        ],
      ),
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

