import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../repositories/notifications_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class MarkNotificationReadUseCase {
  final NotificationsRepository _repository;
  final SessionRepository _sessionRepository;

  const MarkNotificationReadUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<void>> call({required int notificationId}) {
    return withSessionToken(
      _sessionRepository,
      (token) =>
          _repository.markAsRead(token: token, notificationId: notificationId),
    );
  }
}
