import 'package:daway_app/core/erroring/failure.dart';
import 'package:daway_app/core/helpers/api_result.dart';
import 'package:daway_app/features/auth/domain/entities/account_type.dart';
import 'package:daway_app/features/auth/domain/entities/user_session.dart';
import 'package:daway_app/features/auth/domain/repositories/session_repository.dart';
import 'package:daway_app/features/pharmacy/domain/repositories/pharmacy_password_repository.dart';
import 'package:daway_app/features/pharmacy/domain/usecases/change_pharmacy_password_usecase.dart';
import 'package:daway_app/features/pharmacy/presentation/cubit/change_pharmacy_password_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePasswordRepository implements PharmacyPasswordRepository {
  ApiResult<void> result = const Success(null);
  String? lastToken;
  String? lastCurrent;
  String? lastNew;
  int calls = 0;

  @override
  Future<ApiResult<void>> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    calls++;
    lastToken = token;
    lastCurrent = currentPassword;
    lastNew = newPassword;
    return result;
  }
}

class _FakeSessionRepository implements SessionRepository {
  @override
  Future<void> saveSession(UserSession session) async {}

  @override
  Future<UserSession?> getSession() async =>
      const UserSession(accountType: AccountType.pharmacy, token: 'tok-1');

  @override
  Future<void> clearSession() async {}
}

void main() {
  late _FakePasswordRepository repository;
  late ChangePharmacyPasswordCubit cubit;

  setUp(() {
    repository = _FakePasswordRepository();
    cubit = ChangePharmacyPasswordCubit(
      ChangePharmacyPasswordUseCase(repository, _FakeSessionRepository()),
    );
  });

  tearDown(() => cubit.close());

  Future<void> submit({String current = 'old-password', String next = 'new-password', String? confirm}) {
    return cubit.submit(
      currentPassword: current,
      newPassword: next,
      confirmation: confirm ?? next,
    );
  }

  test('a valid change is sent with the session token and succeeds', () async {
    await submit();

    expect(cubit.state, isA<ChangePasswordSuccess>());
    expect(repository.lastToken, 'tok-1');
    expect(repository.lastCurrent, 'old-password');
    expect(repository.lastNew, 'new-password');
  });

  test('an empty current password is refused without a request', () async {
    await submit(current: '');

    expect((cubit.state as ChangePasswordIdle).message, isNotNull);
    expect(repository.calls, 0);
  });

  test('a short new password is refused without a request', () async {
    await submit(next: 'short');

    expect((cubit.state as ChangePasswordIdle).message, isNotNull);
    expect(repository.calls, 0);
  });

  test('a mismatched confirmation is refused without a request', () async {
    await submit(confirm: 'something-else');

    expect((cubit.state as ChangePasswordIdle).message, 'كلمتا المرور غير متطابقتين');
    expect(repository.calls, 0);
  });

  test('the same password again is refused without a request', () async {
    await submit(current: 'same-password', next: 'same-password');

    expect((cubit.state as ChangePasswordIdle).message, isNotNull);
    expect(repository.calls, 0);
  });

  test('a backend failure shows its message and allows another try', () async {
    repository.result = const ApiError(ApiFailure(message: 'كلمة المرور الحالية غير صحيحة'));

    await submit();

    expect((cubit.state as ChangePasswordIdle).message, 'كلمة المرور الحالية غير صحيحة');
    repository.result = const Success(null);
    await submit();
    expect(cubit.state, isA<ChangePasswordSuccess>());
  });
}
