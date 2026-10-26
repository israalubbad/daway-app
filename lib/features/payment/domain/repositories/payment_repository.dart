import 'dart:io';

import '../../../../core/helpers/api_result.dart';
import '../entities/payment.dart';

abstract class PaymentRepository {
  /// `GET /patient/payment-banks` — the active bank accounts to transfer to.
  Future<ApiResult<List<PaymentBank>>> getBanks({required String token});

  /// `GET /patient/orders/{id}/payment`.
  Future<ApiResult<PaymentSummary>> getPayment({required String token, required int orderId});

  /// `POST /patient/orders/{id}/payment/receipt` (multipart). Success means
  /// the receipt is *under review*, not that it was approved.
  Future<ApiResult<void>> submitReceipt({
    required String token,
    required int orderId,
    required int bankId,
    required double amount,
    required String senderName,
    required String transferReference,
    File? receipt,
  });

  /// `POST /patient/orders/{id}/payment/problem`.
  Future<ApiResult<void>> reportProblem({
    required String token,
    required int orderId,
    required String message,
    required int submissionId,
    String category = 'other',
  });

  /// `POST /patient/coupons/validate` — the discount the server would give on
  /// [orderTotal]. 404/422 (unknown, expired, minimum not met) come back as an
  /// ApiError carrying the server message.
  Future<ApiResult<double>> validateCoupon({
    required String token,
    required String code,
    required double orderTotal,
  });

  /// `GET /patient/orders/{id}/tracking` — the parent order's status timeline.
  Future<ApiResult<OrderTracking>> getTracking({required String token, required int orderId});
}
