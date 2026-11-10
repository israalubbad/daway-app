import '../../../../core/erroring/failure.dart';
import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../entities/pharmacy_inquiry.dart';
import '../repositories/patient_inquiries_repository.dart';

class CreatePatientInquiryUseCase {
  final PatientInquiriesRepository _repository;
  final SessionRepository _sessionRepository;

  const CreatePatientInquiryUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<PharmacyInquiry>> call({
    required int pharmacyId,
    int? medicineId,
    required String message,
  }) async {
    final session = await _sessionRepository.getSession();
    if (session == null) {
      return const ApiError(
        ApiFailure(message: sessionExpiredMessage),
      );
    }
    return _repository.createInquiry(
      token: session.token,
      pharmacyId: pharmacyId,
      medicineId: medicineId,
      message: message,
    );
  }
}
