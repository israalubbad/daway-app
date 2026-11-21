import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../entities/favorite_medicine.dart';
import '../repositories/favorites_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class GetFavoriteMedicinesUseCase {
  final FavoritesRepository _repository;
  final SessionRepository _sessionRepository;

  const GetFavoriteMedicinesUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<List<FavoriteMedicine>>> call() {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.getFavoriteMedicines(token: token),
    );
  }
}
