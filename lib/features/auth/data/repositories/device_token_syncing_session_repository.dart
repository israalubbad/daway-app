import '../../domain/entities/user_session.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/usecases/register_device_token_usecase.dart';
import '../../domain/usecases/unregister_device_token_usecase.dart';

/// Keeps the backend's device-token list in step with the session: a new
/// session registers this device for pushes, ending it unregisters first
/// (while the auth token is still readable). Failures never block auth.
class DeviceTokenSyncingSessionRepository implements SessionRepository {
  final SessionRepository _inner;
  final RegisterDeviceTokenUseCase _register;
  final UnregisterDeviceTokenUseCase _unregister;

  const DeviceTokenSyncingSessionRepository(
    this._inner,
    this._register,
    this._unregister,
  );

  @override
  Future<void> saveSession(UserSession session) async {
    await _inner.saveSession(session);
    try {
      await _register(authToken: session.token);
    } catch (_) {}
  }

  @override
  Future<UserSession?> getSession() => _inner.getSession();

  @override
  Future<void> clearSession() async {
    try {
      final session = await _inner.getSession();
      if (session != null) await _unregister(authToken: session.token);
    } catch (_) {}
    await _inner.clearSession();
  }
}
