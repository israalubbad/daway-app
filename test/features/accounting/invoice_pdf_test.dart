import 'dart:io';
import 'dart:typed_data';

import 'package:daway_app/features/accounting/domain/entities/accounting_overview.dart';
import 'package:daway_app/features/accounting/domain/entities/sale_invoice.dart';
import 'package:daway_app/features/accounting/presentation/helpers/invoice_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

ByteData _font(String name) =>
    ByteData.sublistView(File('assets/fonts/$name').readAsBytesSync());

void main() {
  test('builds a PDF with Arabic text and the invoice lines', () async {
    final invoice = SaleInvoice(
      id: 1,
      number: 'INV-1002',
      date: DateTime(2026, 11, 10, 14, 30),
      itemsCount: 1,
      subtotal: 50,
      discount: 0,
      total: 50,
      paid: 20,
      method: PaymentMethod.cash,
      lines: const [InvoiceLine(itemId: 1, name: 'أموكسيسيلين', quantity: 2, unitPrice: 25)],
    );

    final bytes = await buildInvoicePdf(
      invoice,
      regularFont: _font('Tajawal-Regular.ttf'),
      boldFont: _font('Tajawal-Bold.ttf'),
    );

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(2000));
  });

  test('builds one without lines (a list row whose details were not opened)', () async {
    final invoice = SaleInvoice(
      id: 2,
      number: 'INV-1003',
      date: DateTime(2026, 11, 10),
      itemsCount: 3,
      subtotal: 10,
      discount: 0,
      total: 10,
      paid: 10,
      method: PaymentMethod.cash,
    );

    final bytes = await buildInvoicePdf(
      invoice,
      regularFont: _font('Tajawal-Regular.ttf'),
      boldFont: _font('Tajawal-Bold.ttf'),
    );

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
