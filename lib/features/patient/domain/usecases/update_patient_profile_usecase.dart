import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../entities/patient_profile.dart';
import '../repositories/patient_profile_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

/// Reads the auth token from the local session (like [LogoutUseCase] does)
/// so the cubit never has to know where the token comes from.
class UpdatePatientProfileUseCase {
  final PatientProfileRepository _repository;
  final SessionRepository _sessionRepository;

  const UpdatePatientProfileUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<void>> call(PatientProfile profile) {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.updateProfile(token: token, profile: profile),
    );
  }
}
