
enum OrderStatus {
  pending,
  confirmed,
  preparing,
  outForDelivery,
  delivered,
  cancelled;

  /// The backend's status word. Several spellings of "on the way" and
  /// "delivered" are accepted, since the exact words are the backend's to
  /// choose; anything unknown is treated as a new, unreviewed order.
  static OrderStatus fromApi(String value) => switch (value.toLowerCase()) {
        'pending' => OrderStatus.pending,
        'confirmed' => OrderStatus.confirmed,
        'preparing' || 'processing' => OrderStatus.preparing,
        'out_for_delivery' ||
        'on_the_way' ||
        'in_transit' ||
        'in_delivery' ||
        'delivering' ||
        'shipped' =>
          OrderStatus.outForDelivery,
        'delivered' || 'completed' || 'received' => OrderStatus.delivered,
        'cancelled' || 'canceled' => OrderStatus.cancelled,
        _ => OrderStatus.pending,
      };

  bool get isCancelled => this == OrderStatus.cancelled;
  bool get isCompleted => this == OrderStatus.delivered;
  bool get isInProgress => !isCancelled && !isCompleted;

  /// The server only cancels these three (see `POST /patient/orders/{id}/cancel`).
  bool get canCancel =>
      this == OrderStatus.pending ||
      this == OrderStatus.confirmed ||
      this == OrderStatus.preparing;
}

/// A patient's order, as returned by `GET /patient/orders`.
class Order {
  final String orderNumber;
  final String pharmacyName;
  final OrderStatus status;
  final int itemsCount;
  final double price;
  final String address;
  final DateTime createdAt;

  const Order({
    required this.orderNumber,
    required this.pharmacyName,
    required this.status,
    required this.itemsCount,
    required this.price,
    required this.address,
    required this.createdAt,
  });
}
