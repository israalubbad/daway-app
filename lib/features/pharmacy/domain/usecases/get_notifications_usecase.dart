import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../entities/notification.dart';
import '../repositories/notifications_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class GetNotificationsUseCase {
  final NotificationsRepository _repository;
  final SessionRepository _sessionRepository;

  const GetNotificationsUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<NotificationsOverview>> call() {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.getNotifications(token: token),
    );
  }
}
