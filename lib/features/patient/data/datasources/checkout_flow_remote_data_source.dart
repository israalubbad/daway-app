import 'package:dio/dio.dart';
import '../../../../core/networking/auth_options.dart';

import '../../../../core/constants/api_constants.dart';

class CheckoutFlowRemoteDataSource {
  final Dio _dio;

  const CheckoutFlowRemoteDataSource(this._dio);


  String _order(int orderId) => '${ApiConstants.patientOrders}/$orderId';

  Future<Response<dynamic>> validateCoupon({
    required String token,
    required String code,
    required double orderTotal,
  }) {
    return _dio.post(
      ApiConstants.patientCouponsValidate,
      data: {'code': code, 'order_total': orderTotal},
      options: authOptions(token),
    );
  }

  Future<Response<dynamic>> getPayment({
    required String token,
    required int orderId,
  }) {
    return _dio.get('${_order(orderId)}/payment', options: authOptions(token));
  }

  Future<Response<dynamic>> getPaymentBanks({required String token}) {
    return _dio.get(ApiConstants.patientPaymentBanks, options: authOptions(token));
  }

  Future<Response<dynamic>> submitReceipt({
    required String token,
    required int orderId,
    required int bankId,
    required double amount,
    required String receiptPath,
  }) async {
    final form = FormData.fromMap({
      'bank_id': bankId,
      'amount': amount,
      'receipt': await MultipartFile.fromFile(receiptPath),
    });
    return _dio.post(
      '${_order(orderId)}/payment/receipt',
      data: form,
      options: authOptions(token),
    );
  }

  Future<Response<dynamic>> reportProblem({
    required String token,
    required int orderId,
    required String message,
  }) {
    return _dio.post(
      '${_order(orderId)}/payment/problem',
      data: {'category': 'other', 'message': message},
      options: authOptions(token),
    );
  }

  Future<Response<dynamic>> getTracking({
    required String token,
    required int orderId,
  }) {
    return _dio.get('${_order(orderId)}/tracking', options: authOptions(token));
  }
}
