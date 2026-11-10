import 'dart:async';

import 'package:daway_app/core/erroring/failure.dart';
import 'package:daway_app/core/helpers/api_result.dart';
import 'package:daway_app/core/models/picked_location.dart';
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
import 'package:daway_app/features/patient/domain/usecases/checkout_flow_usecases.dart';
import 'package:daway_app/features/patient/domain/usecases/checkout_usecase.dart';
import 'package:daway_app/features/patient/domain/usecases/get_checkout_quote_usecase.dart';
import 'package:daway_app/features/patient/domain/usecases/create_patient_address_usecase.dart';
import 'package:daway_app/features/patient/domain/usecases/get_patient_addresses_usecase.dart';
import 'package:daway_app/features/patient/domain/usecases/get_patient_profile_usecase.dart';
import 'package:daway_app/features/patient/presentation/cubit/checkout_cubit.dart';
import 'package:daway_app/features/patient/presentation/cubit/checkout_state.dart';
import 'package:flutter_test/flutter_test.dart';

const _defaultAddress = PatientAddress(
  id: 1,
  label: 'المنزل',
  recipientName: 'مريض',
  phone: '0599112233',
  address: 'غزة',
  latitude: 31.5,
  longitude: 34.47,
  isDefault: true,
);

const _nonDefaultAddress = PatientAddress(
  id: 2,
  label: 'العمل',
  recipientName: 'مريض',
  phone: '0599112233',
  address: 'رام الله',
  latitude: 31.9,
  longitude: 35.2,
  isDefault: false,
);

const _newAddress = PatientAddress(
  id: 3,
  label: 'عنوان التوصيل',
  recipientName: 'مريض',
  phone: '0599112233',
  address: 'خان يونس',
  latitude: 31.3,
  longitude: 34.3,
  isDefault: true,
);

class _FakeAddressesRepository implements PatientAddressesRepository {
  ApiResult<List<PatientAddress>> addressesResult = const Success([]);
  ApiResult<PatientAddress> createResult = const Success(_newAddress);

  @override
  Future<ApiResult<void>> deleteAddress({
    required String token,
    required int addressId,
  }) async => const Success(null);

  @override
  Future<ApiResult<List<PatientAddress>>> getAddresses({
    required String token,
  }) async => addressesResult;

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
  }) async => createResult;

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
  }) async => createResult;
}

class _FakeProfileRepository implements PatientProfileRepository {
  ApiResult<PatientProfile> profileResult = const Success(
    PatientProfile(name: 'مريض', phone: '0599112233'),
  );

  @override
  Future<ApiResult<PatientProfile>> getProfile({required String token}) async =>
      profileResult;

  @override
  Future<ApiResult<void>> updateProfile({
    required String token,
    required PatientProfile profile,
  }) async => const Success(null);
}

class _FakeOrdersRepository implements OrdersRepository {
  ApiResult<int> checkoutResult = const Success(42);
  int? lastAddressId;
  String? lastCouponCode;
  int checkoutCallCount = 0;

  /// What the quote call answers. By default delivery pricing is off (the
  /// server answers 422), so a flow that does not care about the quote runs
  /// without one.
  ApiResult<CheckoutQuote> quoteResult =
      const ApiError(ApiFailure(message: 'pricing off', statusCode: 422));
  int quoteCallCount = 0;
  String? lastQuoteCouponCode;
  CheckoutQuote? lastQuote;
  String? lastIdempotencyKey;

  /// Quote answers held back until the test completes them, oldest first;
  /// once empty, [quoteResult] answers at once.
  final List<Completer<ApiResult<CheckoutQuote>>> quoteGates = [];

  @override
  Future<ApiResult<void>> cancelOrder({
    required String token,
    required int orderId,
  }) async => const Success(null);

  @override
  Future<ApiResult<List<Order>>> getOrders({required String token}) async =>
      const Success([]);

