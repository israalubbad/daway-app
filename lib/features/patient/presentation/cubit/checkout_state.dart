import '../../domain/entities/checkout_quote.dart';
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

  /// The server's price for this cart at the selected address, delivery
  /// included. Null while it is being read ([isQuoting]), when it could not be
  /// read ([quoteError]), when no address is chosen, and when the server has
  /// delivery pricing switched off.
  final CheckoutQuote? quote;
  final bool isQuoting;

  /// Why the quote could not be read; null when it was read or is not offered.
  final String? quoteError;

  const CheckoutReady({
    required this.addresses,
    required this.selectedAddressId,
    required this.subtotal,
    this.couponCode,
    this.discount = 0,
    this.isApplyingCoupon = false,
    this.isSubmitting = false,
    this.quote,
    this.isQuoting = false,
    this.quoteError,
  });

  PatientAddress? get selectedAddress {
    for (final address in addresses) {
      if (address.id == selectedAddressId) return address;
    }
    return null;
  }

  /// Subtotal less the coupon, before delivery.
  double get productsTotal =>
      (subtotal - discount).clamp(0, double.infinity).toDouble();

  /// What the patient is told they pay: the server's grand total (delivery
  /// included) when it quoted one, otherwise the products alone.
  double get grandTotal => quote?.grandTotal ?? productsTotal;

  /// The coupon's saving as the server priced it, else as the coupon check did.
  double get shownDiscount => quote?.discount ?? discount;

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
      quote: quote,
      isQuoting: isQuoting,
      quoteError: quoteError,
    );
  }

  /// This state with its quote replaced — [quote] and [error] are taken as
  /// given (null clears them), unlike [copyWith], which leaves the quote alone.
  CheckoutReady withQuote({CheckoutQuote? quote, String? error, bool isQuoting = false}) {
    return CheckoutReady(
      addresses: addresses,
      selectedAddressId: selectedAddressId,
      subtotal: subtotal,
      couponCode: couponCode,
      discount: discount,
      isApplyingCoupon: isApplyingCoupon,
      isSubmitting: isSubmitting,
      quote: quote,
      isQuoting: isQuoting,
      quoteError: error,
    );
  }
}
