import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/networking/auth_options.dart';
import '../../../../core/networking/session_expired_interceptor.dart';

class DeviceTokensRemoteDataSource {
  final Dio _dio;

  const DeviceTokensRemoteDataSource(this._dio);

  /// Removing the token happens while the session ends, with a token the
  /// server may already have revoked: that 401 is not an expired session.
  Options _endingSession(String token) => Options(
        headers: {'Authorization': 'Bearer $token'},
        extra: {skipSessionExpiryKey: true},
      );

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
      options: authOptions(authToken),
    );
  }

  Future<Response<dynamic>> unregister({
    required String authToken,
    required String deviceId,
  }) {
    return _dio.delete(
      ApiConstants.deviceTokensCurrent,
      data: {'device_id': deviceId},
      options: _endingSession(authToken),
    );
  }
}
