import '../../../../core/helpers/api_result.dart';
import '../../../../core/helpers/optional_text.dart';
import '../entities/closure_request.dart';
import '../repositories/account_closure_repository.dart';
import '../repositories/session_repository.dart';
import 'with_session_token.dart';

class RequestPharmacyClosureUseCase {
  final AccountClosureRepository _repository;
  final SessionRepository _sessionRepository;

  const RequestPharmacyClosureUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<ClosureRequest>> call({String? reason}) => withSessionToken(
        _sessionRepository,
        (token) => _repository.requestPharmacyClosure(token: token, reason: optionalText(reason)),
      );
}
