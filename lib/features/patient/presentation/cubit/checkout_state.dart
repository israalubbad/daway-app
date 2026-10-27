import '../../domain/entities/patient_address.dart';

sealed class CheckoutState {
  const CheckoutState();
}

class CheckoutLoading extends CheckoutState {
  const CheckoutLoading();
}

class CheckoutLoadFailure extends CheckoutState {
  final String message;

  const CheckoutLoadFailure(this.message);
}

/// "أكمل طلبك": the saved addresses to deliver to, the coupon, and the
/// subtotal of the cart being ordered.
class CheckoutReady extends CheckoutState {
  final List<PatientAddress> addresses;
  final int? selectedAddressId;
  final double subtotal;

  /// The coupon that was accepted, and what it takes off. Null/0 when none.
  final String? couponCode;
  final double discount;
  final bool isApplyingCoupon;
  final bool isSubmitting;

  const CheckoutReady({
    required this.addresses,
    required this.selectedAddressId,
    required this.subtotal,
    this.couponCode,
    this.discount = 0,
    this.isApplyingCoupon = false,
    this.isSubmitting = false,
  });

  PatientAddress? get selectedAddress {
    for (final address in addresses) {
      if (address.id == selectedAddressId) return address;
    }
    return null;
  }

  /// Subtotal less the coupon. The delivery fee is not in it: only the server
  /// knows that, once the order exists.
  double get productsTotal =>
      (subtotal - discount).clamp(0, double.infinity).toDouble();

  CheckoutReady copyWith({
    List<PatientAddress>? addresses,
    int? selectedAddressId,
    String? couponCode,
    bool clearCoupon = false,
    double? discount,
    bool? isApplyingCoupon,
    bool? isSubmitting,
  }) {
    return CheckoutReady(
      addresses: addresses ?? this.addresses,
      selectedAddressId: selectedAddressId ?? this.selectedAddressId,
      subtotal: subtotal,
      couponCode: clearCoupon ? null : (couponCode ?? this.couponCode),
      discount: clearCoupon ? 0 : (discount ?? this.discount),
      isApplyingCoupon: isApplyingCoupon ?? this.isApplyingCoupon,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}
