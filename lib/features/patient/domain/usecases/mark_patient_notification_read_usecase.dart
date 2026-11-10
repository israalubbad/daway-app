import '../../../../core/erroring/failure.dart';
import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../repositories/patient_notifications_repository.dart';

class MarkPatientNotificationReadUseCase {
  final PatientNotificationsRepository _repository;
  final SessionRepository _sessionRepository;

  const MarkPatientNotificationReadUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<void>> call(int notificationId) async {
    final session = await _sessionRepository.getSession();
    if (session == null) {
      return const ApiError(
        ApiFailure(message: sessionExpiredMessage),
      );
    }
    return _repository.markAsRead(token: session.token, notificationId: notificationId);
  }
}
