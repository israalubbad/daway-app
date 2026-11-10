import '../../../../core/helpers/api_result.dart';
import '../entities/checkout_quote.dart';
import '../entities/order.dart';

abstract class OrdersRepository {
  Future<ApiResult<List<Order>>> getOrders({required String token});

  /// `POST /patient/orders/{id}/cancel` — only pending, confirmed and
  /// preparing orders can be cancelled; the server 422s otherwise and that
  /// message is surfaced as an ApiError.
  Future<ApiResult<void>> cancelOrder({required String token, required int orderId});

  /// What the cart costs delivered to [addressId], with [couponCode] applied
  /// (`POST /patient/checkout/quote`, read-only). The server answers 422 when
  /// delivery pricing is switched off — surfaced as an ApiError, which the
  /// checkout treats as "no quote": the order is then made without a guard.
  Future<ApiResult<CheckoutQuote>> getCheckoutQuote({
    required String token,
    required int addressId,
    String? couponCode,
  });

  /// Creates an order from the patient's current cart. Returns the new
  /// order's id. 422s if the cart is empty, the address isn't the caller's,
  /// or an item is no longer available — surfaced as an ApiError message.
  ///
  /// With a [quote] (and its [idempotencyKey]) the server also refuses the
  /// order with a 409 when the price has changed since the quote was read, and
  /// answers a repeat of the same key with the order it already made.
  Future<ApiResult<int>> checkout({
    required String token,
    required int addressId,
    String? couponCode,
    String? notes,
    CheckoutQuote? quote,
    String? idempotencyKey,
  });
}
