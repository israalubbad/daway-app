import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../entities/patient_address.dart';
import '../repositories/patient_addresses_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class CreatePatientAddressUseCase {
  final PatientAddressesRepository _repository;
  final SessionRepository _sessionRepository;

  const CreatePatientAddressUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<PatientAddress>> call({
    required String label,
    required String recipientName,
    required String phone,
    required String address,
    required double latitude,
    required double longitude,
    bool isDefault = true,
  }) {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.createAddress(
        token: token,
        label: label,
        recipientName: recipientName,
        phone: phone,
        address: address,
        latitude: latitude,
        longitude: longitude,
        isDefault: isDefault,
      ),
    );
  }
}
