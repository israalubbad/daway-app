import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../entities/patient_health_profile.dart';
import '../repositories/health_profile_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class GetHealthProfileUseCase {
  final HealthProfileRepository _repository;
  final SessionRepository _sessionRepository;

  const GetHealthProfileUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<PatientHealthProfile>> call() {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.getHealthProfile(token: token),
    );
  }
}

class UpdateHealthProfileUseCase {
  final HealthProfileRepository _repository;
  final SessionRepository _sessionRepository;

  const UpdateHealthProfileUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<PatientHealthProfile>> call(PatientHealthProfile profile) {
    return withSessionToken(
      _sessionRepository,
      (token) =>
          _repository.updateHealthProfile(token: token, profile: profile),
    );
  }
}
