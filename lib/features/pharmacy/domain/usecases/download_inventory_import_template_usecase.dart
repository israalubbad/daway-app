import 'dart:typed_data';

import '../../../../core/erroring/failure.dart';
import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../repositories/pharmacy_inventory_import_repository.dart';

class DownloadInventoryImportTemplateUseCase {
  final PharmacyInventoryImportRepository _repository;
  final SessionRepository _sessionRepository;

  const DownloadInventoryImportTemplateUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<Uint8List>> call() async {
    final session = await _sessionRepository.getSession();
    if (session == null) {
      return const ApiError(
        ApiFailure(message: sessionExpiredMessage),
      );
    }
    return _repository.downloadTemplate(token: session.token);
  }
}
