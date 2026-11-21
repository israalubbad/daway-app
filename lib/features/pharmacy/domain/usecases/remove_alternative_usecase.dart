import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../repositories/pharmacy_alternatives_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class RemoveAlternativeUseCase {
  final PharmacyAlternativesRepository _repository;
  final SessionRepository _sessionRepository;

  const RemoveAlternativeUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<void>> call({
    required int baseMedicineId,
    required int alternativeId,
  }) {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.removeAlternative(
        token: token,
        baseMedicineId: baseMedicineId,
        alternativeId: alternativeId,
      ),
    );
  }
}
