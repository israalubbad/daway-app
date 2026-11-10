import 'package:daway_app/core/erroring/failure.dart';
import 'package:daway_app/core/helpers/api_result.dart';
import 'package:daway_app/features/auth/domain/entities/account_type.dart';
import 'package:daway_app/features/auth/domain/entities/closure_request.dart';
import 'package:daway_app/features/auth/domain/entities/user_session.dart';
import 'package:daway_app/features/auth/domain/repositories/account_closure_repository.dart';
import 'package:daway_app/features/auth/domain/repositories/session_repository.dart';
import 'package:daway_app/features/auth/domain/usecases/close_patient_account_usecase.dart';
import 'package:daway_app/features/auth/domain/usecases/get_pharmacy_closure_request_usecase.dart';
import 'package:daway_app/features/auth/domain/usecases/request_pharmacy_closure_usecase.dart';
import 'package:daway_app/features/auth/presentation/cubit/account_closure_cubit.dart';
import 'package:daway_app/features/auth/presentation/cubit/pharmacy_closure_cubit.dart';
import 'package:get_it/get_it.dart';

const pendingRequest = ClosureRequest(status: ClosureRequestStatus.pending, reason: 'إغلاق نهائي');

class FakeClosureSessionRepository implements SessionRepository {
  UserSession? savedSession = const UserSession(accountType: AccountType.patient, token: 'tok-1');
  int clearCount = 0;

  @override
  Future<void> saveSession(UserSession session) async => savedSession = session;

  @override
  Future<UserSession?> getSession() async => savedSession;

  @override
  Future<void> clearSession() async {
    clearCount++;
    savedSession = null;
  }
}

class FakeAccountClosureRepository implements AccountClosureRepository {
  ApiResult<void> closePatientResult = const Success(null);
  ApiResult<ClosureRequest?> getRequestResult = const Success(null);
  ApiResult<ClosureRequest> requestResult = const Success(pendingRequest);

  String? lastToken;
  String? lastReason;
  int closeCount = 0;
  int getCount = 0;
  int requestCount = 0;

  @override
  Future<ApiResult<void>> closePatientAccount({required String token, String? reason}) async {
    closeCount++;
    lastToken = token;
    lastReason = reason;
    return closePatientResult;
  }

  @override
  Future<ApiResult<ClosureRequest?>> getPharmacyClosureRequest({required String token}) async {
    getCount++;
    lastToken = token;
    return getRequestResult;
  }

  @override
  Future<ApiResult<ClosureRequest>> requestPharmacyClosure({
    required String token,
    String? reason,
  }) async {
    requestCount++;
    lastToken = token;
    lastReason = reason;
    return requestResult;
  }
}

const refusedClosure = ApiError<void>(ApiFailure(message: 'لديك طلبات جارية', statusCode: 409));

/// Puts the two closure cubits in [getIt] over fakes, for a test that opens a
/// settings screen through its route or inside the dashboard shell.
void registerClosureCubits(GetIt getIt) {
  final repository = FakeAccountClosureRepository();
  final session = FakeClosureSessionRepository();
  getIt.registerFactory<AccountClosureCubit>(
    () => AccountClosureCubit(ClosePatientAccountUseCase(repository, session)),
  );
  getIt.registerFactory<PharmacyClosureCubit>(
    () => PharmacyClosureCubit(
      GetPharmacyClosureRequestUseCase(repository, session),
      RequestPharmacyClosureUseCase(repository, session),
    ),
  );
}
