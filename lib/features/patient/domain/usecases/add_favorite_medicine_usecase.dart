import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../repositories/favorites_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class AddFavoriteMedicineUseCase {
  final FavoritesRepository _repository;
  final SessionRepository _sessionRepository;

  const AddFavoriteMedicineUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<void>> call(int medicineId) {
    return withSessionToken(
      _sessionRepository,
      (token) =>
          _repository.addFavoriteMedicine(token: token, medicineId: medicineId),
    );
  }
}
