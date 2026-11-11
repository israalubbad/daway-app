import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../repositories/patient_notifications_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class MarkPatientNotificationReadUseCase {
  final PatientNotificationsRepository _repository;
  final SessionRepository _sessionRepository;

  const MarkPatientNotificationReadUseCase(
    this._repository,
    this._sessionRepository,
  );

  Future<ApiResult<void>> call(int notificationId) {
    return withSessionToken(
      _sessionRepository,
      (token) =>
          _repository.markAsRead(token: token, notificationId: notificationId),
    );
  }
}
