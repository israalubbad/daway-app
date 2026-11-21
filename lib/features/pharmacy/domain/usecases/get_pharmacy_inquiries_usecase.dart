import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../entities/inquiry.dart';
import '../repositories/pharmacy_inquiries_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class GetPharmacyInquiriesUseCase {
  final PharmacyInquiriesRepository _repository;
  final SessionRepository _sessionRepository;

  const GetPharmacyInquiriesUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<InquiriesOverview>> call() {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.getInquiries(token: token),
    );
  }
}
