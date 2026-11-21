import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/helpers/api_result.dart';
import '../../domain/usecases/close_patient_account_usecase.dart';
import 'account_closure_state.dart';

/// Deletes the signed-in patient's account for good.
class AccountClosureCubit extends Cubit<AccountClosureState> {
  final ClosePatientAccountUseCase _closeAccount;

  AccountClosureCubit(this._closeAccount) : super(const AccountClosureIdle());

  Future<void> deleteAccount({String? reason}) async {
    // A second tap while the first is in flight must not send a second request.
    if (state is AccountClosureSubmitting || state is AccountClosureDone) return;
    emit(const AccountClosureSubmitting());
    final result = await _closeAccount(reason: reason);
    if (isClosed) return;
    switch (result) {
      case Success():
        emit(const AccountClosureDone());
      case ApiError(:final failure):
        emit(AccountClosureIdle(errorMessage: failure.message));
    }
  }

  /// The sheet was reopened: a failure message belongs to the try that
  /// produced it, not to the next one.
  void clearError() {
    final current = state;
    if (current is AccountClosureIdle && current.errorMessage != null) {
      emit(const AccountClosureIdle());
    }
  }
}
