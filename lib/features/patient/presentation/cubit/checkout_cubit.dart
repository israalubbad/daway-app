import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/erroring/failure.dart';
import '../../../../core/helpers/api_result.dart';
import '../../../../core/helpers/idempotency_key.dart';
import '../../../../core/models/picked_location.dart';
import '../../domain/usecases/checkout_flow_usecases.dart';
import '../../domain/usecases/checkout_usecase.dart';
import '../../domain/usecases/create_patient_address_usecase.dart';
import '../../domain/usecases/get_checkout_quote_usecase.dart';
import '../../domain/usecases/get_patient_addresses_usecase.dart';
import '../../domain/usecases/get_patient_profile_usecase.dart';
import 'checkout_state.dart';

/// What the patient is told when the server refused the order because the
/// price it quoted has moved.
const quoteChangedMessage = 'تغيّر السعر، راجع الإجمالي الجديد ثم أكّد الطلب';

/// Drives "أكمل طلبك": picks the delivery address, validates the coupon, shows
/// the server's price for the cart delivered there (`POST
/// /patient/checkout/quote`) and creates the order (`POST /patient/checkout`)
/// guarded by that price. The cart being ordered is the whole server-side
/// cart, so only its [subtotal] is needed here, to ask the server what a
/// coupon takes off.
class CheckoutCubit extends Cubit<CheckoutState> {
  final double subtotal;
  final GetPatientAddressesUseCase _getAddressesUseCase;
  final CreatePatientAddressUseCase _createAddressUseCase;
  final GetPatientProfileUseCase _getProfileUseCase;
  final ValidateCouponUseCase _validateCouponUseCase;
  final CheckoutUseCase _checkoutUseCase;
  final GetCheckoutQuoteUseCase _getQuoteUseCase;
  final String Function() _newIdempotencyKey;

  /// Names the order about to be made. It changes with every new quote (a
  /// different price is a different order) and stays the same while the same
  /// order is retried, so a repeated tap or a retried request after a timeout
  /// can never create two orders.
  late String _idempotencyKey;

  /// Counts the quote requests, so a slow, older answer (an address changed
  /// twice quickly) can't overwrite the newer one.
  int _latestQuote = 0;

  CheckoutCubit(
    this.subtotal,
    this._getAddressesUseCase,
    this._createAddressUseCase,
    this._getProfileUseCase,
    this._validateCouponUseCase,
    this._checkoutUseCase,
    this._getQuoteUseCase, {
    String Function() idempotencyKeyFactory = newIdempotencyKey,
  })  : _newIdempotencyKey = idempotencyKeyFactory,
        super(const CheckoutLoading()) {
    _idempotencyKey = _newIdempotencyKey();
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
        unawaited(refreshQuote());
      case ApiError(:final failure):
        emit(CheckoutLoadFailure(failure.message));
    }
  }

  void selectAddress(int addressId) {
    final current = state;
    if (current is! CheckoutReady || current.selectedAddressId == addressId) return;
    emit(current.copyWith(selectedAddressId: addressId));
    unawaited(refreshQuote());
  }

  /// Asks the server what the cart costs delivered to the selected address
  /// with the accepted coupon. Run again whenever one of those changes, and
  /// when the user retries after a failure.
  ///
  /// A 422 means the server has delivery pricing switched off: that is not an
  /// error to show, the order is simply made without a guard.
  Future<void> refreshQuote() async {
    final current = state;
    if (current is! CheckoutReady) return;
    final request = ++_latestQuote;
    final addressId = current.selectedAddressId;
    if (addressId == null) {
      emit(current.withQuote());
      return;
    }

    // A new price is a new order as far as the server's duplicate check goes.
    _idempotencyKey = _newIdempotencyKey();
    emit(current.withQuote(isQuoting: true));
    final result = await _getQuoteUseCase(
      addressId: addressId,
      couponCode: current.couponCode,
    );
    if (isClosed || request != _latestQuote) return;
    final latest = state;
    if (latest is! CheckoutReady) return;

    switch (result) {
      case Success(:final data):
        emit(latest.withQuote(quote: data));
      case ApiError(:final failure):
        final pricingOff = failure is ApiFailure && failure.statusCode == 422;
        emit(latest.withQuote(error: pricingOff ? null : failure.message));
    }
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
            unawaited(refreshQuote());
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
        unawaited(refreshQuote());
        return null;
      case ApiError(:final failure):
        final hadCoupon = latest.couponCode != null;
        emit(latest.copyWith(clearCoupon: true, isApplyingCoupon: false));
        // A coupon that was applied and is now gone changes the price.
        if (hadCoupon) unawaited(refreshQuote());
        return failure.message;
    }
  }

  void removeCoupon() {
    final current = state;
    if (current is! CheckoutReady) return;
    emit(current.copyWith(clearCoupon: true));
    unawaited(refreshQuote());
  }

  /// Creates the order. Returns its id, or an ApiError with the reason.
  ///
  /// Held back (null) while the price is being read, so an order is never
  /// guarded by a price that is about to be replaced. When the server says the
  /// price moved (409), the quote is read again and the caller is told to
  /// look at the new total before confirming.
  Future<ApiResult<int>?> submit() async {
    final current = state;
    if (current is! CheckoutReady || current.isSubmitting || current.isQuoting) return null;
    final addressId = current.selectedAddressId;
    if (addressId == null) return null;

    final quote = current.quote;
    emit(current.copyWith(isSubmitting: true));
    final result = await _checkoutUseCase(
      addressId: addressId,
      couponCode: current.couponCode,
      quote: quote,
      idempotencyKey: quote == null ? null : _idempotencyKey,
    );
    if (isClosed) return null;
    final latest = state;
    if (latest is CheckoutReady) emit(latest.copyWith(isSubmitting: false));

    if (quote != null && result is ApiError<int>) {
      final failure = result.failure;
      if (failure is ApiFailure && failure.statusCode == 409) {
        unawaited(refreshQuote());
        return ApiError(
          ApiFailure(message: quoteChangedMessage, code: failure.code, statusCode: 409),
        );
      }
    }
    return result;
  }
}
