import 'package:dio/dio.dart';

import '../../../../core/networking/auth_options.dart';
import '../../../../core/constants/api_constants.dart';

class PharmacyDashboardRemoteDataSource {
  final Dio _dio;

  const PharmacyDashboardRemoteDataSource(this._dio);

  Future<Response<dynamic>> getStats({required String token}) {
    return _dio.get(
      ApiConstants.pharmacyDashboardStats,
      options: authOptions(token),
    );
  }

  Future<Response<dynamic>> getSalesSummary({required String token}) {
    return _dio.get(
      ApiConstants.pharmacySalesSummary,
      queryParameters: {'range': 'month'},
      options: authOptions(token),
    );
  }

  Future<Response<dynamic>> getRatings({required String token}) {
    return _dio.get(
      ApiConstants.pharmacyRatings,
      queryParameters: {'per_page': 100},
      options: authOptions(token),
    );
  }

  Future<Response<dynamic>> getRecentInquiries({required String token}) {
    return _dio.get(
      ApiConstants.pharmacyInquiries,
      queryParameters: {'per_page': 3},
      options: authOptions(token),
    );
  }
}
