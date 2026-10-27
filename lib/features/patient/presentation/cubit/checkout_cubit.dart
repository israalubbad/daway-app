import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/helpers/api_result.dart';
import '../../../../core/models/picked_location.dart';
import '../../domain/usecases/checkout_flow_usecases.dart';
import '../../domain/usecases/checkout_usecase.dart';
import '../../domain/usecases/create_patient_address_usecase.dart';
import '../../domain/usecases/get_patient_addresses_usecase.dart';
import '../../domain/usecases/get_patient_profile_usecase.dart';
import 'checkout_state.dart';

/// Drives "أكمل طلبك": picks the delivery address, validates the coupon and
/// creates the order (`POST /patient/checkout`). The cart being ordered is
/// the whole server-side cart, so only its [subtotal] is needed here, to
/// ask the server what a coupon takes off.
class CheckoutCubit extends Cubit<CheckoutState> {
  final double subtotal;
  final GetPatientAddressesUseCase _getAddressesUseCase;
  final CreatePatientAddressUseCase _createAddressUseCase;
  final GetPatientProfileUseCase _getProfileUseCase;
  final ValidateCouponUseCase _validateCouponUseCase;
  final CheckoutUseCase _checkoutUseCase;

  CheckoutCubit(
    this.subtotal,
    this._getAddressesUseCase,
    this._createAddressUseCase,
    this._getProfileUseCase,
    this._validateCouponUseCase,
    this._checkoutUseCase,
  ) : super(const CheckoutLoading()) {
    load();
  }

  Future<void> load() async {
    emit(const CheckoutLoading());
    final result = await _getAddressesUseCase();
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        final selected = data.isEmpty
            ? null
            : data.firstWhere((a) => a.isDefault, orElse: () => data.first).id;
        emit(
          CheckoutReady(
            addresses: data,
            selectedAddressId: selected,
            subtotal: subtotal,
          ),
        );
      case ApiError(:final failure):
        emit(CheckoutLoadFailure(failure.message));
    }
  }

  void selectAddress(int addressId) {
    final current = state;
    if (current is! CheckoutReady) return;
    emit(current.copyWith(selectedAddressId: addressId));
  }

  /// Saves [location] as a new address and selects it. Returns null on
  /// success, or a user-facing error message.
  Future<String?> addAddress(PickedLocation location) async {
    final current = state;
    if (current is! CheckoutReady) return null;

    final profileResult = await _getProfileUseCase();
    if (isClosed) return null;
    switch (profileResult) {
      case ApiError(:final failure):
        return failure.message;
      case Success(:final data):
        final created = await _createAddressUseCase(
          label: 'عنوان التوصيل',
          recipientName: data.name,
          phone: data.phone,
          address: location.address,
          latitude: location.latitude,
          longitude: location.longitude,
          isDefault: current.addresses.isEmpty,
        );
        if (isClosed) return null;
        final latest = state;
        if (latest is! CheckoutReady) return null;
        switch (created) {
          case Success(:final data):
            emit(
              latest.copyWith(
                addresses: [...latest.addresses, data],
                selectedAddressId: data.id,
              ),
            );
            return null;
          case ApiError(:final failure):
            return failure.message;
        }
    }
  }

  /// Asks the server what [code] takes off the cart. Returns null when it was
  /// accepted, or the server's reason it was not.
  Future<String?> applyCoupon(String code) async {
    final current = state;
    if (current is! CheckoutReady || current.isApplyingCoupon) return null;
    final trimmed = code.trim();
    if (trimmed.isEmpty) return 'اكتب كود الخصم أولاً';

    emit(current.copyWith(isApplyingCoupon: true));
    final result = await _validateCouponUseCase(
      code: trimmed,
      orderTotal: current.subtotal,
    );
    if (isClosed) return null;
    final latest = state;
    if (latest is! CheckoutReady) return null;

    switch (result) {
      case Success(:final data):
        emit(
          latest.copyWith(
            couponCode: trimmed,
            discount: data,
            isApplyingCoupon: false,
          ),
        );
        return null;
      case ApiError(:final failure):
        emit(latest.copyWith(clearCoupon: true, isApplyingCoupon: false));
        return failure.message;
    }
  }

  void removeCoupon() {
    final current = state;
    if (current is! CheckoutReady) return;
    emit(current.copyWith(clearCoupon: true));
  }

  /// Creates the order. Returns its id, or an ApiError with the reason.
  Future<ApiResult<int>?> submit() async {
    final current = state;
    if (current is! CheckoutReady || current.isSubmitting) return null;
    final addressId = current.selectedAddressId;
    if (addressId == null) return null;

    emit(current.copyWith(isSubmitting: true));
    final result = await _checkoutUseCase(
      addressId: addressId,
      couponCode: current.couponCode,
    );
    if (isClosed) return null;
    final latest = state;
    if (latest is CheckoutReady) emit(latest.copyWith(isSubmitting: false));
    return result;
  }
}
