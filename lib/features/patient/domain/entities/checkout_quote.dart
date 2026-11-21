/// What the server says the cart costs to deliver to an address
/// (`POST /patient/checkout/quote`), before any order exists. Checkout sends
/// these numbers back so the server can refuse the order if the price moved
/// while the patient was looking at it.
class CheckoutQuote {
  /// The cart's price, before the coupon.
  final double subtotal;

  /// What the coupon takes off. 0 without one.
  final double discount;

  /// The cart's price after the coupon, before delivery.
  final double total;

  /// The delivery fee, a whole amount.
  final int deliveryFee;

  /// What the patient pays: [total] plus [deliveryFee].
  final double grandTotal;

  final int? distanceMeters;

  /// How the server priced the delivery (a flat fee or by distance tier).
  final String? pricingMode;
  final int? tierId;

  const CheckoutQuote({
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.deliveryFee,
    required this.grandTotal,
    this.distanceMeters,
    this.pricingMode,
    this.tierId,
  });
}
