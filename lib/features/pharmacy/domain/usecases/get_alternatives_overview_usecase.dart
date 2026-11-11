import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../entities/alternatives_overview.dart';
import '../entities/medicine.dart';
import '../repositories/pharmacy_alternatives_repository.dart';
import 'get_pharmacy_medicines_usecase.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class GetAlternativesOverviewUseCase {
  final PharmacyAlternativesRepository _repository;
  final GetPharmacyMedicinesUseCase _getPharmacyMedicinesUseCase;
  final SessionRepository _sessionRepository;

  const GetAlternativesOverviewUseCase(
    this._repository,
    this._getPharmacyMedicinesUseCase,
    this._sessionRepository,
  );

  Future<ApiResult<AlternativesOverview>> call(Medicine baseMedicine) {
    return withSessionToken(_sessionRepository, (token) async {
      // The candidates endpoint alone doesn't carry enough to render a card
      // (see PharmacyAlternativesRepositoryImpl) — the full stock list is
      // fetched here so the repository can hydrate each candidate with its
      // real price/quantity/name instead of the sparse fields it returns.
      final medicinesResult = await _getPharmacyMedicinesUseCase();
      return switch (medicinesResult) {
        ApiError(:final failure) => ApiError(failure),
        Success(:final data) => _repository.getAlternativesOverview(
          token: token,
          baseMedicine: baseMedicine,
          allMedicines: data,
        ),
      };
    });
  }
}
