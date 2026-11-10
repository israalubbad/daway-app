import '../../../../core/erroring/error_handler.dart';
import '../../../../core/erroring/failure.dart';
import '../../../../core/helpers/api_result.dart';
import '../../domain/entities/closure_request.dart';
import '../../domain/repositories/account_closure_repository.dart';
import '../datasources/account_closure_remote_data_source.dart';
import '../models/closure_request_model.dart';

class AccountClosureRepositoryImpl implements AccountClosureRepository {
  final AccountClosureRemoteDataSource _remoteDataSource;

  const AccountClosureRepositoryImpl(this._remoteDataSource);

  @override
  Future<ApiResult<void>> closePatientAccount({required String token, String? reason}) async {
    try {
      await _remoteDataSource.closePatientAccount(token: token, reason: reason);
      return const Success(null);
    } catch (e) {
      return ApiError(mapExceptionToFailure(e));
    }
  }

  @override
  Future<ApiResult<ClosureRequest?>> getPharmacyClosureRequest({required String token}) async {
    try {
      final response = await _remoteDataSource.getPharmacyClosureRequest(token: token);
      return Success(ClosureRequestModel.fromResponse(response.data));
    } catch (e) {
      final failure = mapExceptionToFailure(e);
      // "No such request" is how an API may say the pharmacy never asked.
      if (failure is ApiFailure && failure.statusCode == 404) return const Success(null);
      return ApiError(failure);
    }
  }

  @override
  Future<ApiResult<ClosureRequest>> requestPharmacyClosure({
    required String token,
    String? reason,
  }) async {
    try {
      final response = await _remoteDataSource.requestPharmacyClosure(token: token, reason: reason);
      // The request was accepted even if the body says nothing more: it is
      // waiting for the admin.
      return Success(
        ClosureRequestModel.fromResponse(response.data) ??
            ClosureRequest(status: ClosureRequestStatus.pending, reason: reason),
      );
    } catch (e) {
      return ApiError(mapExceptionToFailure(e));
    }
  }
}
