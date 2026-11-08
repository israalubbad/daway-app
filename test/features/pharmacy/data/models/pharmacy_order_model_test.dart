import 'package:daway_app/features/pharmacy/data/models/pharmacy_order_model.dart';
import 'package:daway_app/features/pharmacy/domain/entities/pharmacy_order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads the id, number, items, address and payment of a sub-order', () {
    final order = PharmacyOrderModel.fromJson({
      'id': 7,
      'status': 'pending',
      'total': '18.50',
      'created_at': '2026-10-27T10:00:00Z',
      'order': {'order_number': 'DW-1022'},
      'items': [
        {'medicine': {'name': 'أموكسيسيلين'}, 'unit_price': 9.25, 'quantity': 2},
      ],
      'address': {'area': 'غزة - الشجاعية', 'street': 'شارع الجلاء'},
      'payment': {'method': 'محفظة', 'status': 'paid'},
    }).order;

    expect(order.id, 7);
    expect(order.status, PharmacyOrderStatus.pending);
    expect(order.orderNumber, 'DW-1022');
    expect(order.total, 18.5);
    expect(order.itemsCount, 1);
    expect(order.items.single.name, 'أموكسيسيلين');
    expect(order.items.single.price, 18.5);
    expect(order.area, 'غزة - الشجاعية');
    expect(order.deliveryStreet, 'شارع الجلاء');
    expect(order.payment!.isPaid, isTrue);
  });

  test('a bare record still parses, with the id as its number', () {
    final order = PharmacyOrderModel.fromJson({'id': 3}).order;

    expect(order.orderNumber, '3');
    expect(order.status, PharmacyOrderStatus.pending);
    expect(order.items, isEmpty);
    expect(order.payment, isNull);
  });

  test('decided statuses are recognised', () {
    expect(
      PharmacyOrderModel.fromJson({'id': 1, 'status': 'accepted'}).order.status,
      PharmacyOrderStatus.accepted,
    );
    expect(
      PharmacyOrderModel.fromJson({'id': 1, 'status': 'rejected'}).order.status,
      PharmacyOrderStatus.rejected,
    );
  });

  test('a record without an id is refused', () {
    expect(() => PharmacyOrderModel.fromJson({'status': 'pending'}), throwsFormatException);
  });

  test('a list record with only items_count keeps the count', () {
    final order = PharmacyOrderModel.fromJson({'id': 4, 'items_count': 3, 'total': 60}).order;

    expect(order.itemsCount, 3);
    expect(order.items, isEmpty);
  });

  test('lines, when present, win over items_count', () {
    final order = PharmacyOrderModel.fromJson({
      'id': 4,
      'items_count': 9,
      'items': [
        {'name': 'a', 'price': 5},
      ],
    }).order;

    expect(order.itemsCount, 1);
  });

  test('a timestamp with no zone is read as the server clock (UTC)', () {
    final order = PharmacyOrderModel.fromJson({'id': 4, 'created_at': '2026-10-25 12:38:00'}).order;

    expect(order.createdAt, DateTime.utc(2026, 10, 25, 12, 38).toLocal());
  });
}
