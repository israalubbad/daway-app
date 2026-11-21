import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../entities/pharmacy_profile.dart';
import '../repositories/pharmacy_profile_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

/// Reads the auth token from the local session (like the patient-side
/// equivalent does) so the cubit never has to know where the token comes from.
class GetPharmacyProfileUseCase {
  final PharmacyProfileRepository _repository;
  final SessionRepository _sessionRepository;

  const GetPharmacyProfileUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<PharmacyProfile>> call() {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.getProfile(token: token),
    );
  }
}
