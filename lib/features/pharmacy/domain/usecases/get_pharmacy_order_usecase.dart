import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../entities/pharmacy_order.dart';
import '../repositories/pharmacy_orders_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

/// One sub-order in full, for the order-details screen.
class GetPharmacyOrderUseCase {
  final PharmacyOrdersRepository _repository;
  final SessionRepository _sessionRepository;

  const GetPharmacyOrderUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<PharmacyOrder>> call({required int orderId}) {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.getOrder(token: token, orderId: orderId),
    );
  }
}
