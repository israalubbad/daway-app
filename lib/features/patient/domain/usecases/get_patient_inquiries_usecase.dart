import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../entities/pharmacy_inquiry.dart';
import '../repositories/patient_inquiries_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class GetPatientInquiriesUseCase {
  final PatientInquiriesRepository _repository;
  final SessionRepository _sessionRepository;

  const GetPatientInquiriesUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<List<PharmacyInquiry>>> call() {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.getInquiries(token: token),
    );
  }
}
