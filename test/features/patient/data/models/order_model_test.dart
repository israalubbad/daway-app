import 'package:daway_app/features/patient/data/models/order_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads a normal order row', () {
    final order = OrderModel.fromJson({
      'id': 12,
      'status': 'confirmed',
      'items_count': 3,
      'total': 45.5,
      'pharmacy': {'name': 'صيدلية النور'},
      'address': {'address': 'غزة'},
      'created_at': '2026-10-25T10:00:00Z',
    }).toEntity();

    expect(order.orderNumber, '12');
    expect(order.pharmacyName, 'صيدلية النور');
    expect(order.price, 45.5);
    expect(order.address, 'غزة');
  });

  test('a total sent as a decimal string, or as grand_total, is read', () {
    expect(OrderModel.fromJson({'id': 1, 'total': '45.50'}).toEntity().price, 45.5);
    expect(OrderModel.fromJson({'id': 1, 'grand_total': '60.00'}).toEntity().price, 60.0);
  });

  test('wrong types read as missing instead of throwing', () {
    final order = OrderModel.fromJson({
      'id': '9',
      'status': 7,
      'items_count': 'x',
      'pharmacy': 'النور',
      'address': [1],
      'created_at': 5,
    }).toEntity();

    expect(order.orderNumber, '9');
    expect(order.pharmacyName, '');
    expect(order.itemsCount, 0);
    expect(order.address, '');
  });
}
