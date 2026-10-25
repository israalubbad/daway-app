import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';

class AssistantRemoteDataSource {
  final Dio _dio;

  const AssistantRemoteDataSource(this._dio);

  Future<Response<dynamic>> sendMessage({
    required String token,
    required String message,
    double? latitude,
    double? longitude,
  }) {
    return _dio.post(
      ApiConstants.patientAssistantChat,
      data: {
        'message': message,
        'latitude': ?latitude,
        'longitude': ?longitude,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }
}
