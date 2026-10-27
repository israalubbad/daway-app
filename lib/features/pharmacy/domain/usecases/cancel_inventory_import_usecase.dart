import '../../../../core/erroring/failure.dart';
import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../repositories/pharmacy_inventory_import_repository.dart';

class CancelInventoryImportUseCase {
  final PharmacyInventoryImportRepository _repository;
  final SessionRepository _sessionRepository;

  const CancelInventoryImportUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<void>> call(String importId) async {
    final session = await _sessionRepository.getSession();
    if (session == null) {
      return const ApiError(
        ApiFailure(message: 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مرة أخرى'),
      );
    }
    return _repository.cancel(token: session.token, importId: importId);
  }
}
