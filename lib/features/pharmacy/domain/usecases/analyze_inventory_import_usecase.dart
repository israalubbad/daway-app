import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../entities/inventory_import_preview.dart';
import '../repositories/pharmacy_inventory_import_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class AnalyzeInventoryImportUseCase {
  final PharmacyInventoryImportRepository _repository;
  final SessionRepository _sessionRepository;

  const AnalyzeInventoryImportUseCase(
    this._repository,
    this._sessionRepository,
  );

  Future<ApiResult<InventoryImportPreview>> call(String filePath) {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.preview(token: token, filePath: filePath),
    );
  }
}
