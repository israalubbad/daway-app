import '../../../../core/erroring/failure.dart';
import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../entities/pharmacy_order.dart';
import '../repositories/pharmacy_orders_repository.dart';

class GetPharmacyOrdersUseCase {
  final PharmacyOrdersRepository _repository;
  final SessionRepository _sessionRepository;

  const GetPharmacyOrdersUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<List<PharmacyOrder>>> call() async {
    final session = await _sessionRepository.getSession();
    if (session == null) {
      return const ApiError(
        ApiFailure(message: sessionExpiredMessage),
      );
    }
    return _repository.getOrders(token: session.token);
  }
}
