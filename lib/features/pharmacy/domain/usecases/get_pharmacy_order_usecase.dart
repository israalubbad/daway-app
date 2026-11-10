import '../../../../core/erroring/failure.dart';
import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../entities/pharmacy_order.dart';
import '../repositories/pharmacy_orders_repository.dart';

/// One sub-order in full, for the order-details screen.
class GetPharmacyOrderUseCase {
  final PharmacyOrdersRepository _repository;
  final SessionRepository _sessionRepository;

  const GetPharmacyOrderUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<PharmacyOrder>> call({required int orderId}) async {
    final session = await _sessionRepository.getSession();
    if (session == null) {
      return const ApiError(ApiFailure(message: sessionExpiredMessage));
    }
    return _repository.getOrder(token: session.token, orderId: orderId);
  }
}
