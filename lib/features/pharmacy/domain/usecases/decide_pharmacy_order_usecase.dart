import '../../../../core/erroring/failure.dart';
import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../repositories/pharmacy_orders_repository.dart';

/// Accepts ([accept] true) or rejects a sub-order.
class DecidePharmacyOrderUseCase {
  final PharmacyOrdersRepository _repository;
  final SessionRepository _sessionRepository;

  const DecidePharmacyOrderUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<void>> call({required int orderId, required bool accept}) async {
    final session = await _sessionRepository.getSession();
    if (session == null) {
      return const ApiError(
        ApiFailure(message: 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مرة أخرى'),
      );
    }
    return _repository.decide(token: session.token, orderId: orderId, accept: accept);
  }
}
