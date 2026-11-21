import '../../../../core/helpers/json_parsing.dart';
import '../../domain/entities/checkout_quote.dart';

/// The `data` of `POST /patient/checkout/quote`. Amounts may arrive as numbers
/// or as decimal strings; the delivery fee and the grand total are the two the
/// order is guarded by, so a response without them is rejected rather than
/// guessed at.
class CheckoutQuoteModel {
  const CheckoutQuoteModel._();

  static CheckoutQuote fromJson(Map<String, dynamic> json) {
    final deliveryFee = jsonDouble(json['delivery_fee']);
    final grandTotal = jsonDouble(json['grand_total']);
    if (deliveryFee == null || grandTotal == null) {
      throw FormatException('Checkout quote without delivery_fee/grand_total: $json');
    }
    final discount = jsonDouble(json['discount']) ?? 0;
    final total = jsonDouble(json['total']) ?? grandTotal - deliveryFee;
    return CheckoutQuote(
      subtotal: jsonDouble(json['subtotal']) ?? total + discount,
      discount: discount,
      total: total,
      deliveryFee: deliveryFee.round(),
      grandTotal: grandTotal,
      distanceMeters: jsonInt(json['distance_meters']),
      pricingMode: jsonString(json['pricing_mode']),
      tierId: jsonInt(json['tier_id']),
    );
  }
}
