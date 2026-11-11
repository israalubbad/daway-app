import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../repositories/pharmacy_password_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class ChangePharmacyPasswordUseCase {
  final PharmacyPasswordRepository _repository;
  final SessionRepository _sessionRepository;

  const ChangePharmacyPasswordUseCase(
    this._repository,
    this._sessionRepository,
  );

  Future<ApiResult<void>> call({
    required String currentPassword,
    required String newPassword,
  }) {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.changePassword(
        token: token,
        currentPassword: currentPassword,
        newPassword: newPassword,
      ),
    );
  }
}
