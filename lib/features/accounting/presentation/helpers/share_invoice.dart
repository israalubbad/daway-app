import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/sale_invoice.dart';
import 'accounting_format.dart';

/// The invoice as plain text, the way it is sent in a message.
String invoiceShareText(SaleInvoice invoice) {
  final lines = StringBuffer()
    ..writeln('فاتورة ${invoice.number}')
    ..writeln('التاريخ: ${formatDateTime(invoice.date)}')
    ..writeln('العميل: ${invoice.customerName ?? 'زائر نقدي'}');
  for (final line in invoice.lines) {
    lines.writeln('- ${line.name} × ${line.quantity}: ${formatMoney(line.total)}');
  }
  lines
    ..writeln('الإجمالي: ${formatMoney(invoice.total)}')
    ..writeln('المدفوع: ${formatMoney(invoice.paid)}')
    ..writeln('المتبقي: ${formatMoney(invoice.remaining)}')
    ..write('طريقة الدفع: ${paymentMethodLabel(invoice.method)}');
  return lines.toString();
}

/// Opens WhatsApp with the invoice written out, to pick who gets it. There is
/// no PDF yet: building one with Arabic text needs a PDF package and an
/// embedded font, which is not in the app.
Future<void> shareInvoice(BuildContext context, SaleInvoice invoice) async {
  final messenger = ScaffoldMessenger.of(context);
  final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(invoiceShareText(invoice))}');
  try {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
  } catch (_) {
    // Reported below.
  }
  AppSnackbar.showOn(messenger, 'تعذر فتح واتساب');
}
