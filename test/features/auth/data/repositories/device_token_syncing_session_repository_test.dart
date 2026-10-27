import 'package:daway_app/core/helpers/api_result.dart';
import 'package:daway_app/features/auth/data/repositories/device_token_syncing_session_repository.dart';
import 'package:daway_app/features/auth/domain/entities/account_type.dart';
import 'package:daway_app/features/auth/domain/entities/user_session.dart';
import 'package:daway_app/features/auth/domain/repositories/device_tokens_repository.dart';
import 'package:daway_app/features/auth/domain/repositories/push_token_source.dart';
import 'package:daway_app/features/auth/domain/repositories/session_repository.dart';
import 'package:daway_app/features/auth/domain/usecases/register_device_token_usecase.dart';
import 'package:daway_app/features/auth/domain/usecases/unregister_device_token_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSessions implements SessionRepository {
  UserSession? session;

  @override
  Future<void> saveSession(UserSession s) async => session = s;

  @override
  Future<UserSession?> getSession() async => session;

  @override
  Future<void> clearSession() async => session = null;
}

class _FakeTokens implements DeviceTokensRepository {
  final calls = <String>[];
  bool fail = false;

  @override
  Future<ApiResult<void>> register({
    required String authToken,
    required String fcmToken,
    required String deviceId,
    required String platform,
  }) async {
    calls.add('register $authToken $fcmToken $deviceId $platform');
    if (fail) throw Exception('offline');
    return const Success(null);
  }

  @override
  Future<ApiResult<void>> unregister({
    required String authToken,
    required String deviceId,
  }) async {
    calls.add('unregister $authToken $deviceId');
    return const Success(null);
  }
}

class _FakeSource implements PushTokenSource {
  String? token = 'fcm-1';

  @override
  Future<String?> fcmToken() async => token;

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Future<String> deviceId() async => 'dev-1';

  @override
  String get platform => 'android';
}

void main() {
  late _FakeSessions sessions;
  late _FakeTokens tokens;
  late _FakeSource source;
  late DeviceTokenSyncingSessionRepository repository;

  const session = UserSession(accountType: AccountType.patient, token: 'auth-1');

  setUp(() {
    sessions = _FakeSessions();
    tokens = _FakeTokens();
    source = _FakeSource();
    repository = DeviceTokenSyncingSessionRepository(
      sessions,
      RegisterDeviceTokenUseCase(tokens, source),
      UnregisterDeviceTokenUseCase(tokens, source),
    );
  });

  test('saving a session registers this device token', () async {
    await repository.saveSession(session);

    expect(sessions.session, session);
    expect(tokens.calls, ['register auth-1 fcm-1 dev-1 android']);
  });

  test('no push token yet: session is saved and nothing is registered', () async {
    source.token = null;

    await repository.saveSession(session);

    expect(sessions.session, session);
    expect(tokens.calls, isEmpty);
  });

  test('a failing registration does not break saving the session', () async {
    tokens.fail = true;

    await repository.saveSession(session);

    expect(sessions.session, session);
  });

  test('clearing unregisters with the auth token, then clears', () async {
    sessions.session = session;

    await repository.clearSession();

    expect(tokens.calls, ['unregister auth-1 dev-1']);
    expect(sessions.session, isNull);
  });

  test('clearing with no session just clears', () async {
    await repository.clearSession();

    expect(tokens.calls, isEmpty);
  });
}
