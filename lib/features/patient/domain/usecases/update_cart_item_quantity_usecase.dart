import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../repositories/cart_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class UpdateCartItemQuantityUseCase {
  final CartRepository _repository;
  final SessionRepository _sessionRepository;

  const UpdateCartItemQuantityUseCase(
    this._repository,
    this._sessionRepository,
  );

  Future<ApiResult<void>> call({required int itemId, required int quantity}) {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.updateQuantity(
        token: token,
        itemId: itemId,
        quantity: quantity,
      ),
    );
  }
}
