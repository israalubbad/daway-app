import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../entities/pharmacy_dashboard_stats.dart';
import '../repositories/pharmacy_dashboard_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class GetPharmacyDashboardStatsUseCase {
  final PharmacyDashboardRepository _repository;
  final SessionRepository _sessionRepository;

  const GetPharmacyDashboardStatsUseCase(
    this._repository,
    this._sessionRepository,
  );

  Future<ApiResult<PharmacyDashboardStats>> call() {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.getDashboardStats(token: token),
    );
  }
}
