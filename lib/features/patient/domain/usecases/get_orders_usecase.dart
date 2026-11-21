import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../entities/order.dart';
import '../repositories/orders_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class GetOrdersUseCase {
  final OrdersRepository _repository;
  final SessionRepository _sessionRepository;

  const GetOrdersUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<List<Order>>> call() {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.getOrders(token: token),
    );
  }
}
