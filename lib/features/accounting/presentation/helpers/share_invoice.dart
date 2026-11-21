import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/sale_invoice.dart';
import 'accounting_format.dart';
import 'invoice_pdf.dart';

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

/// Shares the invoice as a PDF through the system share sheet (WhatsApp, mail,
/// ...). If the PDF cannot be made or shared, falls back to WhatsApp with the
/// invoice written out.
Future<void> shareInvoice(BuildContext context, SaleInvoice invoice) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final bytes = await buildInvoicePdfFromAssets(invoice);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'application/pdf', name: '${invoice.number}.pdf')],
        fileNameOverrides: ['${invoice.number}.pdf'],
        subject: 'فاتورة ${invoice.number}',
      ),
    );
    return;
  } catch (_) {
    // Fall back to the text message below.
  }
  final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(invoiceShareText(invoice))}');
  try {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
  } catch (_) {
    // Reported below.
  }
  AppSnackbar.showOn(messenger, 'تعذر فتح واتساب');
}
