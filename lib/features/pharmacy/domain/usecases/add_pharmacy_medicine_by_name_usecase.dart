import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../repositories/pharmacy_medicine_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class AddPharmacyMedicineByNameUseCase {
  final PharmacyMedicineRepository _repository;
  final SessionRepository _sessionRepository;

  const AddPharmacyMedicineByNameUseCase(
    this._repository,
    this._sessionRepository,
  );

  Future<ApiResult<void>> call({
    required String tradeName,
    String? tradeNameAr,
    String? activeIngredient,
    int? categoryId,
    required double price,
    required int quantity,
    required bool isAvailable,
    String? imageUrl,
  }) {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.addMedicineByName(
        token: token,
        tradeName: tradeName,
        tradeNameAr: tradeNameAr,
        activeIngredient: activeIngredient,
        categoryId: categoryId,
        price: price,
        quantity: quantity,
        isAvailable: isAvailable,
        imageUrl: imageUrl,
      ),
    );
  }
}
