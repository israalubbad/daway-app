import '../../../../core/erroring/failure.dart';
import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../entities/inquiry.dart';
import '../repositories/pharmacy_inquiries_repository.dart';

class GetPharmacyInquiriesUseCase {
  final PharmacyInquiriesRepository _repository;
  final SessionRepository _sessionRepository;

  const GetPharmacyInquiriesUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<InquiriesOverview>> call() async {
    final session = await _sessionRepository.getSession();
    if (session == null) {
      return ApiError(
        ApiFailure(message: sessionExpiredMessage),
      );
    }
    return _repository.getInquiries(token: session.token);
  }
}
