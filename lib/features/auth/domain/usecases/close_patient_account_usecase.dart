import '../../../../core/helpers/api_result.dart';
import '../../../../core/helpers/optional_text.dart';
import '../repositories/account_closure_repository.dart';
import '../repositories/session_repository.dart';
import 'with_session_token.dart';

/// Closes the patient's account, then ends the local session: the server has
/// already revoked the token, so nothing else the app holds is usable. A failed
/// closure leaves the session alone — the account is still there.
class ClosePatientAccountUseCase {
  final AccountClosureRepository _repository;
  final SessionRepository _sessionRepository;

  const ClosePatientAccountUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<void>> call({String? reason}) async {
    final result = await withSessionToken(
      _sessionRepository,
      (token) => _repository.closePatientAccount(token: token, reason: optionalText(reason)),
    );
    if (result is Success) await _sessionRepository.clearSession();
    return result;
  }
}
