import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../repositories/notifications_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class MarkAllNotificationsReadUseCase {
  final NotificationsRepository _repository;
  final SessionRepository _sessionRepository;

  const MarkAllNotificationsReadUseCase(
    this._repository,
    this._sessionRepository,
  );

  Future<ApiResult<void>> call() {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.markAllAsRead(token: token),
    );
  }
}
