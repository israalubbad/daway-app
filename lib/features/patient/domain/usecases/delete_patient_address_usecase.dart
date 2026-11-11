import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../repositories/patient_addresses_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class DeletePatientAddressUseCase {
  final PatientAddressesRepository _repository;
  final SessionRepository _sessionRepository;

  const DeletePatientAddressUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<void>> call(int addressId) {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.deleteAddress(token: token, addressId: addressId),
    );
  }
}
