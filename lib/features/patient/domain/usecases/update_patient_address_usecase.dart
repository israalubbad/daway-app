import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../entities/patient_address.dart';
import '../repositories/patient_addresses_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class UpdatePatientAddressUseCase {
  final PatientAddressesRepository _repository;
  final SessionRepository _sessionRepository;

  const UpdatePatientAddressUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<PatientAddress>> call({
    required int addressId,
    required String label,
    required String recipientName,
    required String phone,
    required String address,
    required double latitude,
    required double longitude,
    required bool isDefault,
  }) {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.updateAddress(
        token: token,
        addressId: addressId,
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
