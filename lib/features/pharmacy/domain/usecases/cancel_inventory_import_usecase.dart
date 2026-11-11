import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../repositories/pharmacy_inventory_import_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class CancelInventoryImportUseCase {
  final PharmacyInventoryImportRepository _repository;
  final SessionRepository _sessionRepository;

  const CancelInventoryImportUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<void>> call(String importId) {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.cancel(token: token, importId: importId),
    );
  }
}
