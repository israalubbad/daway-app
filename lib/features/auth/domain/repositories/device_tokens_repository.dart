import '../../../../core/helpers/api_result.dart';

abstract class DeviceTokensRepository {
  /// `POST /device-tokens` — idempotent for the same (user, device id).
  Future<ApiResult<void>> register({
    required String authToken,
    required String fcmToken,
    required String deviceId,
    required String platform,
  });

  /// `DELETE /device-tokens/current` — stops pushes to this device.
  Future<ApiResult<void>> unregister({
    required String authToken,
    required String deviceId,
  });
}
