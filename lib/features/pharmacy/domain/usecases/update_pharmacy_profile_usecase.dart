import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../entities/pharmacy_profile.dart';
import '../repositories/pharmacy_profile_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class UpdatePharmacyProfileUseCase {
  final PharmacyProfileRepository _repository;
  final SessionRepository _sessionRepository;

  const UpdatePharmacyProfileUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<void>> call(PharmacyProfile profile) {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.updateProfile(token: token, profile: profile),
    );
  }
}
