import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../repositories/pharmacy_inventory_import_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class CommitInventoryImportUseCase {
  final PharmacyInventoryImportRepository _repository;
  final SessionRepository _sessionRepository;

  const CommitInventoryImportUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<void>> call(String importId) {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.commit(token: token, importId: importId),
    );
  }
}
