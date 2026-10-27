import '../../../../core/helpers/api_result.dart';
import '../repositories/device_tokens_repository.dart';
import '../repositories/push_token_source.dart';

class RegisterDeviceTokenUseCase {
  final DeviceTokensRepository _repository;
  final PushTokenSource _source;

  const RegisterDeviceTokenUseCase(this._repository, this._source);

  /// No-op (success) when the device has no push token yet.
  Future<ApiResult<void>> call({required String authToken, String? fcmToken}) async {
    final token = fcmToken ?? await _source.fcmToken();
    if (token == null || token.isEmpty) return const Success(null);
    return _repository.register(
      authToken: authToken,
      fcmToken: token,
      deviceId: await _source.deviceId(),
      platform: _source.platform,
    );
  }
}
