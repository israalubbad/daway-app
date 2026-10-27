import '../../../../core/helpers/api_result.dart';
import '../repositories/device_tokens_repository.dart';
import '../repositories/push_token_source.dart';

class UnregisterDeviceTokenUseCase {
  final DeviceTokensRepository _repository;
  final PushTokenSource _source;

  const UnregisterDeviceTokenUseCase(this._repository, this._source);

  Future<ApiResult<void>> call({required String authToken}) async {
    return _repository.unregister(
      authToken: authToken,
      deviceId: await _source.deviceId(),
    );
  }
}
