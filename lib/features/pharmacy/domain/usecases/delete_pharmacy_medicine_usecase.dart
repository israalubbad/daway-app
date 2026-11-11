import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../repositories/pharmacy_medicine_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class DeletePharmacyMedicineUseCase {
  final PharmacyMedicineRepository _repository;
  final SessionRepository _sessionRepository;

  const DeletePharmacyMedicineUseCase(
    this._repository,
    this._sessionRepository,
  );

  Future<ApiResult<void>> call(int pharmacyMedicineId) {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.deleteMedicine(
        token: token,
        pharmacyMedicineId: pharmacyMedicineId,
      ),
    );
  }
}
