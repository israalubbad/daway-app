import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theming/app_colors.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_custom_button.dart';
import '../../../../core/widgets/app_filter_chip.dart';
import '../../domain/entities/accounting_overview.dart';
import '../../domain/entities/sale_invoice.dart';
import '../cubit/sales_cubit.dart';
import '../helpers/accounting_format.dart';
import '../helpers/accounting_styles.dart';

import '../../../../core/localization/translations.dart';

/// "تسجيل دفعة" on an invoice: how much was paid now, and how. Starts at what
/// is still owed. Pops with true once the payment is saved.
class RecordPaymentSheet extends StatefulWidget {
  final SaleInvoice invoice;
  final SalesCubit cubit;

  const RecordPaymentSheet({super.key, required this.invoice, required this.cubit});

  static Future<bool?> show(BuildContext context, SaleInvoice invoice, SalesCubit cubit) {
    return AppBottomSheet.show<bool>(
      context,
      builder: (_) => RecordPaymentSheet(invoice: invoice, cubit: cubit),
    );
  }

  @override
  State<RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends State<RecordPaymentSheet> {
  late final TextEditingController _amountController;
  PaymentMethod _method = PaymentMethod.cash;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.invoice.remaining.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final error = await widget.cubit.recordPayment(
      widget.invoice,
      amount: double.tryParse(_amountController.text.trim()) ?? 0,
      method: _method,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _isSaving = false;
        _error = error;
      });
      return;
    }
    Navigator.of(context).pop(true);
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
                  Expanded(child: Text('تسجيل دفعة'.tr, style: AccountingStyles.sectionTitle)),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'إغلاق'.tr,
                  ),
                ],
              ),
              Text(
                'الفاتورة {0} · المتبقي {1}'.trArgs([widget.invoice.number, formatMoney(widget.invoice.remaining)]),
                style: AccountingStyles.muted,
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
                decoration: InputDecoration(
                  isDense: true,
                  prefixText: '₪ ',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(color: AppColors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(color: AppColors.mainTeal),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Text('طريقة الدفع'.tr, style: AccountingStyles.label),
              SizedBox(height: 6.h),
              Wrap(
                spacing: 8.w,
                children: [
                  for (final method in PaymentMethod.values)
                    AppFilterChip(
                      label: paymentMethodLabel(method),
                      selected: _method == method,
                      onTap: () => setState(() => _method = method),
                    ),
                ],
              ),
              if (_error != null) ...[
                SizedBox(height: 8.h),
                Text(_error!, style: AccountingStyles.label.copyWith(color: AppColors.logoutRed)),
              ],
              SizedBox(height: 16.h),
              AppCustomButton(text: 'تسجيل'.tr, isLoading: _isSaving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
