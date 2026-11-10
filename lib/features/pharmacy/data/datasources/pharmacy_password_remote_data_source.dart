import 'package:dio/dio.dart';

import '../../../../core/networking/auth_options.dart';
import '../../../../core/constants/api_constants.dart';

class PharmacyPasswordRemoteDataSource {
  final Dio _dio;

  const PharmacyPasswordRemoteDataSource(this._dio);

  Future<Response<dynamic>> changePassword({
    required String token,
    required Map<String, dynamic> body,
  }) {
    return _dio.post(
      ApiConstants.pharmacyChangePassword,
      data: body,
      options: authOptions(token),
    );
  }
}
