import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';

/// The pharmacy accounting endpoints (`/pharmacy/accounting/*`), as the
/// "Pharmacy Accounting + Barcode Scanner" Postman collection documents them.
class AccountingRemoteDataSource {
  final Dio _dio;

  const AccountingRemoteDataSource(this._dio);

  static const _base = ApiConstants.pharmacyAccounting;

  Options _auth(String token, {Duration? receiveTimeout}) => Options(
    headers: {'Authorization': 'Bearer $token'},
    receiveTimeout: receiveTimeout,
  );

  /// The heaviest call of the API: 17 to 62 seconds on the hosted database, so
  /// the client waits up to 90.
  Future<Response<dynamic>> getOverview({required String token, required String range}) {
    return _dio.get(
      '$_base/overview',
      queryParameters: {'range': range},
      options: _auth(token, receiveTimeout: const Duration(seconds: 90)),
    );
  }

  Future<Response<dynamic>> getSales({required String token, required int page}) {
    return _dio.get(
      '$_base/sales',
      queryParameters: {'per_page': 100, 'page': page},
      options: _auth(token),
    );
  }

  Future<Response<dynamic>> getSale({required String token, required String number}) {
    return _dio.get('$_base/sales/$number', options: _auth(token));
  }

  Future<Response<dynamic>> getRefundItems({required String token, required String number}) {
    return _dio.get('$_base/sales/$number/refund-items', options: _auth(token));
  }

  Future<Response<dynamic>> createSale({
    required String token,
    required Map<String, dynamic> body,
  }) {
    return _dio.post('$_base/sales', data: body, options: _auth(token));
  }

  Future<Response<dynamic>> getRefunds({required String token}) {
    return _dio.get('$_base/refunds', options: _auth(token));
  }

  Future<Response<dynamic>> createRefund({
    required String token,
    required Map<String, dynamic> body,
  }) {
    return _dio.post('$_base/refunds', data: body, options: _auth(token));
  }

  /// Without a date filter the cash book answers only this month, so the
  /// request asks from a date far enough back to mean "everything".
  Future<Response<dynamic>> getCash({required String token}) {
    return _dio.get(
      '$_base/cash',
      queryParameters: {'per_page': 100, 'from': '2020-01-01'},
      options: _auth(token),
    );
  }

  Future<Response<dynamic>> createCashAdjustment({
    required String token,
    required Map<String, dynamic> body,
  }) {
    return _dio.post('$_base/cash/adjustments', data: body, options: _auth(token));
  }

  Future<Response<dynamic>> getBarcode({required String token, required String barcode}) {
    return _dio.get('$_base/barcode/$barcode', options: _auth(token));
  }

  /// The pharmacy's own stock, searched by name (two characters at least).
  Future<Response<dynamic>> searchMedicines({required String token, required String query}) {
    return _dio.get(
      ApiConstants.pharmacyMedicinesSearch,
      queryParameters: {'q': query},
      options: _auth(token),
    );
  }

  Future<Response<dynamic>> getCustomers({required String token, required String search}) {
    return _dio.get(
      '$_base/customers',
      queryParameters: {'per_page': 10, 'search': search},
      options: _auth(token),
    );
  }

  Future<Response<dynamic>> createCustomerPayment({
    required String token,
    required int customerId,
    required Map<String, dynamic> body,
  }) {
    return _dio.post('$_base/customers/$customerId/payments', data: body, options: _auth(token));
  }
}
