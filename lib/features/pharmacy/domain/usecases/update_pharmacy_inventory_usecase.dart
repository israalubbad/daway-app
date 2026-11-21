import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../entities/inventory_item_update.dart';
import '../repositories/pharmacy_inventory_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class UpdatePharmacyInventoryUseCase {
  final PharmacyInventoryRepository _repository;
  final SessionRepository _sessionRepository;

  const UpdatePharmacyInventoryUseCase(
    this._repository,
    this._sessionRepository,
  );

  Future<ApiResult<void>> call(List<InventoryItemUpdate> items) {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.updateInventory(token: token, items: items),
    );
  }
}