  @override
  Future<ApiResult<CheckoutQuote>> getCheckoutQuote({
    required String token,
    required int addressId,
    String? couponCode,
  }) async {
    quoteCallCount++;
    lastQuoteCouponCode = couponCode;
    if (quoteGates.isNotEmpty) return quoteGates.removeAt(0).future;
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
    checkoutCallCount++;
    lastQuote = quote;
    lastIdempotencyKey = idempotencyKey;
    lastAddressId = addressId;
    lastCouponCode = couponCode;
    return checkoutResult;
  }
}

class _FakeCheckoutFlowRepository implements CheckoutFlowRepository {
  ApiResult<double> couponResult = const Success(4);
  String? lastCode;
  double? lastOrderTotal;

  @override
  Future<ApiResult<double>> validateCoupon({
    required String token,
    required String code,
    required double orderTotal,
  }) async {
    lastCode = code;
    lastOrderTotal = orderTotal;
    return couponResult;
  }

  @override
  Future<ApiResult<OrderPayment>> getPayment({
    required String token,
    required int orderId,
  }) => throw UnimplementedError();

  @override
  Future<ApiResult<void>> submitReceipt({
    required String token,
    required int orderId,
    required int bankId,
    required double amount,
    required String receiptPath,
  }) => throw UnimplementedError();

  @override
  Future<ApiResult<void>> reportProblem({
    required String token,
    required int orderId,
    required String message,
  }) => throw UnimplementedError();

  @override
  Future<ApiResult<OrderTracking>> getTracking({
    required String token,
    required int orderId,
  }) => throw UnimplementedError();
}

class _FakeSessionRepository implements SessionRepository {
  UserSession? savedSession = const UserSession(
    accountType: AccountType.patient,
    token: 'tok-1',
  );

  @override
  Future<void> saveSession(UserSession session) async => savedSession = session;

  @override
  Future<UserSession?> getSession() async => savedSession;

  @override
  Future<void> clearSession() async => savedSession = null;
}

