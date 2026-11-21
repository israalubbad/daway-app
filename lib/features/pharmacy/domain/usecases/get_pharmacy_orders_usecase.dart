import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../entities/pharmacy_order.dart';
import '../repositories/pharmacy_orders_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class GetPharmacyOrdersUseCase {
  final PharmacyOrdersRepository _repository;
  final SessionRepository _sessionRepository;

  const GetPharmacyOrdersUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<List<PharmacyOrder>>> call() {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.getOrders(token: token),
    );
  }
}
