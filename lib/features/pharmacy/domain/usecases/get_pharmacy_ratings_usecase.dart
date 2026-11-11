import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../entities/rating.dart';
import '../repositories/pharmacy_ratings_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class GetPharmacyRatingsUseCase {
  final PharmacyRatingsRepository _repository;
  final SessionRepository _sessionRepository;

  const GetPharmacyRatingsUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<RatingsOverview>> call() {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.getRatings(token: token),
    );
  }
}
