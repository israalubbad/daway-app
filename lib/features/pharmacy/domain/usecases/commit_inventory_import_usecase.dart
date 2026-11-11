import '../../../../core/erroring/failure.dart';
import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../repositories/pharmacy_inventory_import_repository.dart';

class CommitInventoryImportUseCase {
  final PharmacyInventoryImportRepository _repository;
  final SessionRepository _sessionRepository;

  const CommitInventoryImportUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<void>> call(String importId) async {
    final session = await _sessionRepository.getSession();
    if (session == null) {
      return ApiError(
        ApiFailure(message: sessionExpiredMessage),
      );
    }
    return _repository.commit(token: session.token, importId: importId);
  }
}
