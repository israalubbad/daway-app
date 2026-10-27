import '../../../../core/helpers/api_result.dart';

abstract class PharmacyPasswordRepository {
  /// `POST /pharmacy/change-password`. The collection documents no body, so the
  /// fields follow the patient endpoint's (`current_password`, `new_password`)
  /// plus a `new_password_confirmation` in case the backend asks for one.
  Future<ApiResult<void>> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  });
}
