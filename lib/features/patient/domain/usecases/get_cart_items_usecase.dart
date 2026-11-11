import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../entities/cart_item.dart';
import '../repositories/cart_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class GetCartItemsUseCase {
  final CartRepository _repository;
  final SessionRepository _sessionRepository;

  const GetCartItemsUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<List<CartItem>>> call() {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.getItems(token: token),
    );
  }
}
