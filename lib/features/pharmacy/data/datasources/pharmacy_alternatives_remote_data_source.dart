import 'package:dio/dio.dart';

import '../../../../core/networking/auth_options.dart';
import '../../../../core/constants/api_constants.dart';

class PharmacyAlternativesRemoteDataSource {
  final Dio _dio;

  const PharmacyAlternativesRemoteDataSource(this._dio);

  Future<Response<dynamic>> getCandidates({
    required String token,
    required int pharmacyMedicineId,
  }) {
    return _dio.get(
      '${ApiConstants.pharmacyMedicines}/$pharmacyMedicineId/alternatives',
      options: authOptions(token),
    );
  }

  /// `per_page` matches the cap every other list endpoint in this app
  /// sends — the live response for this one didn't include a `pagination`
  /// object even with it, so it may be unpaginated regardless; harmless to
  /// send either way; sent for the day it isn't.
  Future<Response<dynamic>> getLinks({required String token}) {
    return _dio.get(
      ApiConstants.pharmacyAlternatives,
      queryParameters: {'per_page': 100},
      options: authOptions(token),
    );
  }

  Future<Response<dynamic>> create({
    required String token,
    required int baseMedicineId,
    required int alternativeId,
  }) {
    return _dio.post(
      ApiConstants.pharmacyAlternatives,
      data: {
        'base_medicine_id': baseMedicineId,
        'alternative_id': alternativeId,
      },
      options: authOptions(token),
    );
  }

  Future<Response<dynamic>> delete({
    required String token,
    required int baseMedicineId,
    required int alternativeId,
  }) {
    return _dio.delete(
      '${ApiConstants.pharmacyAlternatives}/$baseMedicineId/$alternativeId',
      options: authOptions(token),
    );
  }
}
