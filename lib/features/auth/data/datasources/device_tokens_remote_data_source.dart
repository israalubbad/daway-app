import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';

class DeviceTokensRemoteDataSource {
  final Dio _dio;

  const DeviceTokensRemoteDataSource(this._dio);

  Options _auth(String token) => Options(headers: {'Authorization': 'Bearer $token'});

  /// 201 when new, 200 when updated; both are success.
  Future<Response<dynamic>> register({
    required String authToken,
    required String fcmToken,
    required String deviceId,
    required String platform,
  }) {
    return _dio.post(
      ApiConstants.deviceTokens,
      data: {'token': fcmToken, 'platform': platform, 'device_id': deviceId},
      options: _auth(authToken),
    );
  }

  Future<Response<dynamic>> unregister({
    required String authToken,
    required String deviceId,
  }) {
    return _dio.delete(
      ApiConstants.deviceTokensCurrent,
      data: {'device_id': deviceId},
      options: _auth(authToken),
    );
  }
}
