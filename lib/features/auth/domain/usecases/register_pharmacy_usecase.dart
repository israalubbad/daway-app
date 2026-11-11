import '../../../../core/erroring/failure.dart';
import '../../../../core/helpers/api_result.dart';
import '../../../../core/helpers/validators.dart';
import '../repositories/auth_repository.dart';

import '../../../../core/localization/translations.dart';
class RegisterPharmacyUseCase {

  final AuthRepository _repository;

  const RegisterPharmacyUseCase(this._repository);

  Future<ApiResult<void>> call({
    required String pharmacyName,
    required String phone,
    required String region,
    required String password,
  }) {
    if (pharmacyName.trim().isEmpty || phone.trim().isEmpty || region.trim().isEmpty) {
      return Future.value(
        ApiError(ValidationFailure('يرجى تعبئة جميع الحقول المطلوبة'.tr)),
      );
    }
    if (!Validators.isValidPassword(password)) {
      return Future.value(
        ApiError(
          ValidationFailure('كلمة المرور يجب أن تكون {0} أحرف على الأقل'.trArgs([Validators.minPasswordLength])),
        ),
      );
    }
    return _repository.registerPharmacy(
      pharmacyName: pharmacyName.trim(),
      phone: phone.trim(),
      region: region.trim(),
      password: password,
    );
  }
}
