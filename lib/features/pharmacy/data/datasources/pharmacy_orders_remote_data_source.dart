import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';

class PharmacyOrdersRemoteDataSource {
  final Dio _dio;

  const PharmacyOrdersRemoteDataSource(this._dio);

  Future<Response<dynamic>> getOrders({required String token}) {
    return _dio.get(
      ApiConstants.pharmacySubOrders,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<Response<dynamic>> updateStatus({
    required String token,
    required int orderId,
    required String status,
  }) {
    return _dio.post(
      '${ApiConstants.pharmacySubOrders}/$orderId/status',
      data: {'status': status},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }
}
