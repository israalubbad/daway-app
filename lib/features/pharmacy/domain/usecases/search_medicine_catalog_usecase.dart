import '../../../../core/erroring/failure.dart';
import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../entities/medicine_catalog_item.dart';
import '../repositories/pharmacy_medicine_repository.dart';

class SearchMedicineCatalogUseCase {
  final PharmacyMedicineRepository _repository;
  final SessionRepository _sessionRepository;

  const SearchMedicineCatalogUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<List<MedicineCatalogItem>>> call(String query) async {
    final session = await _sessionRepository.getSession();
    if (session == null) {
      return ApiError(
        ApiFailure(message: sessionExpiredMessage),
      );
    }
    return _repository.searchCatalog(token: session.token, query: query);
  }
}
