import 'package:daway_app/core/widgets/app_custom_button.dart';
import 'package:daway_app/core/widgets/header_icon_button.dart';
import 'package:daway_app/features/pharmacy/domain/entities/pharmacy_order.dart';
import 'package:daway_app/features/pharmacy/presentation/screens/pharmacy_order_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/arabic_test_app.dart';

final _order = PharmacyOrder(
  orderNumber: 'DW-1022',
  createdAt: DateTime.now(),
  itemsCount: 1,
  total: 18,
  area: 'غزة - الشجاعية',
  items: const [PharmacyOrderItem(name: 'أموكسيسيلين 500 مج', price: 18)],
  deliveryStreet: 'شارع الجلاء، مبنى رقم 14، شقة 3',
  payment: const PharmacyOrderPayment(
    method: 'محفظة إلكترونية',
    detail: 'فوري باي · ****4827',
    isPaid: true,
  ),
);

void main() {
  Future<void> pumpScreen(
    WidgetTester tester, {
    PharmacyOrder? order,
    PharmacyOrderLoader? onLoadDetails,
  }) async {
    await setDesignViewport(tester);
    await tester.pumpWidget(
      buildArabicTestApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PharmacyOrderDetailsScreen(
                    order: order ?? _order,
                    onLoadDetails: onLoadDetails,
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the order summary: number, strip and time', (tester) async {
    await pumpScreen(tester);

    expect(find.text('تفاصيل الطلب'), findsOneWidget);
    expect(find.text('راجع تفاصيل طلب العميل'), findsOneWidget);
    expect(find.text('#DW-1022'), findsOneWidget);
    expect(find.text('دواء واحد'), findsOneWidget);
    // In the strip, and again as the delivery address's area.
    expect(find.text('غزة - الشجاعية'), findsNWidgets(2));
    expect(find.textContaining('اليوم'), findsOneWidget);
  });

  testWidgets('shows each medicine with its price and availability', (tester) async {
    await pumpScreen(tester);

    expect(find.text('أموكسيسيلين 500 مج'), findsOneWidget);
    expect(find.text('متوفر'), findsOneWidget);
    // The strip shows the order total and the card the medicine's price.
    expect(find.text('18 ₪'), findsNWidgets(2));
  });

  testWidgets('an item the pharmacy has run out of says نافد', (tester) async {
    await pumpScreen(
      tester,
      order: PharmacyOrder(
        orderNumber: 'DW-1',
        createdAt: DateTime.now(),
        itemsCount: 1,
        total: 5,
        area: 'غزة',
        items: const [PharmacyOrderItem(name: 'دواء', price: 5, isAvailable: false)],
      ),
    );

    expect(find.text('نافد'), findsOneWidget);
    expect(find.text('متوفر'), findsNothing);
  });

  testWidgets('shows the delivery address and the payment', (tester) async {
    await pumpScreen(tester);

    await tester.ensureVisible(find.text('طريقة الدفع'));
    expect(find.text('عنوان التوصيل'), findsOneWidget);
    expect(find.text('شارع الجلاء، مبنى رقم 14، شقة 3'), findsOneWidget);
    expect(find.text('طريقة الدفع'), findsOneWidget);
    expect(find.text('مدفوع'), findsOneWidget);
    expect(find.text('محفظة إلكترونية'), findsOneWidget);
    expect(find.text('فوري باي · ****4827'), findsOneWidget);
  });

  testWidgets('an unpaid order says غير مدفوع', (tester) async {
    await pumpScreen(
      tester,
      order: PharmacyOrder(
        orderNumber: 'DW-2',
        createdAt: DateTime.now(),
        itemsCount: 1,
        total: 5,
        area: 'غزة',
        payment: const PharmacyOrderPayment(method: 'الدفع عند الاستلام', isPaid: false),
      ),
    );

    await tester.ensureVisible(find.text('طريقة الدفع'));
    expect(find.text('غير مدفوع'), findsOneWidget);
    expect(find.text('مدفوع'), findsNothing);
  });

  testWidgets('an order with no payment information has no payment card', (tester) async {
    await pumpScreen(
      tester,
      order: PharmacyOrder(
        orderNumber: 'DW-3',
        createdAt: DateTime.now(),
        itemsCount: 1,
        total: 5,
        area: 'غزة',
      ),
    );

    expect(find.text('طريقة الدفع'), findsNothing);
  });

  testWidgets('a pending order has no accept or reject buttons', (tester) async {
    await pumpScreen(tester);

    expect(find.text('قبول الطلب'), findsNothing);
    expect(find.text('رفض الطلب'), findsNothing);
    expect(find.byType(AppCustomButton), findsNothing);
  });

  testWidgets('shows the full record fetched on open', (tester) async {
    await pumpScreen(
      tester,
      onLoadDetails: (order) async => PharmacyOrder(
        id: order.id,
        orderNumber: order.orderNumber,
        createdAt: order.createdAt,
        itemsCount: 1,
        total: 12,
        area: order.area,
        patientName: 'أحمد',
        items: const [PharmacyOrderItem(name: 'بنادول', price: 12, quantity: 3, unitPrice: 4)],
      ),
    );

    expect(find.text('العميل: أحمد'), findsOneWidget);
    expect(find.text('بنادول'), findsOneWidget);
    expect(find.textContaining('الكمية: 3'), findsOneWidget);
  });

  testWidgets('keeps the list data when the full record cannot be fetched', (tester) async {
    await pumpScreen(tester, onLoadDetails: (order) async => null);

    expect(find.text('أموكسيسيلين 500 مج'), findsOneWidget);
  });

  testWidgets('the back chip returns to the previous screen', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byType(HeaderIconButton));
    await tester.pumpAndSettle();

    expect(find.text('تفاصيل الطلب'), findsNothing);
  });
}
