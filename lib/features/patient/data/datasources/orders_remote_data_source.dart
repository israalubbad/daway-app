import 'package:dio/dio.dart';

import '../../../../core/networking/auth_options.dart';
import '../../../../core/constants/api_constants.dart';

class OrdersRemoteDataSource {
  final Dio _dio;

  const OrdersRemoteDataSource(this._dio);

  Future<Response<dynamic>> getOrders({required String token, int page = 1}) {
    return _dio.get(
      ApiConstants.patientOrders,
      queryParameters: {'page': page},
      options: authOptions(token),
    );
  }

  Future<Response<dynamic>> cancelOrder({required String token, required int orderId}) {
    return _dio.post(
      '${ApiConstants.patientOrders}/$orderId/cancel',
      options: authOptions(token),
    );
  }

  /// The price of the cart delivered to [addressId]; read-only, nothing is
  /// created. [couponCode] is sent as null when there is none, as the
  /// collection does.
  Future<Response<dynamic>> getCheckoutQuote({
    required String token,
    required int addressId,
    String? couponCode,
  }) {
    return _dio.post(
      ApiConstants.patientCheckoutQuote,
      data: {'address_id': addressId, 'coupon_code': couponCode},
      options: authOptions(token),
    );
  }

  /// The three `quoted*` amounts and [idempotencyKey] go together: with them
  /// the server refuses the order (409) if its price has moved since the
  /// quote, and a repeated key never creates a second order.
  Future<Response<dynamic>> checkout({
    required String token,
    required int addressId,
    String? couponCode,
    String? notes,
    int? quotedDeliveryFee,
    double? quotedDiscount,
    double? quotedGrandTotal,
    String? idempotencyKey,
  }) {
    return _dio.post(
      ApiConstants.patientCheckout,
      data: {
        'address_id': addressId,
        'coupon_code': ?couponCode,
        'notes': ?notes,
        'quoted_delivery_fee': ?quotedDeliveryFee,
        'quoted_discount': ?quotedDiscount,
        'quoted_grand_total': ?quotedGrandTotal,
        'idempotency_key': ?idempotencyKey,
      },
      options: authOptions(token),
    );
  }
}
