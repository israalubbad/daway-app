import 'package:flutter/material.dart';

import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/sale_invoice.dart';
import '../cubit/sales_cubit.dart';
import '../screens/invoice_details_screen.dart';
import '../widgets/invoice_card.dart';
import '../widgets/record_payment_sheet.dart';
import '../widgets/refund_sheet.dart';
import 'share_invoice.dart';

import '../../../../core/localization/translations.dart';

/// Runs [work] while a spinner covers the screen: what an action does before it
/// has anything to show (fetching an invoice's lines).
Future<T> _whileBusy<T>(BuildContext context, Future<T> work) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black26,
    builder: (_) => const PopScope(
      canPop: false,
      child: Center(child: CircularProgressIndicator()),
    ),
  );
  try {
    return await work;
  } finally {
    navigator.pop();
  }
}

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
      // The list has no lines: they are fetched before the details open.
      final details = await _whileBusy(context, cubit.loadDetails(invoice));
      if (!context.mounted) return false;
      final loaded = details.invoice;
      if (loaded == null) {
        AppSnackbar.show(context, details.error ?? 'تعذر تحميل الفاتورة'.tr);
        return false;
      }
      await InvoiceDetailsScreen.open(
        context,
        invoice: loaded,
        onAction: (screen, next) => runInvoiceAction(
          screen,
          invoice: loaded,
          action: next,
          cubit: cubit,
          onChanged: onChanged,
        ),
      );
      return false;
    case InvoiceAction.recordPayment:
      if (invoice.isClosed || invoice.remaining <= 0) {
        AppSnackbar.show(context, 'لا يوجد مبلغ متبقٍ على هذه الفاتورة'.tr);
        return false;
      }
      final saved = await RecordPaymentSheet.show(context, invoice, cubit);
      if (saved != true || !context.mounted) return false;
      onChanged();
      AppSnackbar.show(context, 'تم تسجيل الدفعة'.tr);
      return true;
    case InvoiceAction.refund:
      final refundable = await _whileBusy(context, cubit.loadRefundableLines(invoice));
      if (!context.mounted) return false;
      final lines = refundable.lines;
      if (lines == null) {
        AppSnackbar.show(context, refundable.error ?? 'تعذر تحميل أصناف الفاتورة'.tr);
        return false;
      }
      final saved = await RefundSheet.show(context, invoice, lines, cubit);
      if (saved != true || !context.mounted) return false;
      onChanged();
      AppSnackbar.show(context, 'تم تسجيل الإرجاع'.tr);
      return true;
    case InvoiceAction.share:
      // Share what is known: the lines only if the details were opened.
      await shareInvoice(context, invoice);
      return false;
  }
}
