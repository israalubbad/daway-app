import '../../../../core/erroring/failure.dart';
import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../repositories/availability_alerts_repository.dart';

class SubscribeAvailabilityAlertUseCase {
  final AvailabilityAlertsRepository _repository;
  final SessionRepository _sessionRepository;

  const SubscribeAvailabilityAlertUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<void>> call(int medicineId) async {
    final session = await _sessionRepository.getSession();
    if (session == null) {
      return ApiError(
        ApiFailure(message: sessionExpiredMessage),
      );
    }
    return _repository.subscribe(token: session.token, medicineId: medicineId);
  }
}
