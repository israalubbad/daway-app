import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../repositories/cart_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class ClearCartUseCase {
  final CartRepository _repository;
  final SessionRepository _sessionRepository;

  const ClearCartUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<void>> call() {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.clearCart(token: token),
    );
  }
}
