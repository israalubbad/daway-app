import '../../../../core/helpers/api_result.dart';
import '../entities/closure_request.dart';

abstract class AccountClosureRepository {
  /// Closes the signed-in patient's account for good (`POST /account/closure`
  /// with the confirmation word the backend requires). The server revokes the
  /// account's tokens. [reason] is optional.
  Future<ApiResult<void>> closePatientAccount({required String token, String? reason});

  /// The pharmacy's closure request, or null when it never asked.
  Future<ApiResult<ClosureRequest?>> getPharmacyClosureRequest({required String token});

  /// Asks the admin to close the pharmacy's account. The pharmacy stays
  /// signed in and usable until the admin decides.
  Future<ApiResult<ClosureRequest>> requestPharmacyClosure({
    required String token,
    String? reason,
  });
}
