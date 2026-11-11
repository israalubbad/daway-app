import '../../../../core/erroring/error_handler.dart';
import '../../../../core/helpers/api_result.dart';
import '../../domain/repositories/device_tokens_repository.dart';
import '../datasources/device_tokens_remote_data_source.dart';

class DeviceTokensRepositoryImpl implements DeviceTokensRepository {
  final DeviceTokensRemoteDataSource _remoteDataSource;

  const DeviceTokensRepositoryImpl(this._remoteDataSource);

  @override
  Future<ApiResult<void>> register({
    required String authToken,
    required String fcmToken,
    required String deviceId,
    required String platform,
  }) {
    return guardApi(() async {
      await _remoteDataSource.register(
        authToken: authToken,
        fcmToken: fcmToken,
        deviceId: deviceId,
        platform: platform,
      );
      return const Success(null);
    });
  }

  @override
  Future<ApiResult<void>> unregister({
    required String authToken,
    required String deviceId,
  }) {
    return guardApi(() async {
      await _remoteDataSource.unregister(authToken: authToken, deviceId: deviceId);
      return const Success(null);
    });
  }
}
