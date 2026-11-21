import 'package:daway_app/core/erroring/failure.dart';
import 'package:daway_app/core/helpers/api_result.dart';
import 'package:daway_app/features/auth/domain/entities/account_type.dart';
import 'package:daway_app/features/auth/domain/entities/patient_auth_result.dart';
import 'package:daway_app/features/auth/domain/entities/pharmacy_auth_result.dart';
import 'package:daway_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:daway_app/features/auth/domain/usecases/pharmacy_login_usecase.dart';
import 'package:daway_app/features/auth/domain/usecases/save_session_usecase.dart';
import 'package:daway_app/features/auth/presentation/cubit/pharmacy_auth_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../helpers/in_memory_session_repository.dart';

class _FakeAuthRepository implements AuthRepository {
  ApiResult<PharmacyAuthResult> loginResult =
      const Success(PharmacyAuthResult(token: 'fake-token'));

  @override
  Future<ApiResult<String?>> sendOtp({
    required String phone,
    String? name,
    String? birthDate,
  }) async =>
      const Success(null);

  @override
  Future<ApiResult<PatientAuthResult>> verifyOtp({
    required String phone,
    required String otp,
    String? name,
    String? birthDate,
    double? latitude,
    double? longitude,
    bool? notificationsEnabled,
  }) async =>
      const Success(PatientAuthResult(token: 'tok', isNewAccount: false));

  @override
  Future<ApiResult<PharmacyAuthResult>> pharmacyLogin({
    required String pharmacyId,
    required String password,
  }) async =>
      loginResult;

  @override
  Future<ApiResult<void>> registerPharmacy({
    required String pharmacyName,
    required String phone,
    required String region,
    required String password,
  }) async => const Success(null);

  @override
  Future<ApiResult<void>> logout({required String token}) async => const Success(null);
}

void main() {
  late _FakeAuthRepository repository;
  late InMemorySessionRepository sessionRepository;
  late PharmacyAuthCubit cubit;

  setUp(() {
    repository = _FakeAuthRepository();
    sessionRepository = InMemorySessionRepository();
    cubit = PharmacyAuthCubit(
      PharmacyLoginUseCase(repository),
      SaveSessionUseCase(sessionRepository),
    );
  });

  tearDown(() => cubit.close());

  group('login', () {
    test('rejects an empty pharmacy id', () async {
      await cubit.login(pharmacyId: '', password: 'password');

      expect(cubit.state.token, isNull);
      expect(cubit.state.errorMessage, isNotNull);
    });

    test('stores the token on success', () async {
      await cubit.login(pharmacyId: 'PH-1234', password: 'password');

      expect(cubit.state.token, 'fake-token');
      expect(cubit.state.isLoggingIn, isFalse);
      expect(cubit.state.errorMessage, isNull);
    });

    test('persists the session on success', () async {
      await cubit.login(pharmacyId: 'PH-1234', password: 'password');

      expect(sessionRepository.savedSession?.accountType, AccountType.pharmacy);
      expect(sessionRepository.savedSession?.token, 'fake-token');
    });

    test('surfaces the failure message on error', () async {
      repository.loginResult =
          const ApiError(ApiFailure(message: 'بيانات الدخول غير صحيحة', code: 'INVALID_CREDENTIALS'));

      await cubit.login(pharmacyId: 'PH-1234', password: 'wrong-password');

      expect(cubit.state.token, isNull);
      expect(cubit.state.errorMessage, 'بيانات الدخول غير صحيحة');
    });
  });
}
