import '../../../../core/erroring/error_handler.dart';
import '../../../../core/helpers/api_result.dart';
import '../../domain/repositories/pharmacy_password_repository.dart';
import '../datasources/pharmacy_password_remote_data_source.dart';

class PharmacyPasswordRepositoryImpl implements PharmacyPasswordRepository {
  final PharmacyPasswordRemoteDataSource _remoteDataSource;

  const PharmacyPasswordRepositoryImpl(this._remoteDataSource);

  @override
  Future<ApiResult<void>> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _remoteDataSource.changePassword(
        token: token,
        body: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPassword,
        },
      );
      return const Success(null);
    } catch (e) {
      return ApiError(mapExceptionToFailure(e));
    }
  }
}
