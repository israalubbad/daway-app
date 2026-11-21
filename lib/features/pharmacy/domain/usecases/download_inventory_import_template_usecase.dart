import 'dart:typed_data';

import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../repositories/pharmacy_inventory_import_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class DownloadInventoryImportTemplateUseCase {
  final PharmacyInventoryImportRepository _repository;
  final SessionRepository _sessionRepository;

  const DownloadInventoryImportTemplateUseCase(
    this._repository,
    this._sessionRepository,
  );

  Future<ApiResult<Uint8List>> call() {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.downloadTemplate(token: token),
    );
  }
}
