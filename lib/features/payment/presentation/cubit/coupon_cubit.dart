import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/helpers/api_result.dart';
import '../../domain/usecases/payment_usecases.dart';

class CouponState {
  final bool isChecking;

  /// The code the server accepted, with the discount it quoted.
  final String? appliedCode;
  final double? discount;
  final String? error;

  const CouponState({this.isChecking = false, this.appliedCode, this.discount, this.error});
}

/// The coupon box of the cart. The discount shown is the quote of the server;
/// the final amount still comes from the order payment summary.
class CouponCubit extends Cubit<CouponState> {
  final ValidateCouponUseCase _validateCouponUseCase;

  CouponCubit(this._validateCouponUseCase) : super(const CouponState());

  /// The code to send with checkout, only once it has been validated.
  String? get appliedCode => state.appliedCode;

  Future<void> apply(String code, {required double orderTotal}) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty || state.isChecking) return;
    emit(const CouponState(isChecking: true));
    final result = await _validateCouponUseCase(code: trimmed, orderTotal: orderTotal);
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(CouponState(appliedCode: trimmed, discount: data));
      case ApiError(:final failure):
        emit(CouponState(error: failure.message));
    }
  }

  void remove() => emit(const CouponState());
}
