import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:daway_app/core/networking/response_cache_interceptor.dart';
import 'package:daway_app/core/networking/response_cache_store.dart';
import 'package:daway_app/features/auth/data/repositories/cache_clearing_session_repository.dart';
import 'package:daway_app/features/auth/domain/entities/account_type.dart';
import 'package:daway_app/features/auth/domain/entities/user_session.dart';
import 'package:daway_app/features/auth/domain/repositories/session_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStore implements ResponseCacheStore {
  final Map<String, CachedResponse> entries = {};
  int clears = 0;

  @override
  Future<CachedResponse?> read(String key) async => entries[key];

  @override
  Future<void> write(String key, CachedResponse response) async => entries[key] = response;

  @override
  Future<void> clear() async {
    clears++;
    entries.clear();
  }
}

/// Answers each request with the next scripted result: a body, or an error type.
class _ScriptedAdapter implements HttpClientAdapter {
  final List<Object> script;
  int calls = 0;

  _ScriptedAdapter(this.script);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final next = script[calls < script.length ? calls : script.length - 1];
    calls++;
    if (next is DioExceptionType) {
      throw DioException(requestOptions: options, type: next);
    }
    final status = next is int ? next : 200;
    final body = next is int ? '{"message":"no"}' : jsonEncode(next);
    return ResponseBody.fromString(body, status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _MemoryStore store;
  late DateTime now;

  Dio dioFor(List<Object> script, {int maxBodyBytes = 256 * 1024}) {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test/api'));
    dio.httpClientAdapter = _ScriptedAdapter(script);
    dio.interceptors.add(
      ResponseCacheInterceptor(store, maxBodyBytes: maxBodyBytes, now: () => now),
    );
    return dio;
  }

  _ScriptedAdapter adapterOf(Dio dio) => dio.httpClientAdapter as _ScriptedAdapter;

  setUp(() {
    store = _MemoryStore();
    now = DateTime(2026, 11, 11, 12);
  });

  test('a catalogue answer is served from the cache while it is fresh', () async {
    final dio = dioFor([
      {'data': ['a']},
      {'data': ['b']},
    ]);

    await dio.get<dynamic>('/categories');
    now = now.add(const Duration(minutes: 30));
    final second = await dio.get<dynamic>('/categories');

    expect(adapterOf(dio).calls, 1);
    expect(second.data, {'data': ['a']});
    expect(second.extra[ResponseCacheInterceptor.fromCacheKey], isTrue);
  });

  test('a catalogue answer is fetched again once it is stale', () async {
    final dio = dioFor([
      {'data': ['a']},
      {'data': ['b']},
    ]);

    await dio.get<dynamic>('/categories');
    now = now.add(const Duration(hours: 2));
    final second = await dio.get<dynamic>('/categories');

    expect(adapterOf(dio).calls, 2);
    expect(second.data, {'data': ['b']});
  });

  test('the user\'s own lists are always fetched, so a change is never hidden', () async {
    final dio = dioFor([
      {'data': ['old']},
      {'data': ['new']},
    ]);

    await dio.get<dynamic>('/patient/favorites/medicines');
    final second = await dio.get<dynamic>('/patient/favorites/medicines');

    expect(adapterOf(dio).calls, 2);
    expect(second.data, {'data': ['new']});
  });

  test('offline, the last copy answers instead of an error', () async {
    final dio = dioFor([
      {'data': ['orders']},
      DioExceptionType.connectionError,
    ]);

    await dio.get<dynamic>('/patient/orders');
    final offline = await dio.get<dynamic>('/patient/orders');

    expect(offline.data, {'data': ['orders']});
    expect(offline.extra[ResponseCacheInterceptor.fromCacheKey], isTrue);
  });

  test('offline with nothing kept still fails', () async {
    final dio = dioFor([DioExceptionType.connectionError]);

    expect(
      () => dio.get<dynamic>('/patient/orders'),
      throwsA(isA<DioException>().having((e) => e.type, 'type', DioExceptionType.connectionError)),
    );
  });

  test('a copy older than a week is not used even offline', () async {
    final dio = dioFor([
      {'data': ['orders']},
      DioExceptionType.connectionError,
    ]);

    await dio.get<dynamic>('/patient/orders');
    now = now.add(const Duration(days: 8));

    expect(() => dio.get<dynamic>('/patient/orders'), throwsA(isA<DioException>()));
  });

  test('a server error is not hidden behind the cache', () async {
    final dio = dioFor([
      {'data': ['orders']},
      500,
    ]);

    await dio.get<dynamic>('/patient/orders');

    expect(
      () => dio.get<dynamic>('/patient/orders'),
      throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 500)),
    );
  });

  test('other routes, POSTs and error answers are never kept', () async {
    final dio = dioFor([
      {'ok': true},
    ]);

    await dio.get<dynamic>('/patient/cart');
    await dio.post<dynamic>('/categories');

    expect(store.entries, isEmpty);
  });

  test('an answer over the size limit is not kept', () async {
    final dio = dioFor([
      {'data': List.filled(100, 'long text to fill the answer')},
    ], maxBodyBytes: 200);

    await dio.get<dynamic>('/categories');

    expect(store.entries, isEmpty);
  });

  test('two accounts never share an answer', () async {
    final dio = dioFor([
      {'data': ['mine']},
      {'data': ['theirs']},
    ]);

    await dio.get<dynamic>(
      '/patient/orders',
      options: Options(headers: {'Authorization': 'Bearer one'}),
    );
    await dio.get<dynamic>(
      '/patient/orders',
      options: Options(headers: {'Authorization': 'Bearer two'}),
    );

    expect(store.entries.length, 2);
  });

  group('FileResponseCacheStore', () {
    late Directory temp;

    setUp(() => temp = Directory.systemTemp.createTempSync('dawak_cache_test'));
    tearDown(() => temp.deleteSync(recursive: true));

    test('round-trips an answer', () async {
      final fileStore = FileResponseCacheStore(() async => temp);
      await fileStore.write('k', CachedResponse(body: {'a': 1}, storedAt: DateTime(2026, 11, 11)));

      final read = await fileStore.read('k');

      expect(read!.body, {'a': 1});
      expect(read.storedAt, DateTime(2026, 11, 11));
      expect(await fileStore.read('other'), isNull);
    });

    test('drops the oldest entries past the limit', () async {
      final fileStore = FileResponseCacheStore(() async => temp, maxEntries: 2);
      for (final key in ['a', 'b', 'c']) {
        await fileStore.write(key, CachedResponse(body: [key], storedAt: DateTime(2026)));
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }

      expect(await fileStore.read('a'), isNull);
      expect(await fileStore.read('b'), isNotNull);
      expect(await fileStore.read('c'), isNotNull);
    });

    test('drops entries past the byte limit', () async {
      final fileStore = FileResponseCacheStore(() async => temp, maxBytes: 150);
      for (final key in ['a', 'b', 'c']) {
        await fileStore.write(key, CachedResponse(body: List.filled(5, key * 10), storedAt: DateTime(2026)));
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }

      expect(await fileStore.read('a'), isNull);
      expect(await fileStore.read('c'), isNotNull);
    });

    test('clear forgets everything', () async {
      final fileStore = FileResponseCacheStore(() async => temp);
      await fileStore.write('k', CachedResponse(body: [1], storedAt: DateTime(2026)));

      await fileStore.clear();

      expect(await fileStore.read('k'), isNull);
    });
  });

  group('CacheClearingSessionRepository', () {
    test('clears the cache when a session ends and when a new one starts', () async {
      final cache = _MemoryStore();
      final inner = _InnerSession();
      final repository = CacheClearingSessionRepository(inner, cache);

      await repository.saveSession(const UserSession(accountType: AccountType.patient, token: 't'));
      expect(cache.clears, 1);
      expect(inner.session, isNotNull);

      await repository.clearSession();
      expect(cache.clears, 2);
      expect(inner.session, isNull);
    });
  });
}

class _InnerSession implements SessionRepository {
  UserSession? session;

  @override
  Future<void> saveSession(UserSession session) async => this.session = session;

  @override
  Future<UserSession?> getSession() async => session;

  @override
  Future<void> clearSession() async => session = null;
}
