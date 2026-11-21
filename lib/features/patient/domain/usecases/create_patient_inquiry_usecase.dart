import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../entities/pharmacy_inquiry.dart';
import '../repositories/patient_inquiries_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class CreatePatientInquiryUseCase {
  final PatientInquiriesRepository _repository;
  final SessionRepository _sessionRepository;

  const CreatePatientInquiryUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<PharmacyInquiry>> call({
    required int pharmacyId,
    int? medicineId,
    required String message,
  }) {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.createInquiry(
        token: token,
        pharmacyId: pharmacyId,
        medicineId: medicineId,
        message: message,
      ),
    );
  }
}
