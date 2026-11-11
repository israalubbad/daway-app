import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../repositories/cart_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class AddCartItemUseCase {
  final CartRepository _repository;
  final SessionRepository _sessionRepository;

  const AddCartItemUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<void>> call({
    int? pharmacyMedicineId,
    required int pharmacyId,
    required int medicineId,
    int quantity = 1,
  }) {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.addItem(
        token: token,
        pharmacyMedicineId: pharmacyMedicineId,
        pharmacyId: pharmacyId,
        medicineId: medicineId,
        quantity: quantity,
      ),
    );
  }
}
