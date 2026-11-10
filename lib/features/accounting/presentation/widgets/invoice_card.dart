import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theming/app_colors.dart';
import '../../domain/entities/sale_invoice.dart';
import '../helpers/accounting_format.dart';
import '../helpers/accounting_styles.dart';
import 'accounting_card.dart';

enum InvoiceAction { view, refund, recordPayment, share }

/// One sales invoice: number and status, who and when, the three amounts, the
/// payment method and the discount, and a menu of what can be done with it.
class InvoiceCard extends StatelessWidget {
  final SaleInvoice invoice;
  final ValueChanged<InvoiceAction> onAction;

  const InvoiceCard({super.key, required this.invoice, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final remaining = invoice.remaining;
    return AccountingCard(
      onTap: () => onAction(InvoiceAction.view),
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
                    style: AccountingStyles.cardTitle,
                  ),
                ),
              ),
              PaymentStatusBadge(invoice.status),
              _Menu(invoice: invoice, onAction: onAction),
            ],
          ),
          Text(
            '${invoice.customerName ?? 'زائر نقدي'} · ${invoice.itemsCount} صنف · ${formatDateTime(invoice.date)}',
            style: AccountingStyles.muted,
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              _Figure(label: 'الإجمالي', amount: invoice.total),
              _Figure(label: 'المدفوع', amount: invoice.paid),
              _Figure(
                label: 'المتبقي',
                amount: remaining,
                color: remaining > 0 ? AppColors.logoutRed : null,
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              AccountingChip(paymentMethodLabel(invoice.method)),
              const Spacer(),
              Text(
                invoice.discount > 0 ? 'خصم ${formatMoney(invoice.discount)}' : 'خصم –',
                textDirection: TextDirection.rtl,
                style: AccountingStyles.muted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  final String label;
  final double amount;
  final Color? color;

  const _Figure({required this.label, required this.amount, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AccountingStyles.muted),
          MoneyText(
            amount,
            style: AccountingStyles.cardTitle.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _Menu extends StatelessWidget {
  final SaleInvoice invoice;
  final ValueChanged<InvoiceAction> onAction;

  const _Menu({required this.invoice, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<InvoiceAction>(
      tooltip: 'إجراءات',
      icon: Icon(Icons.more_vert_rounded, size: 20.r, color: AppColors.authInputBorder),
      padding: EdgeInsets.zero,
      onSelected: onAction,
      itemBuilder: (_) => [
        const PopupMenuItem(value: InvoiceAction.view, child: Text('عرض')),
        // A cancelled or refunded invoice takes no returns or payments.
        PopupMenuItem(
          value: InvoiceAction.refund,
          enabled: !invoice.isClosed,
          child: const Text('إرجاع'),
        ),
        // A fully paid invoice has nothing left to pay.
        PopupMenuItem(
          value: InvoiceAction.recordPayment,
          enabled: !invoice.isClosed && invoice.remaining > 0,
          child: const Text('تسجيل دفعة'),
        ),
        const PopupMenuItem(value: InvoiceAction.share, child: Text('مشاركة PDF')),
      ],
    );
  }
}
