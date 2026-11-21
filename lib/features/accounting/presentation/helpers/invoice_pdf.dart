import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/entities/sale_invoice.dart';
import 'accounting_format.dart';

/// The invoice as a one-page PDF (A5, right-to-left, Tajawal embedded so the
/// Arabic text is drawn and joined correctly). [regularFont] and [boldFont]
/// are the bytes of the TTF files, so a test can hand them in directly.
Future<Uint8List> buildInvoicePdf(
  SaleInvoice invoice, {
  required ByteData regularFont,
  required ByteData boldFont,
}) async {
  final theme = pw.ThemeData.withFont(
    base: pw.Font.ttf(regularFont),
    bold: pw.Font.ttf(boldFont),
  );
  final document = pw.Document(theme: theme, title: 'فاتورة ${invoice.number}');

  pw.Widget row(String label, String value, {bool strong = false}) {
    final style = pw.TextStyle(fontWeight: strong ? pw.FontWeight.bold : null, fontSize: 12);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [pw.Text(label, style: style), pw.Text(value, style: style)],
      ),
    );
  }

  document.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a5,
      textDirection: pw.TextDirection.rtl,
      margin: const pw.EdgeInsets.all(28),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            'فاتورة ${invoice.number}',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          row('التاريخ', formatDateTime(invoice.date)),
          row('العميل', invoice.customerName ?? 'زائر نقدي'),
          pw.Divider(),
          if (invoice.lines.isNotEmpty) ...[
            pw.TableHelper.fromTextArray(
              context: null,
              headers: ['المنتج', 'الكمية', 'السعر', 'المجموع'],
              data: [
                for (final line in invoice.lines)
                  [
                    line.name,
                    '${line.quantity}',
                    _money(line.unitPrice),
                    _money(line.unitPrice * line.quantity),
                  ],
              ],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
              cellStyle: const pw.TextStyle(fontSize: 11),
              cellAlignment: pw.Alignment.centerRight,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            ),
            pw.SizedBox(height: 8),
          ],
          row('الإجمالي', _money(invoice.total), strong: true),
          row('المدفوع', _money(invoice.paid)),
          row('المتبقي', _money(invoice.remaining)),
          row('طريقة الدفع', paymentMethodLabel(invoice.method)),
        ],
      ),
    ),
  );
  return document.save();
}

/// Loads the bundled Tajawal files and builds the PDF.
Future<Uint8List> buildInvoicePdfFromAssets(SaleInvoice invoice) async => buildInvoicePdf(
      invoice,
      regularFont: await rootBundle.load('assets/fonts/Tajawal-Regular.ttf'),
      boldFont: await rootBundle.load('assets/fonts/Tajawal-Bold.ttf'),
    );

/// [formatMoney] with the shekel sign written as a word: Tajawal has no glyph
/// for "₪", and a missing glyph would print as an empty box.
String _money(double amount) => formatMoney(amount).replaceAll('₪', ' شيكل').trim();
