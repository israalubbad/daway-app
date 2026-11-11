import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../entities/medicine_catalog_item.dart';
import '../repositories/pharmacy_medicine_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class SearchMedicineCatalogUseCase {
  final PharmacyMedicineRepository _repository;
  final SessionRepository _sessionRepository;

  const SearchMedicineCatalogUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<List<MedicineCatalogItem>>> call(String query) {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.searchCatalog(token: token, query: query),
    );
  }
}
