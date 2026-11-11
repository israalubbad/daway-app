import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../repositories/cart_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class DeleteCartItemUseCase {
  final CartRepository _repository;
  final SessionRepository _sessionRepository;

  const DeleteCartItemUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<void>> call(int itemId) {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.deleteItem(token: token, itemId: itemId),
    );
  }
}
