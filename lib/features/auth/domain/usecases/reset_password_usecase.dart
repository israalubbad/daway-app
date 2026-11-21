import '../../../../core/erroring/failure.dart';
import '../../../../core/helpers/api_result.dart';
import '../../../../core/helpers/validators.dart';
import '../repositories/password_reset_repository.dart';

import '../../../../core/localization/translations.dart';
class ResetPasswordUseCase {

  final PasswordResetRepository _repository;

  const ResetPasswordUseCase(this._repository);

  Future<ApiResult<void>> call({
    required String phone,
    required String resetToken,
    required String password,
    required String passwordConfirmation,
  }) {
    if (!Validators.isValidPassword(password)) {
      return Future.value(
        ApiError(
          ValidationFailure('كلمة المرور يجب أن تكون {0} أحرف على الأقل'.trArgs([Validators.minPasswordLength])),
        ),
      );
    }
    if (password != passwordConfirmation) {
      return Future.value(ApiError(ValidationFailure('كلمتا المرور غير متطابقتين'.tr)));
    }
    return _repository.resetPassword(
      phone: phone,
      resetToken: resetToken,
      password: password,
    );
  }
}
