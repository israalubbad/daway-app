import '../../../../core/helpers/api_result.dart';
import '../entities/checkout_flow.dart';

/// Everything around placing an order that the order list does not cover:
/// the coupon, the payment (banks, receipt, problem report) and the tracking.
abstract class CheckoutFlowRepository {
  /// `POST /patient/coupons/validate` — the discount the code gives on an
  /// order of [orderTotal]. A bad / expired / too-small-order code is an
  /// ApiError carrying the server's message.
  Future<ApiResult<double>> validateCoupon({
    required String token,
    required String code,
    required double orderTotal,
  });

  /// `GET /patient/orders/{id}/payment`.
  Future<ApiResult<OrderPayment>> getPayment({
    required String token,
    required int orderId,
  });

  /// `POST /patient/orders/{id}/payment/receipt` (multipart). Success means
  /// the receipt is under review, not that the payment was approved.
  Future<ApiResult<void>> submitReceipt({
    required String token,
    required int orderId,
    required int bankId,
    required double amount,
    required String receiptPath,
  });

  /// `POST /patient/orders/{id}/payment/problem` — for a patient who cannot
  /// upload the receipt and wants to hand the transfer details over instead.
  Future<ApiResult<void>> reportProblem({
    required String token,
    required int orderId,
    required String message,
  });

  /// `GET /patient/orders/{id}/tracking`.
  Future<ApiResult<OrderTracking>> getTracking({
    required String token,
    required int orderId,
  });
}
