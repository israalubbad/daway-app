import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../entities/medicine.dart';
import '../repositories/pharmacy_inventory_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class GetPharmacyInventoryUseCase {
  final PharmacyInventoryRepository _repository;
  final SessionRepository _sessionRepository;

  const GetPharmacyInventoryUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<List<Medicine>>> call() {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.getInventory(token: token),
    );
  }
}
