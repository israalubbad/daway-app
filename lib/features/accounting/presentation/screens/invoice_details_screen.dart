import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theming/app_colors.dart';
import '../../../../core/widgets/app_custom_button.dart';
import '../../../pharmacy/presentation/widgets/pharmacy_products_header.dart';
import '../../domain/entities/sale_invoice.dart';
import '../helpers/accounting_format.dart';
import '../helpers/accounting_styles.dart';
import '../widgets/accounting_card.dart';
import '../widgets/invoice_card.dart';

import '../../../../core/localization/translations.dart';

/// "تفاصيل الفاتورة": who and when, every line, the totals, and the invoice's
/// actions. A payment or a return changes the invoice, so once one is saved the
/// screen closes and the list behind it shows the new figures.
class InvoiceDetailsScreen extends StatelessWidget {
  final SaleInvoice invoice;

  /// Runs an action with this screen's context; completes with true when it
  /// saved a payment or a return.
  final Future<bool> Function(BuildContext context, InvoiceAction action) onAction;

  const InvoiceDetailsScreen({super.key, required this.invoice, required this.onAction});

  static Future<void> open(
    BuildContext context, {
    required SaleInvoice invoice,
    required Future<bool> Function(BuildContext context, InvoiceAction action) onAction,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InvoiceDetailsScreen(invoice: invoice, onAction: onAction),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 24.h),
          children: [
            PharmacyProductsHeader(
              title: 'تفاصيل الفاتورة'.tr,
              subtitle: invoice.number,
              onBack: () => Navigator.of(context).pop(),
            ),
            SizedBox(height: 16.h),
            AccountingCard(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            invoice.number,
                            textDirection: TextDirection.ltr,
                            style: AccountingStyles.sectionTitle,
                          ),
                        ),
                      ),
                      PaymentStatusBadge(invoice.status),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  _InfoRow('العميل'.tr, invoice.customerName ?? 'زائر نقدي'.tr),
                  _InfoRow('التاريخ'.tr, formatDateTime(invoice.date), ltr: true),
                  _InfoRow('طريقة الدفع'.tr, paymentMethodLabel(invoice.method)),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Text('الأصناف'.tr, style: AccountingStyles.sectionTitle),
            SizedBox(height: 8.h),
            if (invoice.lines.isEmpty)
              Text('لا توجد تفاصيل أصناف لهذه الفاتورة'.tr, style: AccountingStyles.muted)
            else
              for (final line in invoice.lines) ...[
                AccountingCard(
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
                      MoneyText(line.total, style: AccountingStyles.cardTitle),
                    ],
                  ),
                ),
                SizedBox(height: 8.h),
              ],
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.permissionIconBg,
                border: Border.all(color: AppColors.iconBlueBorder),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  _MoneyRow('المجموع الفرعي'.tr, invoice.subtotal),
                  _MoneyRow('الخصم'.tr, invoice.discount, negative: true),
                  _MoneyRow('الإجمالي'.tr, invoice.total, strong: true),
                  _MoneyRow('المدفوع'.tr, invoice.paid),
                  _MoneyRow(
                    'المتبقي'.tr,
                    invoice.remaining,
                    color: invoice.remaining > 0 ? AppColors.logoutRed : null,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            if (!invoice.isClosed && invoice.remaining > 0) ...[
              AppCustomButton(
                text: 'تسجيل دفعة'.tr,
                height: 48.h,
                onPressed: () => _run(context, InvoiceAction.recordPayment),
              ),
              SizedBox(height: 8.h),
            ],
            Row(
              children: [
                if (!invoice.isClosed) ...[
                  Expanded(
                    child: AppCustomButton(
                      text: 'إرجاع'.tr,
                      height: 48.h,
                      backgroundColor: Colors.white,
                      textColor: AppColors.mainTeal,
                      borderColor: AppColors.cardBorder,
                      onPressed: () => _run(context, InvoiceAction.refund),
                    ),
                  ),
                  SizedBox(width: 8.w),
                ],
                Expanded(
                  child: AppCustomButton(
                    text: 'مشاركة'.tr,
                    height: 48.h,
                    backgroundColor: Colors.white,
                    textColor: AppColors.mainTeal,
                    borderColor: AppColors.cardBorder,
                    onPressed: () => _run(context, InvoiceAction.share),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _run(BuildContext context, InvoiceAction action) async {
    final changed = await onAction(context, action);
    // A saved payment or return makes this screen's invoice out of date: the
    // list behind it has refreshed, so go back to it.
    if (changed && context.mounted) Navigator.of(context).pop();
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool ltr;

  const _InfoRow(this.label, this.value, {this.ltr = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AccountingStyles.muted)),
          Text(
            value,
            textDirection: ltr ? TextDirection.ltr : null,
            style: AccountingStyles.body,
          ),
        ],
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool strong;
  final bool negative;
  final Color? color;

  const _MoneyRow(this.label, this.amount, {this.strong = false, this.negative = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AccountingStyles.body)),
          Text(
            '${negative && amount > 0 ? '−' : ''}${formatMoney(amount)}',
            textDirection: TextDirection.ltr,
            style: (strong ? AccountingStyles.amount : AccountingStyles.cardTitle).copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
