import '../../../../core/erroring/failure.dart';
import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../entities/medicine.dart';
import '../repositories/pharmacy_inventory_repository.dart';

class GetPharmacyInventoryUseCase {
  final PharmacyInventoryRepository _repository;
  final SessionRepository _sessionRepository;

  const GetPharmacyInventoryUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<List<Medicine>>> call() async {
    final session = await _sessionRepository.getSession();
    if (session == null) {
      return const ApiError(
        ApiFailure(message: sessionExpiredMessage),
      );
    }
    return _repository.getInventory(token: session.token);
  }
}
