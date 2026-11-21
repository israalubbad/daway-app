import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../repositories/pharmacy_medicine_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class AddPharmacyMedicineUseCase {
  final PharmacyMedicineRepository _repository;
  final SessionRepository _sessionRepository;

  const AddPharmacyMedicineUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<void>> call({
    int? medicineId,
    int? mohMedicineId,
    required double price,
    required int quantity,
    required bool isAvailable,
    String? imageUrl,
  }) {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.addMedicine(
        token: token,
        medicineId: medicineId,
        mohMedicineId: mohMedicineId,
        price: price,
        quantity: quantity,
        isAvailable: isAvailable,
        imageUrl: imageUrl,
      ),
    );
  }
}
