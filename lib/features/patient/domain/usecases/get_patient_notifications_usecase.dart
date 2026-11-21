import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../entities/patient_notification.dart';
import '../repositories/patient_notifications_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class GetPatientNotificationsUseCase {
  final PatientNotificationsRepository _repository;
  final SessionRepository _sessionRepository;

  const GetPatientNotificationsUseCase(
    this._repository,
    this._sessionRepository,
  );

  Future<ApiResult<List<PatientNotification>>> call() {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.getNotifications(token: token),
    );
  }
}
