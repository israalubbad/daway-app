import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theming/app_colors.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_custom_button.dart';
import '../../domain/entities/sale_invoice.dart';
import '../cubit/sales_cubit.dart';
import '../helpers/accounting_styles.dart';
import 'accounting_card.dart';

import '../../../../core/localization/translations.dart';

/// "إرجاع" on an invoice: how many units of each line come back, the amount
/// that adds up to, and a confirmation before it is saved. Pops with true once
/// the return is saved.
class RefundSheet extends StatefulWidget {
  final SaleInvoice invoice;

  /// The lines that can still be returned, each with the units left.
  final List<InvoiceLine> lines;
  final SalesCubit cubit;

  const RefundSheet({super.key, required this.invoice, required this.lines, required this.cubit});

  static Future<bool?> show(
    BuildContext context,
    SaleInvoice invoice,
    List<InvoiceLine> lines,
    SalesCubit cubit,
  ) {
    return AppBottomSheet.show<bool>(
      context,
      builder: (_) => RefundSheet(invoice: invoice, lines: lines, cubit: cubit),
    );
  }

  @override
  State<RefundSheet> createState() => _RefundSheetState();
}

class _RefundSheetState extends State<RefundSheet> {
  /// Item id → units to return.
  final Map<int, int> _quantities = {};
  bool _isSaving = false;
  String? _error;

  RefundRequest get _request => RefundRequest(
    invoiceNumber: widget.invoice.number,
    lines: widget.lines,
    quantities: _quantities,
  );

  void _change(InvoiceLine line, int delta) {
    final next = ((_quantities[line.itemId] ?? 0) + delta).clamp(0, line.quantity);
    setState(() {
      _quantities[line.itemId] = next;
      _error = null;
    });
  }

  Future<void> _save() async {
    final request = _request;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('تأكيد إرجاع {0} ₪؟'.trArgs([request.amount.toStringAsFixed(2)]), style: AccountingStyles.cardTitle),
        content: Text('سيتم تسجيل الإرجاع على الفاتورة {0}.'.trArgs([widget.invoice.number]), style: AccountingStyles.body),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text('إلغاء'.tr)),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text('تأكيد'.tr)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });
    final error = await widget.cubit.refund(request);
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
    final request = _request;
    return AppBottomSheet(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 24.h),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('إرجاع'.tr, style: AccountingStyles.sectionTitle)),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'إغلاق'.tr,
                ),
              ],
            ),
            Text('الفاتورة {0} · اختر الكمية المرجعة من كل صنف'.trArgs([widget.invoice.number]), style: AccountingStyles.muted),
            SizedBox(height: 12.h),
            for (final line in widget.lines)
              Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: _RefundLineTile(
                  line: line,
                  returned: _quantities[line.itemId] ?? 0,
                  onChange: (delta) => _change(line, delta),
                ),
              ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(child: Text('مبلغ الإرجاع'.tr, style: AccountingStyles.body)),
                MoneyText(request.amount, style: AccountingStyles.amount),
              ],
            ),
            if (_error != null) ...[
              SizedBox(height: 8.h),
              Text(_error!, style: AccountingStyles.label.copyWith(color: AppColors.logoutRed)),
            ],
            SizedBox(height: 16.h),
            AppCustomButton(
              text: 'تأكيد الإرجاع'.tr,
              isLoading: _isSaving,
              backgroundColor: request.isValid ? AppColors.mainTeal : AppColors.borderGrey,
              // Said under the lines: a snackbar would sit behind this sheet.
              onPressed: request.isValid
                  ? _save
                  : () => setState(() => _error = 'اختر وحدة واحدة على الأقل للإرجاع'.tr),
            ),
          ],
        ),
      ),
    );
  }
}

class _RefundLineTile extends StatelessWidget {
  final InvoiceLine line;
  final int returned;
  final ValueChanged<int> onChange;

  const _RefundLineTile({required this.line, required this.returned, required this.onChange});

  @override
  Widget build(BuildContext context) {
    Widget step(IconData icon, VoidCallback onTap, String label) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6.r),
      child: Semantics(
        button: true,
        label: label,
        child: Container(
          width: 30.r,
          height: 30.r,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Icon(icon, size: 16.r, color: AppColors.mainTeal),
        ),
      ),
    );

    return AccountingCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.name, style: AccountingStyles.cardTitle),
                Row(
                  children: [
                    MoneyText(line.unitPrice, style: AccountingStyles.muted),
                    Text(' × ${line.quantity}', style: AccountingStyles.muted),
                  ],
                ),
              ],
            ),
          ),
          step(Icons.remove, () => onChange(-1), 'تقليل'.tr),
          SizedBox(
            width: 32.w,
            child: Text('$returned', textAlign: TextAlign.center, style: AccountingStyles.cardTitle),
          ),
          step(Icons.add, () => onChange(1), 'زيادة'.tr),
        ],
      ),
    );
  }
}
