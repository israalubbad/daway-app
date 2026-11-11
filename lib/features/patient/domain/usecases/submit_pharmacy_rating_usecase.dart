import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../repositories/patient_ratings_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class SubmitPharmacyRatingUseCase {
  final PatientRatingsRepository _repository;
  final SessionRepository _sessionRepository;

  const SubmitPharmacyRatingUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<void>> call({
    required int pharmacyId,
    required int stars,
    String? comment,
  }) {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.submitPharmacyRating(
        token: token,
        pharmacyId: pharmacyId,
        stars: stars,
        comment: comment,
      ),
    );
  }
}
