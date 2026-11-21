import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../entities/medicine.dart';
import '../repositories/pharmacy_medicine_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class GetPharmacyMedicinesUseCase {
  final PharmacyMedicineRepository _repository;
  final SessionRepository _sessionRepository;

  const GetPharmacyMedicinesUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<List<Medicine>>> call() {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.getMedicines(token: token),
    );
  }
}
