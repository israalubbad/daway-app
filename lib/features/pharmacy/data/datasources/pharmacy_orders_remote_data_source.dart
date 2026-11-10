import 'package:dio/dio.dart';

import '../../../../core/networking/auth_options.dart';
import '../../../../core/constants/api_constants.dart';

class PharmacyOrdersRemoteDataSource {
  final Dio _dio;

  const PharmacyOrdersRemoteDataSource(this._dio);

  Future<Response<dynamic>> getOrders({required String token}) {
    return _dio.get(
      ApiConstants.pharmacySubOrders,
      options: authOptions(token),
    );
  }

  Future<Response<dynamic>> getOrder({required String token, required int orderId}) {
    return _dio.get(
      '${ApiConstants.pharmacySubOrders}/$orderId',
      options: authOptions(token),
    );
  }
}
