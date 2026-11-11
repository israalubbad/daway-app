import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../repositories/availability_alerts_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class SubscribeAvailabilityAlertUseCase {
  final AvailabilityAlertsRepository _repository;
  final SessionRepository _sessionRepository;

  const SubscribeAvailabilityAlertUseCase(
    this._repository,
    this._sessionRepository,
  );

  Future<ApiResult<void>> call(int medicineId) {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.subscribe(token: token, medicineId: medicineId),
    );
  }
}
