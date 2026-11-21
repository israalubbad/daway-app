import '../../../../core/helpers/api_result.dart';
import '../entities/closure_request.dart';
import '../repositories/account_closure_repository.dart';
import '../repositories/session_repository.dart';
import 'with_session_token.dart';

class GetPharmacyClosureRequestUseCase {
  final AccountClosureRepository _repository;
  final SessionRepository _sessionRepository;

  const GetPharmacyClosureRequestUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<ClosureRequest?>> call() => withSessionToken(
        _sessionRepository,
        (token) => _repository.getPharmacyClosureRequest(token: token),
      );
}