void main() {
  late _FakeAddressesRepository addressesRepository;
  late _FakeProfileRepository profileRepository;
  late _FakeOrdersRepository ordersRepository;
  late _FakeCheckoutFlowRepository flowRepository;
  late _FakeSessionRepository sessionRepository;
  var keyCounter = 0;

  CheckoutCubit buildCubit() {
    return CheckoutCubit(
      139,
      GetPatientAddressesUseCase(addressesRepository, sessionRepository),
      CreatePatientAddressUseCase(addressesRepository, sessionRepository),
      GetPatientProfileUseCase(profileRepository, sessionRepository),
      ValidateCouponUseCase(flowRepository, sessionRepository),
      CheckoutUseCase(ordersRepository, sessionRepository),
      GetCheckoutQuoteUseCase(ordersRepository, sessionRepository),
      idempotencyKeyFactory: () => 'key-${++keyCounter}',
    );
  }

  Future<CheckoutCubit> readyCubit() async {
    final cubit = buildCubit();
    addTearDown(cubit.close);
    await Future<void>.delayed(Duration.zero);
    return cubit;
  }

  setUp(() {
    keyCounter = 0;
    addressesRepository = _FakeAddressesRepository();
    profileRepository = _FakeProfileRepository();
    ordersRepository = _FakeOrdersRepository();
    flowRepository = _FakeCheckoutFlowRepository();
    sessionRepository = _FakeSessionRepository();
  });

  test('selects the default address when the addresses load', () async {
    addressesRepository.addressesResult = const Success([
      _nonDefaultAddress,
      _defaultAddress,
    ]);

    final cubit = await readyCubit();

    final state = cubit.state as CheckoutReady;
    expect(state.selectedAddressId, _defaultAddress.id);
    expect(state.subtotal, 139);
  });

  test('falls back to the first address when none is the default', () async {
    addressesRepository.addressesResult = const Success([_nonDefaultAddress]);

    final cubit = await readyCubit();

    expect(
      (cubit.state as CheckoutReady).selectedAddressId,
      _nonDefaultAddress.id,
    );
  });

  test('has no selected address when the patient has none', () async {
    final cubit = await readyCubit();

    expect((cubit.state as CheckoutReady).selectedAddressId, isNull);
  });

  test('fails to load with the addresses error', () async {
    addressesRepository.addressesResult = const ApiError(
      ApiFailure(message: 'تعذر التحميل'),
    );

    final cubit = await readyCubit();

    expect((cubit.state as CheckoutLoadFailure).message, 'تعذر التحميل');
  });

  test('selectAddress switches the chosen address', () async {
    addressesRepository.addressesResult = const Success([
      _defaultAddress,
      _nonDefaultAddress,
    ]);
    final cubit = await readyCubit();

    cubit.selectAddress(_nonDefaultAddress.id);

    expect((cubit.state as CheckoutReady).selectedAddress, _nonDefaultAddress);
  });

  test('addAddress saves the picked location and selects it', () async {
    addressesRepository.addressesResult = const Success([_defaultAddress]);
    final cubit = await readyCubit();

    final error = await cubit.addAddress(
      const PickedLocation(
        latitude: 31.3,
        longitude: 34.3,
        address: 'خان يونس',
      ),
    );

    expect(error, isNull);
    final state = cubit.state as CheckoutReady;
    expect(state.addresses, [_defaultAddress, _newAddress]);
    expect(state.selectedAddressId, _newAddress.id);
  });

  test(
    'addAddress returns the error and keeps the selection when saving fails',
    () async {
      addressesRepository.addressesResult = const Success([_defaultAddress]);
      addressesRepository.createResult = const ApiError(
        ApiFailure(message: 'فشل الحفظ'),
      );
      final cubit = await readyCubit();

      final error = await cubit.addAddress(
        const PickedLocation(
          latitude: 31.3,
          longitude: 34.3,
          address: 'خان يونس',
        ),
      );

      expect(error, 'فشل الحفظ');
      expect(
        (cubit.state as CheckoutReady).selectedAddressId,
        _defaultAddress.id,
      );
    },
  );

  group('coupon', () {
    test(
      'an accepted code takes its discount off the products total',
      () async {
        final cubit = await readyCubit();

        final error = await cubit.applyCoupon(' SAVE4 ');

        expect(error, isNull);
        expect(flowRepository.lastCode, 'SAVE4');
        expect(flowRepository.lastOrderTotal, 139);
        final state = cubit.state as CheckoutReady;
        expect(state.couponCode, 'SAVE4');
        expect(state.discount, 4);
        expect(state.productsTotal, 135);
      },
    );

    test('a rejected code returns the reason and leaves no discount', () async {
      flowRepository.couponResult = const ApiError(
        ApiFailure(message: 'الكود منتهي'),
      );
      final cubit = await readyCubit();

      final error = await cubit.applyCoupon('OLD');

      expect(error, 'الكود منتهي');
      final state = cubit.state as CheckoutReady;
      expect(state.couponCode, isNull);
      expect(state.productsTotal, 139);
    });

    test('an empty code is refused without asking the server', () async {
      final cubit = await readyCubit();

      final error = await cubit.applyCoupon('  ');

      expect(error, isNotNull);
      expect(flowRepository.lastCode, isNull);
    });

    test('removeCoupon clears the code and the discount', () async {
      final cubit = await readyCubit();
      await cubit.applyCoupon('SAVE4');

      cubit.removeCoupon();

      final state = cubit.state as CheckoutReady;
      expect(state.couponCode, isNull);
      expect(state.discount, 0);
    });
  });

  group('submit', () {
    test(
      'creates the order with the chosen address and coupon and returns its id',
      () async {
        addressesRepository.addressesResult = const Success([
          _defaultAddress,
          _nonDefaultAddress,
        ]);
        final cubit = await readyCubit();
        cubit.selectAddress(_nonDefaultAddress.id);
        await cubit.applyCoupon('SAVE4');
        // The order waits for the price the coupon just changed.
        await Future<void>.delayed(Duration.zero);

        final result = await cubit.submit();

        expect(result, isA<Success<int>>());
        expect((result! as Success<int>).data, 42);
        expect(ordersRepository.lastAddressId, _nonDefaultAddress.id);
        expect(ordersRepository.lastCouponCode, 'SAVE4');
        expect((cubit.state as CheckoutReady).isSubmitting, isFalse);
      },
    );

    test('does nothing without an address', () async {
      final cubit = await readyCubit();

      final result = await cubit.submit();

      expect(result, isNull);
      expect(ordersRepository.checkoutCallCount, 0);
    });

    test('returns the server error when the order is refused', () async {
      addressesRepository.addressesResult = const Success([_defaultAddress]);
      ordersRepository.checkoutResult = const ApiError(
        ApiFailure(message: 'السلة فارغة'),
      );
      final cubit = await readyCubit();

      final result = await cubit.submit();

      expect((result! as ApiError<int>).failure.message, 'السلة فارغة');
    });
  });

  group('delivery quote', () {
    const quote = CheckoutQuote(
      subtotal: 139,
      discount: 0,
      total: 139,
      deliveryFee: 9,
      grandTotal: 148,
    );
    const otherQuote = CheckoutQuote(
      subtotal: 139,
      discount: 0,
      total: 139,
      deliveryFee: 15,
      grandTotal: 154,
    );

    setUp(() {
      addressesRepository.addressesResult = const Success([
        _defaultAddress,
        _nonDefaultAddress,
      ]);
    });

    test('is read for the default address once the addresses load', () async {
      ordersRepository.quoteResult = const Success(quote);

      final cubit = await readyCubit();

      final state = cubit.state as CheckoutReady;
      expect(state.quote, quote);
      expect(state.isQuoting, isFalse);
      expect(state.grandTotal, 148);
      expect(ordersRepository.quoteCallCount, 1);
    });

    test('the server pricing of the coupon replaces the coupon check', () async {
      ordersRepository.quoteResult = const Success(
        CheckoutQuote(subtotal: 139, discount: 10, total: 129, deliveryFee: 9, grandTotal: 138),
      );

      final cubit = await readyCubit();

      final state = cubit.state as CheckoutReady;
      expect(state.shownDiscount, 10);
      expect(state.grandTotal, 138);
    });

    test('a 422 (delivery pricing off) leaves no quote and no error', () async {
      final cubit = await readyCubit();

      final state = cubit.state as CheckoutReady;
      expect(state.quote, isNull);
      expect(state.quoteError, isNull);
      expect(state.grandTotal, 139);
    });

    test('any other failure is kept as the reason there is no quote', () async {
      ordersRepository.quoteResult = const ApiError(
        ApiFailure(message: 'تعذر الاتصال', statusCode: 500),
      );

      final cubit = await readyCubit();

      final state = cubit.state as CheckoutReady;
      expect(state.quote, isNull);
      expect(state.quoteError, 'تعذر الاتصال');
    });

    test('refreshQuote tries again after a failure', () async {
      ordersRepository.quoteResult = const ApiError(
        ApiFailure(message: 'تعذر الاتصال', statusCode: 500),
      );
      final cubit = await readyCubit();
      ordersRepository.quoteResult = const Success(quote);

      await cubit.refreshQuote();

      final state = cubit.state as CheckoutReady;
      expect(state.quote, quote);
      expect(state.quoteError, isNull);
    });

    test('is not asked for without an address', () async {
      addressesRepository.addressesResult = const Success([]);

      final cubit = await readyCubit();

      expect((cubit.state as CheckoutReady).quote, isNull);
      expect(ordersRepository.quoteCallCount, 0);
    });

    test('is read again when another address is chosen', () async {
      ordersRepository.quoteResult = const Success(quote);
      final cubit = await readyCubit();
      ordersRepository.quoteResult = const Success(otherQuote);

      cubit.selectAddress(_nonDefaultAddress.id);
      await Future<void>.delayed(Duration.zero);

      expect((cubit.state as CheckoutReady).quote, otherQuote);
      expect(ordersRepository.quoteCallCount, 2);
    });

    test('choosing the address that is already chosen does not ask again', () async {
      final cubit = await readyCubit();

      cubit.selectAddress(_defaultAddress.id);
      await Future<void>.delayed(Duration.zero);

      expect(ordersRepository.quoteCallCount, 1);
    });

    test('is read again with the coupon when one is accepted, and without it when removed',
        () async {
      final cubit = await readyCubit();

      await cubit.applyCoupon('SAVE4');
      await Future<void>.delayed(Duration.zero);
      expect(ordersRepository.lastQuoteCouponCode, 'SAVE4');

      cubit.removeCoupon();
      await Future<void>.delayed(Duration.zero);
      expect(ordersRepository.lastQuoteCouponCode, isNull);
      expect(ordersRepository.quoteCallCount, 3);
    });

    test('a slow, older answer does not overwrite a newer one', () async {
      final first = Completer<ApiResult<CheckoutQuote>>();
      final second = Completer<ApiResult<CheckoutQuote>>();
      ordersRepository.quoteGates.addAll([first, second]);
      final cubit = await readyCubit();

      cubit.selectAddress(_nonDefaultAddress.id);
      await Future<void>.delayed(Duration.zero);
      second.complete(const Success(otherQuote));
      await Future<void>.delayed(Duration.zero);
      first.complete(const Success(quote));
      await Future<void>.delayed(Duration.zero);

      expect((cubit.state as CheckoutReady).quote, otherQuote);
    });

    test('the order waits while the price is being read', () async {
      final gate = Completer<ApiResult<CheckoutQuote>>();
      ordersRepository.quoteGates.add(gate);
      final cubit = await readyCubit();

      expect((cubit.state as CheckoutReady).isQuoting, isTrue);
      final result = await cubit.submit();

      expect(result, isNull);
      expect(ordersRepository.checkoutCallCount, 0);
    });

    test('the order is guarded by the quote and a key', () async {
      ordersRepository.quoteResult = const Success(quote);
      final cubit = await readyCubit();

      await cubit.submit();

      expect(ordersRepository.lastQuote, quote);
      expect(ordersRepository.lastIdempotencyKey, isNotNull);
    });

    test('retrying the same order keeps the same key', () async {
      ordersRepository.quoteResult = const Success(quote);
      ordersRepository.checkoutResult = const ApiError(
        ApiFailure(message: 'تعذر الاتصال', statusCode: 500),
      );
      final cubit = await readyCubit();

      await cubit.submit();
      final firstKey = ordersRepository.lastIdempotencyKey;
      await cubit.submit();

      expect(ordersRepository.lastIdempotencyKey, firstKey);
      expect(ordersRepository.checkoutCallCount, 2);
    });

    test('a new quote is a new order, with a new key', () async {
      ordersRepository.quoteResult = const Success(quote);
      final cubit = await readyCubit();
      await cubit.submit();
      final firstKey = ordersRepository.lastIdempotencyKey;

      cubit.selectAddress(_nonDefaultAddress.id);
      await Future<void>.delayed(Duration.zero);
      await cubit.submit();

      expect(ordersRepository.lastIdempotencyKey, isNot(firstKey));
    });

    test('without a quote the order carries neither a quote nor a key', () async {
      final cubit = await readyCubit();

      await cubit.submit();

      expect(ordersRepository.checkoutCallCount, 1);
      expect(ordersRepository.lastQuote, isNull);
      expect(ordersRepository.lastIdempotencyKey, isNull);
    });

    test('a 409 says the price moved and reads the new price', () async {
      ordersRepository.quoteResult = const Success(quote);
      ordersRepository.checkoutResult = const ApiError(
        ApiFailure(message: 'quote_changed', code: 'quote_changed', statusCode: 409),
      );
      final cubit = await readyCubit();
      ordersRepository.quoteResult = const Success(otherQuote);

      final result = await cubit.submit();
      await Future<void>.delayed(Duration.zero);

      expect((result! as ApiError<int>).failure.message, quoteChangedMessage);
      expect((cubit.state as CheckoutReady).quote, otherQuote);
      expect(ordersRepository.quoteCallCount, 2);
    });

    test('a 409 on an order sent without a quote is passed on as it came', () async {
      ordersRepository.checkoutResult = const ApiError(
        ApiFailure(message: 'تعارض', statusCode: 409),
      );
      final cubit = await readyCubit();

      final result = await cubit.submit();

      expect((result! as ApiError<int>).failure.message, 'تعارض');
    });
  });
}
