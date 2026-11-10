import 'package:daway_app/core/erroring/failure.dart';
import 'package:daway_app/core/helpers/api_result.dart';
import 'package:daway_app/features/auth/domain/entities/closure_request.dart';
import 'package:daway_app/features/auth/domain/usecases/close_patient_account_usecase.dart';
import 'package:daway_app/features/auth/domain/usecases/get_pharmacy_closure_request_usecase.dart';
import 'package:daway_app/features/auth/domain/usecases/request_pharmacy_closure_usecase.dart';
import 'package:daway_app/features/auth/presentation/cubit/account_closure_cubit.dart';
import 'package:daway_app/features/auth/presentation/cubit/account_closure_state.dart';
import 'package:daway_app/features/auth/presentation/cubit/pharmacy_closure_cubit.dart';
import 'package:daway_app/features/auth/presentation/cubit/pharmacy_closure_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../account_closure_test_fakes.dart';

void main() {
  late FakeAccountClosureRepository repository;
  late FakeClosureSessionRepository session;

  setUp(() {
    repository = FakeAccountClosureRepository();
    session = FakeClosureSessionRepository();
  });

  group('AccountClosureCubit', () {
    AccountClosureCubit build() {
      final cubit = AccountClosureCubit(ClosePatientAccountUseCase(repository, session));
      addTearDown(cubit.close);
      return cubit;
    }

    test('starts idle', () {
      expect(build().state, isA<AccountClosureIdle>());
    });

    test('goes through submitting to done, and the session is gone', () async {
      final cubit = build();
      final states = <AccountClosureState>[];
      cubit.stream.listen(states.add);

      await cubit.deleteAccount(reason: 'لا أحتاجه');
      await Future<void>.delayed(Duration.zero);

      expect(states.map((s) => s.runtimeType), [AccountClosureSubmitting, AccountClosureDone]);
      expect(repository.lastReason, 'لا أحتاجه');
      expect(session.savedSession, isNull);
    });

    test('a refusal goes back to idle with the reason, and the session stays', () async {
      repository.closePatientResult = refusedClosure;
      final cubit = build();

      await cubit.deleteAccount();

      expect((cubit.state as AccountClosureIdle).errorMessage, 'لديك طلبات جارية');
      expect(session.savedSession, isNotNull);
    });

    test('can be tried again after a refusal', () async {
      repository.closePatientResult = refusedClosure;
      final cubit = build();
      await cubit.deleteAccount();
      repository.closePatientResult = const Success(null);

      await cubit.deleteAccount();

      expect(cubit.state, isA<AccountClosureDone>());
      expect(repository.closeCount, 2);
    });

    test('a second tap while the first is in flight sends nothing more', () async {
      final cubit = build();

      final first = cubit.deleteAccount();
      final second = cubit.deleteAccount();
      await Future.wait([first, second]);

      expect(repository.closeCount, 1);
    });

    test('once done it does not delete again', () async {
      final cubit = build();
      await cubit.deleteAccount();

      await cubit.deleteAccount();

      expect(repository.closeCount, 1);
    });

    test('clearError drops the message of the last try', () async {
      repository.closePatientResult = refusedClosure;
      final cubit = build();
      await cubit.deleteAccount();

      cubit.clearError();

      expect((cubit.state as AccountClosureIdle).errorMessage, isNull);
    });
  });

  group('PharmacyClosureCubit', () {
    PharmacyClosureCubit build() {
      final cubit = PharmacyClosureCubit(
        GetPharmacyClosureRequestUseCase(repository, session),
        RequestPharmacyClosureUseCase(repository, session),
      );
      addTearDown(cubit.close);
      return cubit;
    }

    test('load reads that the pharmacy never asked', () async {
      final cubit = build();

      await cubit.load();

      final state = cubit.state as PharmacyClosureLoaded;
      expect(state.request, isNull);
      expect(state.isSubmitting, isFalse);
    });

    test('load reads a request that is waiting', () async {
      repository.getRequestResult = const Success(pendingRequest);
      final cubit = build();

      await cubit.load();

      expect((cubit.state as PharmacyClosureLoaded).request, pendingRequest);
    });

    test('a failed load is a load failure, not a missing request', () async {
      repository.getRequestResult = const ApiError(ApiFailure(message: 'تعذر الاتصال'));
      final cubit = build();

      await cubit.load();

      expect(cubit.state, isA<PharmacyClosureLoadFailure>());
    });

    test('submit sends the request and keeps it as waiting', () async {
      final cubit = build();
      await cubit.load();
      final states = <PharmacyClosureState>[];
      cubit.stream.listen(states.add);

      await cubit.submit(reason: 'إغلاق نهائي');
      await Future<void>.delayed(Duration.zero);

      expect((states.first as PharmacyClosureLoaded).isSubmitting, isTrue);
      final done = cubit.state as PharmacyClosureLoaded;
      expect(done.request, pendingRequest);
      expect(done.isSubmitting, isFalse);
      expect(repository.lastReason, 'إغلاق نهائي');
      // The pharmacy stays signed in: only the admin can end the account.
      expect(session.savedSession, isNotNull);
    });

    test('a refusal keeps the old state and carries the reason', () async {
      repository.requestResult = const ApiError(ApiFailure(message: 'يوجد طلب مفتوح'));
      final cubit = build();
      await cubit.load();

      await cubit.submit();

      final state = cubit.state as PharmacyClosureLoaded;
      expect(state.request, isNull);
      expect(state.errorMessage, 'يوجد طلب مفتوح');
      expect(state.isSubmitting, isFalse);
    });

    test('closureRequestJustSent is true only for the change that lands a request', () async {
      final cubit = build();
      await cubit.load();
      final states = <PharmacyClosureState>[cubit.state];
      cubit.stream.listen(states.add);

      await cubit.submit();
      await Future<void>.delayed(Duration.zero);

      expect(closureRequestJustSent(states[0], states[1]), isFalse);
      expect(closureRequestJustSent(states[1], states[2]), isTrue);
    });

    test('a request that is already waiting is not sent again', () async {
      repository.getRequestResult = const Success(pendingRequest);
      final cubit = build();
      await cubit.load();

      await cubit.submit();

      expect(repository.requestCount, 0);
    });

    test('a rejected request may be asked again', () async {
      repository.getRequestResult = const Success(
        ClosureRequest(status: ClosureRequestStatus.rejected),
      );
      final cubit = build();
      await cubit.load();

      await cubit.submit();

      expect(repository.requestCount, 1);
    });

    test('a second tap while the first is in flight sends nothing more', () async {
      final cubit = build();
      await cubit.load();

      final first = cubit.submit();
      final second = cubit.submit();
      await Future.wait([first, second]);

      expect(repository.requestCount, 1);
    });

    test('submit works even when the load failed', () async {
      repository.getRequestResult = const ApiError(ApiFailure(message: 'تعذر الاتصال'));
      final cubit = build();
      await cubit.load();

      await cubit.submit();

      expect((cubit.state as PharmacyClosureLoaded).request, pendingRequest);
    });

    test('clearError drops the message of the last try', () async {
      repository.requestResult = const ApiError(ApiFailure(message: 'يوجد طلب مفتوح'));
      final cubit = build();
      await cubit.load();
      await cubit.submit();

      cubit.clearError();

      expect((cubit.state as PharmacyClosureLoaded).errorMessage, isNull);
    });
  });
}
