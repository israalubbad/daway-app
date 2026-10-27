import 'package:daway_app/features/patient/domain/entities/order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderStatus.fromApi', () {
    test('reads each stage of an order', () {
      expect(OrderStatus.fromApi('pending'), OrderStatus.pending);
      expect(OrderStatus.fromApi('confirmed'), OrderStatus.confirmed);
      expect(OrderStatus.fromApi('preparing'), OrderStatus.preparing);
      expect(OrderStatus.fromApi('out_for_delivery'), OrderStatus.outForDelivery);
      expect(OrderStatus.fromApi('delivered'), OrderStatus.delivered);
      expect(OrderStatus.fromApi('cancelled'), OrderStatus.cancelled);
    });

    test('accepts the other spellings of "on the way" and "delivered"', () {
      for (final word in ['on_the_way', 'in_transit', 'in_delivery', 'delivering', 'shipped']) {
        expect(OrderStatus.fromApi(word), OrderStatus.outForDelivery, reason: word);
      }
      for (final word in ['completed', 'received', 'Delivered']) {
        expect(OrderStatus.fromApi(word), OrderStatus.delivered, reason: word);
      }
      expect(OrderStatus.fromApi('canceled'), OrderStatus.cancelled);
      expect(OrderStatus.fromApi('processing'), OrderStatus.preparing);
    });

    test('treats an unknown word as a new order', () {
      expect(OrderStatus.fromApi('something_new'), OrderStatus.pending);
      expect(OrderStatus.fromApi(''), OrderStatus.pending);
    });
  });

  group('OrderStatus flags', () {
    test('an order on the way is in progress and can no longer be cancelled', () {
      expect(OrderStatus.outForDelivery.isInProgress, isTrue);
      expect(OrderStatus.outForDelivery.canCancel, isFalse);
    });

    test('a delivered order is complete and a cancelled one is neither in progress nor complete',
        () {
      expect(OrderStatus.delivered.isCompleted, isTrue);
      expect(OrderStatus.delivered.isInProgress, isFalse);
      expect(OrderStatus.cancelled.isInProgress, isFalse);
      expect(OrderStatus.cancelled.isCompleted, isFalse);
    });
  });
}
