import '../../../../core/erroring/failure.dart';
import '../../../../core/helpers/api_result.dart';
import '../entities/user_session.dart';
import '../repositories/session_repository.dart';

/// Runs [action] with the signed-in account's session, or answers the
/// session-expired failure when there is none. For a use case that needs more
/// of the session than its token (the account type, the user id).
Future<ApiResult<T>> withSession<T>(
  SessionRepository sessions,
  Future<ApiResult<T>> Function(UserSession session) action,
) async {
  final session = await sessions.getSession();
  if (session == null) {
    return ApiError(ApiFailure(message: sessionExpiredMessage));
  }
  return action(session);
}

/// Runs [action] with the signed-in account's token, or answers the
/// session-expired failure when there is none. What every use case that needs
/// the session does first; new ones should use this instead of writing the
/// check out again.
Future<ApiResult<T>> withSessionToken<T>(
  SessionRepository sessions,
  Future<ApiResult<T>> Function(String token) action,
) => withSession(sessions, (session) => action(session.token));
