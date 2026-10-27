import '../../../../core/erroring/failure.dart';
import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../entities/inventory_import_preview.dart';
import '../repositories/pharmacy_inventory_import_repository.dart';

class AnalyzeInventoryImportUseCase {
  final PharmacyInventoryImportRepository _repository;
  final SessionRepository _sessionRepository;

  const AnalyzeInventoryImportUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<InventoryImportPreview>> call(String filePath) async {
    final session = await _sessionRepository.getSession();
    if (session == null) {
      return const ApiError(
        ApiFailure(message: 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مرة أخرى'),
      );
    }
    return _repository.preview(token: session.token, filePath: filePath);
  }
}
