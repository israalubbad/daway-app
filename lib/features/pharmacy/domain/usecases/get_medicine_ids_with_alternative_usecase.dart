import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../repositories/pharmacy_alternatives_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class GetMedicineIdsWithAlternativeUseCase {
  final PharmacyAlternativesRepository _repository;
  final SessionRepository _sessionRepository;

  const GetMedicineIdsWithAlternativeUseCase(
    this._repository,
    this._sessionRepository,
  );

  Future<ApiResult<Set<int>>> call() {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.getBaseMedicineIdsWithAlternatives(token: token),
    );
  }
}
