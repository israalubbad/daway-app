import 'package:daway_app/core/erroring/failure.dart';
import 'package:daway_app/core/helpers/api_result.dart';
import 'package:daway_app/features/auth/data/datasources/account_closure_remote_data_source.dart';
import 'package:daway_app/features/auth/data/repositories/account_closure_repository_impl.dart';
import 'package:daway_app/features/auth/domain/entities/closure_request.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// A data source over a Dio that answers from a script instead of the network,
/// so the request it builds can be read back.
class _ScriptedAdapter implements HttpClientAdapter {
  int statusCode = 200;
  Object? body = {'success': true};
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      _json(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  static String _json(Object? value) => switch (value) {
        null => 'null',
        Map() => '{${value.entries.map((e) => '"${e.key}":${_json(e.value)}').join(',')}}',
        String() => '"$value"',
        _ => '$value',
      };

  @override
  void close({bool force = false}) {}
}

void main() {
  late _ScriptedAdapter adapter;
  late AccountClosureRepositoryImpl repository;

  setUp(() {
    adapter = _ScriptedAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'))..httpClientAdapter = adapter;
    repository = AccountClosureRepositoryImpl(AccountClosureRemoteDataSource(dio));
  });

  group('closePatientAccount', () {
    test('posts the confirmation word and the reason to /account/closure', () async {
      final result = await repository.closePatientAccount(token: 'tok', reason: 'لا أحتاجه');

      expect(result, isA<Success<void>>());
      expect(adapter.lastRequest!.method, 'POST');
      expect(adapter.lastRequest!.path, '/account/closure');
      expect(adapter.lastRequest!.headers['Authorization'], 'Bearer tok');
      expect(adapter.lastRequest!.data, {'confirm': 'DELETE', 'reason': 'لا أحتاجه'});
    });

    test('leaves the reason out when there is none', () async {
      await repository.closePatientAccount(token: 'tok');

      expect(adapter.lastRequest!.data, {'confirm': 'DELETE'});
    });

    test('a refusal comes back as the server message', () async {
      adapter
        ..statusCode = 409
        ..body = {'message': 'لديك طلبات جارية'};

      final result = await repository.closePatientAccount(token: 'tok');

      final failure = (result as ApiError<void>).failure as ApiFailure;
      expect(failure.message, 'لديك طلبات جارية');
      expect(failure.statusCode, 409);
    });
  });

  group('getPharmacyClosureRequest', () {
    test('reads the request from /pharmacy/account/closure-request', () async {
      adapter.body = {
        'data': {'status': 'pending', 'reason': 'إغلاق نهائي'},
      };

      final result = await repository.getPharmacyClosureRequest(token: 'tok');

      expect(adapter.lastRequest!.method, 'GET');
      expect(adapter.lastRequest!.path, '/pharmacy/account/closure-request');
      final request = (result as Success<ClosureRequest?>).data!;
      expect(request.status, ClosureRequestStatus.pending);
      expect(request.reason, 'إغلاق نهائي');
    });

    test('no data is no request', () async {
      adapter.body = {'data': null};

      final result = await repository.getPharmacyClosureRequest(token: 'tok');

      expect((result as Success<ClosureRequest?>).data, isNull);
    });

    test('a 404 is no request either', () async {
      adapter
        ..statusCode = 404
        ..body = {'message': 'not found'};

      final result = await repository.getPharmacyClosureRequest(token: 'tok');

      expect((result as Success<ClosureRequest?>).data, isNull);
    });

    test('any other failure is an error', () async {
      adapter
        ..statusCode = 500
        ..body = {'message': 'boom'};

      final result = await repository.getPharmacyClosureRequest(token: 'tok');

      expect(result, isA<ApiError<ClosureRequest?>>());
    });
  });

  group('requestPharmacyClosure', () {
    test('posts the reason and returns the request', () async {
      adapter.body = {
        'data': {'status': 'pending', 'reason': 'إغلاق نهائي'},
      };

      final result = await repository.requestPharmacyClosure(token: 'tok', reason: 'إغلاق نهائي');

      expect(adapter.lastRequest!.method, 'POST');
      expect(adapter.lastRequest!.path, '/pharmacy/account/closure-request');
      expect(adapter.lastRequest!.data, {'reason': 'إغلاق نهائي'});
      expect((result as Success<ClosureRequest>).data.status, ClosureRequestStatus.pending);
    });

    test('an accepted request with an empty body is still a waiting request', () async {
      adapter.body = {'success': true};

      final result = await repository.requestPharmacyClosure(token: 'tok', reason: 'سبب');

      final request = (result as Success<ClosureRequest>).data;
      expect(request.status, ClosureRequestStatus.pending);
      expect(request.reason, 'سبب');
    });

    test('a refusal comes back as the server message', () async {
      adapter
        ..statusCode = 422
        ..body = {'message': 'يوجد طلب مفتوح'};

      final result = await repository.requestPharmacyClosure(token: 'tok');

      expect((result as ApiError<ClosureRequest>).failure.message, 'يوجد طلب مفتوح');
    });
  });
}
