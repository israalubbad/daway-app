import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../entities/patient_address.dart';
import '../repositories/patient_addresses_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class GetPatientAddressesUseCase {
  final PatientAddressesRepository _repository;
  final SessionRepository _sessionRepository;

  const GetPatientAddressesUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<List<PatientAddress>>> call() {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.getAddresses(token: token),
    );
  }
}
