import '../../../../core/networking/response_cache_store.dart';
import '../../domain/entities/user_session.dart';
import '../../domain/repositories/session_repository.dart';

/// Empties the kept API answers whenever the session changes hands: what was
/// cached belongs to the account that just signed out (or was just replaced),
/// so it must neither linger on the device nor be offered to the next one.
class CacheClearingSessionRepository implements SessionRepository {
  final SessionRepository _inner;
  final ResponseCacheStore _cache;

  const CacheClearingSessionRepository(this._inner, this._cache);

  @override
  Future<void> saveSession(UserSession session) async {
    await _cache.clear();
    await _inner.saveSession(session);
  }

  @override
  Future<UserSession?> getSession() => _inner.getSession();

  @override
  Future<void> clearSession() async {
    await _inner.clearSession();
    await _cache.clear();
  }
}
