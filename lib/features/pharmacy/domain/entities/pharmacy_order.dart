/// Where a sub-order stands with the pharmacy.
enum PharmacyOrderStatus { pending, accepted, rejected, other }

/// An order a patient placed with the pharmacy (`GET /pharmacy/sub-orders`),
/// as the home screen's "الطلبات" cards and the order-details screen show it.
class PharmacyOrder {
  /// The sub-order's id, what the decision is sent against.
  final int id;
  final PharmacyOrderStatus status;

  /// Without the leading "#" ("DW-1021").
  final String orderNumber;

  /// In local time — a UTC timestamp from the API has to be converted first:
  /// the card's "منذ 5 د" / "أمس" compares calendar dates, which a UTC value
  /// would put on the wrong day around midnight.
  final DateTime createdAt;
  final int itemsCount;

  /// In shekels.
  final double total;

  /// Where it is going ("غزة - النصر").
  final String area;

  /// What was ordered. The list cards only need [itemsCount], so an order
  /// without its lines (a list response that leaves them out) is still valid.
  final List<PharmacyOrderItem> items;

  /// The street line of the delivery address ("شارع الجلاء، مبنى رقم 14، شقة 3").
  final String? deliveryStreet;

  /// Null when the order carries no payment information.
  final PharmacyOrderPayment? payment;

  /// Who placed the order; null when the API does not say.
  final String? patientName;

  /// This order with another [status] — what a decision turns it into.
  PharmacyOrder withStatus(PharmacyOrderStatus status) => PharmacyOrder(
    id: id,
    status: status,
    orderNumber: orderNumber,
    createdAt: createdAt,
    itemsCount: itemsCount,
    total: total,
    area: area,
    items: items,
    deliveryStreet: deliveryStreet,
    payment: payment,
    patientName: patientName,
  );

  const PharmacyOrder({
    this.id = 0,
    this.status = PharmacyOrderStatus.pending,
    required this.orderNumber,
    required this.createdAt,
    required this.itemsCount,
    required this.total,
    required this.area,
    this.items = const [],
    this.deliveryStreet,
    this.payment,
    this.patientName,
  });
}

/// One medicine on an order.
class PharmacyOrderItem {
  final String name;

  /// The line's total in shekels (unit price × [quantity]).
  final double price;
  final String? imageUrl;

  /// How many of it were ordered.
  final int quantity;

  /// One unit's price in shekels, when the API gives it.
  final double? unitPrice;

  /// Whether the pharmacy has it in stock right now.
  final bool isAvailable;

  const PharmacyOrderItem({
    required this.name,
    required this.price,
    this.imageUrl,
    this.quantity = 1,
    this.unitPrice,
    this.isAvailable = true,
  });
}

/// How an order is paid, and whether it already has been.
class PharmacyOrderPayment {
  /// "محفظة إلكترونية".
  final String method;

  /// Extra line under the method ("فوري باي · ****4827"), when there is one.
  final String? detail;
  final bool isPaid;

  const PharmacyOrderPayment({required this.method, this.detail, required this.isPaid});
}
