import '../../../../core/erroring/failure.dart';
import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../entities/inquiry.dart';
import '../repositories/pharmacy_inquiries_repository.dart';

class UpdateInquiryStatusUseCase {
  final PharmacyInquiriesRepository _repository;
  final SessionRepository _sessionRepository;

  const UpdateInquiryStatusUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<void>> call({
    required int inquiryId,
    required InquiryStatus status,
  }) async {
    final session = await _sessionRepository.getSession();
    if (session == null) {
      return const ApiError(
        ApiFailure(message: sessionExpiredMessage),
      );
    }
    return _repository.updateInquiryStatus(
      token: session.token,
      inquiryId: inquiryId,
      status: status,
    );
  }
}
