import '../../../../core/erroring/failure.dart';
import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../repositories/pharmacy_password_repository.dart';

class ChangePharmacyPasswordUseCase {
  final PharmacyPasswordRepository _repository;
  final SessionRepository _sessionRepository;

  const ChangePharmacyPasswordUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<void>> call({
    required String currentPassword,
    required String newPassword,
  }) async {
    final session = await _sessionRepository.getSession();
    if (session == null) {
      return ApiError(
        ApiFailure(message: sessionExpiredMessage),
      );
    }
    return _repository.changePassword(
      token: session.token,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}
