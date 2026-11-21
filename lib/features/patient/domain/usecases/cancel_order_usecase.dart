import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../repositories/orders_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class CancelOrderUseCase {
  final OrdersRepository _repository;
  final SessionRepository _sessionRepository;

  const CancelOrderUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<void>> call(int orderId) {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.cancelOrder(token: token, orderId: orderId),
    );
  }
}
