import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/helpers/api_result.dart';
import '../../../../core/helpers/validators.dart';
import '../../domain/usecases/change_pharmacy_password_usecase.dart';

import '../../../../core/localization/translations.dart';

sealed class ChangePharmacyPasswordState {
  const ChangePharmacyPasswordState();
}

class ChangePasswordIdle extends ChangePharmacyPasswordState {
  /// What is wrong with the last attempt, if anything.
  final String? message;

  const ChangePasswordIdle({this.message});
}

class ChangePasswordSaving extends ChangePharmacyPasswordState {
  const ChangePasswordSaving();
}

class ChangePasswordSuccess extends ChangePharmacyPasswordState {
  const ChangePasswordSuccess();
}

class ChangePharmacyPasswordCubit extends Cubit<ChangePharmacyPasswordState> {
  final ChangePharmacyPasswordUseCase _useCase;

  ChangePharmacyPasswordCubit(this._useCase) : super(const ChangePasswordIdle());

  Future<void> submit({
    required String currentPassword,
    required String newPassword,
    required String confirmation,
  }) async {
    if (state is ChangePasswordSaving) return;

    if (currentPassword.isEmpty) {
      emit(ChangePasswordIdle(message: 'أدخل كلمة المرور الحالية'.tr));
      return;
    }
    if (!Validators.isValidPassword(newPassword)) {
      emit(
        ChangePasswordIdle(
          message: 'كلمة المرور الجديدة يجب أن تكون {0} أحرف على الأقل'.trArgs([Validators.minPasswordLength]),
        ),
      );
      return;
    }
    if (newPassword != confirmation) {
      emit(ChangePasswordIdle(message: 'كلمتا المرور غير متطابقتين'.tr));
      return;
    }
    if (newPassword == currentPassword) {
      emit(ChangePasswordIdle(message: 'كلمة المرور الجديدة هي نفسها الحالية'.tr));
      return;
    }

    emit(const ChangePasswordSaving());

    final result = await _useCase(currentPassword: currentPassword, newPassword: newPassword);

    switch (result) {
      case Success():
        emit(const ChangePasswordSuccess());
      case ApiError(:final failure):
        emit(ChangePasswordIdle(message: failure.message));
    }
  }
}
