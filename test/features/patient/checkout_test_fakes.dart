import 'package:daway_app/core/erroring/failure.dart';
import 'package:daway_app/core/helpers/api_result.dart';
import 'package:daway_app/features/auth/domain/entities/account_type.dart';
import 'package:daway_app/features/auth/domain/entities/user_session.dart';
import 'package:daway_app/features/auth/domain/repositories/session_repository.dart';
import 'package:daway_app/features/patient/domain/entities/checkout_flow.dart';
import 'package:daway_app/features/patient/domain/entities/checkout_quote.dart';
import 'package:daway_app/features/patient/domain/entities/order.dart';
import 'package:daway_app/features/patient/domain/entities/patient_address.dart';
import 'package:daway_app/features/patient/domain/entities/patient_profile.dart';
import 'package:daway_app/features/patient/domain/repositories/checkout_flow_repository.dart';
import 'package:daway_app/features/patient/domain/repositories/orders_repository.dart';
import 'package:daway_app/features/patient/domain/repositories/patient_addresses_repository.dart';
import 'package:daway_app/features/patient/domain/repositories/patient_profile_repository.dart';

/// Fakes shared by the order-flow tests (checkout, payment, confirmation).

const testBanks = [
  PaymentBank(id: 1, name: 'بنك فلسطين', accountNumber: '0597601911'),
  PaymentBank(id: 2, name: 'محفظة PalPay', accountNumber: '0597601911'),
  PaymentBank(id: 3, name: 'محفظة Jawwal Pay', accountNumber: '0597601911'),
];

OrderPayment testPayment({
  String paymentStatus = 'pending',
  bool canSubmitReceipt = true,
  double? deliveryFee = 15,
  bool awaitingDeliveryFee = false,
  double grandTotal = 150,
}) {
  return OrderPayment(
    orderId: 11,
    grandTotal: grandTotal,
    deliveryFee: deliveryFee,
    paymentStatus: paymentStatus,
    canSubmitReceipt: canSubmitReceipt,
    awaitingDeliveryFee: awaitingDeliveryFee,
    banks: testBanks,
  );
}

OrderTracking testTracking(OrderStatus status) {
  return OrderTracking(
    status: status,
    history: [OrderTrackingEvent(status: status, at: DateTime(2026, 10, 27, 15, 36))],
  );
}

class FakeSessionRepository implements SessionRepository {
  UserSession? savedSession = const UserSession(accountType: AccountType.patient, token: 'tok-1');

  @override
  Future<void> saveSession(UserSession session) async => savedSession = session;

  @override
  Future<UserSession?> getSession() async => savedSession;

  @override
  Future<void> clearSession() async => savedSession = null;
}

class FakeCheckoutFlowRepository implements CheckoutFlowRepository {
  ApiResult<double> couponResult = const Success(4);
  ApiResult<OrderPayment> paymentResult = Success(testPayment());
  ApiResult<OrderTracking> trackingResult = Success(testTracking(OrderStatus.confirmed));
  ApiResult<void> receiptResult = const Success(null);
  ApiResult<void> problemResult = const Success(null);

  String? lastCoupon;
  int? receiptBankId;
  String? problemMessage;

  @override
  Future<ApiResult<double>> validateCoupon({
    required String token,
    required String code,
    required double orderTotal,
  }) async {
    lastCoupon = code;
    return couponResult;
  }

  @override
  Future<ApiResult<OrderPayment>> getPayment({required String token, required int orderId}) async =>
      paymentResult;

  @override
  Future<ApiResult<void>> submitReceipt({
    required String token,
    required int orderId,
    required int bankId,
    required double amount,
    required String receiptPath,
  }) async {
    receiptBankId = bankId;
    return receiptResult;
  }

  @override
  Future<ApiResult<void>> reportProblem({
    required String token,
    required int orderId,
    required String message,
  }) async {
    problemMessage = message;
    return problemResult;
  }

  @override
  Future<ApiResult<OrderTracking>> getTracking({required String token, required int orderId}) async =>
      trackingResult;
}

class FakeOrdersRepository implements OrdersRepository {
  ApiResult<int> checkoutResult = const Success(11);
  int? lastAddressId;
  String? lastCouponCode;

  /// What the quote call answers. By default delivery pricing is off (the
  /// server answers 422), so a flow that does not care about the quote runs
  /// without one.
  ApiResult<CheckoutQuote> quoteResult =
      const ApiError(ApiFailure(message: 'pricing off', statusCode: 422));
  int quoteCallCount = 0;
  String? lastQuoteCouponCode;
  CheckoutQuote? lastQuote;
  String? lastIdempotencyKey;

  @override
  Future<ApiResult<List<Order>>> getOrders({required String token}) async => const Success([]);

  @override
  Future<ApiResult<void>> cancelOrder({required String token, required int orderId}) async =>
      const Success(null);

  @override
  Future<ApiResult<CheckoutQuote>> getCheckoutQuote({
    required String token,
    required int addressId,
    String? couponCode,
  }) async {
    quoteCallCount++;
    lastQuoteCouponCode = couponCode;
    return quoteResult;
  }

  @override
  Future<ApiResult<int>> checkout({
    required String token,
    required int addressId,
    String? couponCode,
    String? notes,
    CheckoutQuote? quote,
    String? idempotencyKey,
  }) async {
    lastQuote = quote;
    lastIdempotencyKey = idempotencyKey;
    lastAddressId = addressId;
    lastCouponCode = couponCode;
    return checkoutResult;
  }
}

const testAddress = PatientAddress(
  id: 1,
  label: 'المنزل',
  recipientName: 'مريض',
  phone: '0597601911',
  address: 'غزة - الرمال',
  latitude: 31.5,
  longitude: 34.47,
  isDefault: true,
);

class FakeAddressesRepository implements PatientAddressesRepository {
  ApiResult<List<PatientAddress>> addressesResult = const Success([testAddress]);

  @override
  Future<ApiResult<List<PatientAddress>>> getAddresses({required String token}) async =>
      addressesResult;

  @override
  Future<ApiResult<PatientAddress>> createAddress({
    required String token,
    required String label,
    required String recipientName,
    required String phone,
    required String address,
    required double latitude,
    required double longitude,
    bool isDefault = true,
  }) async =>
      const Success(testAddress);

  @override
  Future<ApiResult<PatientAddress>> updateAddress({
    required String token,
    required int addressId,
    required String label,
    required String recipientName,
    required String phone,
    required String address,
    required double latitude,
    required double longitude,
    required bool isDefault,
  }) async =>
      const Success(testAddress);

  @override
  Future<ApiResult<void>> deleteAddress({required String token, required int addressId}) async =>
      const Success(null);
}

class FakeProfileRepository implements PatientProfileRepository {
  @override
  Future<ApiResult<PatientProfile>> getProfile({required String token}) async =>
      const Success(PatientProfile(name: 'مريض', phone: '0597601911'));

  @override
  Future<ApiResult<void>> updateProfile({
    required String token,
    required PatientProfile profile,
  }) async =>
      const Success(null);
}
