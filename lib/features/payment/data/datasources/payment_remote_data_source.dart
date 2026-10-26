import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';

class PaymentRemoteDataSource {
  final Dio _dio;

  const PaymentRemoteDataSource(this._dio);

  Options _auth(String token) => Options(headers: {'Authorization': 'Bearer $token'});

  Future<Response<dynamic>> getBanks({required String token}) =>
      _dio.get(ApiConstants.patientPaymentBanks, options: _auth(token));

  Future<Response<dynamic>> getPayment({required String token, required int orderId}) =>
      _dio.get('${ApiConstants.patientOrders}/$orderId/payment', options: _auth(token));

  Future<Response<dynamic>> submitReceipt({
    required String token,
    required int orderId,
    required int bankId,
    required double amount,
    required String senderName,
    required String transferReference,
    required File receipt,
  }) async {
    final form = FormData.fromMap({
      'bank_id': bankId,
      'amount': amount,
      'sender_name': senderName,
      'transfer_reference': transferReference,
      'receipt': await MultipartFile.fromFile(receipt.path),
    });
    return _dio.post(
      '${ApiConstants.patientOrders}/$orderId/payment/receipt',
      data: form,
      options: _auth(token),
    );
  }

  Future<Response<dynamic>> reportProblem({
    required String token,
    required int orderId,
    required String category,
    required String message,
    required int submissionId,
  }) =>
      _dio.post(
        '${ApiConstants.patientOrders}/$orderId/payment/problem',
        data: {'category': category, 'message': message, 'submission_id': submissionId},
        options: _auth(token),
      );

  Future<Response<dynamic>> validateCoupon({
    required String token,
    required String code,
    required double orderTotal,
  }) =>
      _dio.post(
        ApiConstants.patientCouponsValidate,
        data: {'code': code, 'order_total': orderTotal},
        options: _auth(token),
      );

  Future<Response<dynamic>> getTracking({required String token, required int orderId}) =>
      _dio.get('${ApiConstants.patientOrders}/$orderId/tracking', options: _auth(token));
}
