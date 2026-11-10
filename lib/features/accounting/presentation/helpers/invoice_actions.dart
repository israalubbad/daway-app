import 'package:flutter/material.dart';

import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/sale_invoice.dart';
import '../cubit/sales_cubit.dart';
import '../screens/invoice_details_screen.dart';
import '../widgets/invoice_card.dart';
import '../widgets/record_payment_sheet.dart';
import '../widgets/refund_sheet.dart';
import 'share_invoice.dart';

/// Does what an invoice's menu (or its details screen) asked for. Completes
/// with true when a payment or a return was saved; [onChanged] is called then,
/// so the other tabs that show the same money (overview, refunds, cash) can
/// fetch again.
Future<bool> runInvoiceAction(
  BuildContext context, {
  required SaleInvoice invoice,
  required InvoiceAction action,
  required SalesCubit cubit,
  required VoidCallback onChanged,
}) async {
  switch (action) {
    case InvoiceAction.view:
      await InvoiceDetailsScreen.open(
        context,
        invoice: invoice,
        onAction: (details, next) => runInvoiceAction(
          details,
          invoice: invoice,
          action: next,
          cubit: cubit,
          onChanged: onChanged,
        ),
      );
      return false;
    case InvoiceAction.recordPayment:
      if (invoice.remaining <= 0) {
        AppSnackbar.show(context, 'الفاتورة مدفوعة بالكامل');
        return false;
      }
      final saved = await RecordPaymentSheet.show(context, invoice, cubit);
      if (saved != true || !context.mounted) return false;
      onChanged();
      AppSnackbar.show(context, 'تم تسجيل الدفعة');
      return true;
    case InvoiceAction.refund:
      if (invoice.lines.isEmpty) {
        AppSnackbar.show(context, 'لا توجد تفاصيل أصناف لهذه الفاتورة');
        return false;
      }
      final saved = await RefundSheet.show(context, invoice, cubit);
      if (saved != true || !context.mounted) return false;
      onChanged();
      AppSnackbar.show(context, 'تم تسجيل الإرجاع');
      return true;
    case InvoiceAction.share:
      await shareInvoice(context, invoice);
      return false;
  }
}
