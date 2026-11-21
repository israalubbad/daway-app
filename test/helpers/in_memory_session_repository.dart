import 'package:daway_app/features/auth/domain/entities/account_type.dart';
import 'package:daway_app/features/auth/domain/entities/user_session.dart';
import 'package:daway_app/features/auth/domain/repositories/session_repository.dart';

/// A [SessionRepository] that keeps the session in memory, for the tests of
/// everything that reads it. Starts signed out unless told otherwise.
class InMemorySessionRepository implements SessionRepository {
  UserSession? savedSession;

  InMemorySessionRepository({this.savedSession});

  /// Signed in as a patient, token "tok-1".
  InMemorySessionRepository.patient()
    : savedSession = const UserSession(accountType: AccountType.patient, token: 'tok-1');

  /// Signed in as a pharmacy, token "tok-1".
  InMemorySessionRepository.pharmacy()
    : savedSession = const UserSession(accountType: AccountType.pharmacy, token: 'tok-1');

  @override
  Future<void> saveSession(UserSession session) async => savedSession = session;

  @override
  Future<UserSession?> getSession() async => savedSession;

  @override
  Future<void> clearSession() async => savedSession = null;
}
