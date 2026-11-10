import 'package:daway_app/core/helpers/api_result.dart';
import 'package:daway_app/features/auth/domain/entities/closure_request.dart';
import 'package:daway_app/features/auth/domain/usecases/close_patient_account_usecase.dart';
import 'package:daway_app/features/auth/domain/usecases/get_pharmacy_closure_request_usecase.dart';
import 'package:daway_app/features/auth/domain/usecases/request_pharmacy_closure_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../account_closure_test_fakes.dart';

void main() {
  late FakeAccountClosureRepository repository;
  late FakeClosureSessionRepository session;

  setUp(() {
    repository = FakeAccountClosureRepository();
    session = FakeClosureSessionRepository();
  });

  group('ClosePatientAccountUseCase', () {
    test('closes the account with the session token and ends the session', () async {
      final result = await ClosePatientAccountUseCase(repository, session)(reason: 'لا أحتاجه');

      expect(result, isA<Success<void>>());
      expect(repository.lastToken, 'tok-1');
      expect(repository.lastReason, 'لا أحتاجه');
      expect(session.clearCount, 1);
      expect(session.savedSession, isNull);
    });

    test('a blank reason is sent as no reason', () async {
      await ClosePatientAccountUseCase(repository, session)(reason: '   ');

      expect(repository.lastReason, isNull);
    });

    test('a refused closure keeps the session: the account is still there', () async {
      repository.closePatientResult = refusedClosure;

      final result = await ClosePatientAccountUseCase(repository, session)();

      expect((result as ApiError<void>).failure.message, 'لديك طلبات جارية');
      expect(session.clearCount, 0);
      expect(session.savedSession, isNotNull);
    });

    test('without a session it fails and calls nothing', () async {
      session.savedSession = null;

      final result = await ClosePatientAccountUseCase(repository, session)();

      expect(result, isA<ApiError<void>>());
      expect(repository.closeCount, 0);
    });
  });

  group('GetPharmacyClosureRequestUseCase', () {
    test('reads the request with the session token', () async {
      repository.getRequestResult = const Success(pendingRequest);

      final result = await GetPharmacyClosureRequestUseCase(repository, session)();

      expect((result as Success<ClosureRequest?>).data, pendingRequest);
      expect(repository.lastToken, 'tok-1');
    });

    test('without a session it fails and calls nothing', () async {
      session.savedSession = null;

      final result = await GetPharmacyClosureRequestUseCase(repository, session)();

      expect(result, isA<ApiError<ClosureRequest?>>());
      expect(repository.getCount, 0);
    });
  });

  group('RequestPharmacyClosureUseCase', () {
    test('sends the trimmed reason and keeps the pharmacy signed in', () async {
      final result = await RequestPharmacyClosureUseCase(repository, session)(
        reason: '  إغلاق نهائي  ',
      );

      expect((result as Success<ClosureRequest>).data, pendingRequest);
      expect(repository.lastReason, 'إغلاق نهائي');
      expect(session.clearCount, 0);
    });

    test('a blank reason is sent as no reason', () async {
      await RequestPharmacyClosureUseCase(repository, session)(reason: '');

      expect(repository.lastReason, isNull);
    });

    test('without a session it fails and calls nothing', () async {
      session.savedSession = null;

      final result = await RequestPharmacyClosureUseCase(repository, session)();

      expect(result, isA<ApiError<ClosureRequest>>());
      expect(repository.requestCount, 0);
    });
  });
}
