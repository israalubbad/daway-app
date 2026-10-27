import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daway_app/core/networking/session_expired_interceptor.dart';

void main() {
  Dio buildDio(int status, {required void Function() onExpired}) {
    final dio = Dio(BaseOptions(baseUrl: 'http://test'));
    dio.interceptors.add(SessionExpiredInterceptor(onExpired));
    dio.httpClientAdapter = _FixedStatusAdapter(status);
    return dio;
  }

  test('401 on a request with a bearer token reports an expired session', () async {
    var calls = 0;
    final dio = buildDio(401, onExpired: () => calls++);

    await expectLater(
      dio.get('/x', options: Options(headers: {'Authorization': 'Bearer t'})),
      throwsA(isA<DioException>()),
    );
    expect(calls, 1);
  });

  test('401 without a token (wrong credentials) is not a session expiry', () async {
    var calls = 0;
    final dio = buildDio(401, onExpired: () => calls++);

    await expectLater(dio.get('/x'), throwsA(isA<DioException>()));
    expect(calls, 0);
  });

  test('other errors with a token are not a session expiry', () async {
    var calls = 0;
    final dio = buildDio(500, onExpired: () => calls++);

    await expectLater(
      dio.get('/x', options: Options(headers: {'Authorization': 'Bearer t'})),
      throwsA(isA<DioException>()),
    );
    expect(calls, 0);
  });
}

class _FixedStatusAdapter implements HttpClientAdapter {
  final int status;
  _FixedStatusAdapter(this.status);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      ResponseBody.fromString('{}', status, headers: {
        Headers.contentTypeHeader: ['application/json'],
      });

  @override
  void close({bool force = false}) {}
}
