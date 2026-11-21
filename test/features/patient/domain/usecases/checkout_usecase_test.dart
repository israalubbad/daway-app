import 'package:daway_app/core/erroring/failure.dart';
import 'package:daway_app/core/helpers/api_result.dart';
import 'package:daway_app/features/auth/domain/entities/account_type.dart';
import 'package:daway_app/features/auth/domain/entities/user_session.dart';
import 'package:daway_app/features/patient/domain/entities/checkout_quote.dart';
import 'package:daway_app/features/patient/domain/entities/order.dart';
import 'package:daway_app/features/patient/domain/repositories/orders_repository.dart';
import 'package:daway_app/features/patient/domain/usecases/checkout_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../helpers/in_memory_session_repository.dart';

class _FakeOrdersRepository implements OrdersRepository {

  @override
  Future<ApiResult<void>> cancelOrder({required String token, required int orderId}) async =>
      const Success(null);
  ApiResult<int> checkoutResult = const Success(1);
  String? lastToken;
  int? lastAddressId;
  String? lastCouponCode;
  CheckoutQuote? lastQuote;
  String? lastIdempotencyKey;

  @override
  Future<ApiResult<List<Order>>> getOrders({required String token}) async => const Success([]);

  @override
  Future<ApiResult<CheckoutQuote>> getCheckoutQuote({
    required String token,
    required int addressId,
    String? couponCode,
  }) => throw UnimplementedError();

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
    lastToken = token;
    lastAddressId = addressId;
    lastCouponCode = couponCode;
    return checkoutResult;
  }
}

void main() {
  test('passes the session token, address id and coupon through to the repository', () async {
    final repository = _FakeOrdersRepository();
    final sessionRepository = InMemorySessionRepository()
      ..savedSession = const UserSession(accountType: AccountType.patient, token: 'tok-1');
    final useCase = CheckoutUseCase(repository, sessionRepository);

    final result = await useCase(addressId: 1, couponCode: 'SAVE20');

    expect(repository.lastToken, 'tok-1');
    expect(repository.lastAddressId, 1);
    expect(repository.lastCouponCode, 'SAVE20');
    expect(result, isA<Success<int>>());
  });

  test('returns a session failure without calling the repository when logged out', () async {
    final repository = _FakeOrdersRepository();
    final useCase = CheckoutUseCase(repository, InMemorySessionRepository());

    final result = await useCase(addressId: 1);

    expect(result, isA<ApiError<int>>());
    expect(repository.lastAddressId, isNull);
  });

  test('surfaces a repository failure (e.g. empty cart) unchanged', () async {
    final repository = _FakeOrdersRepository()
      ..checkoutResult = const ApiError(ApiFailure(message: 'السلة فارغة'));
    final sessionRepository = InMemorySessionRepository()
      ..savedSession = const UserSession(accountType: AccountType.patient, token: 'tok-1');
    final useCase = CheckoutUseCase(repository, sessionRepository);

    final result = await useCase(addressId: 1);

    expect(result, isA<ApiError<int>>());
  });

  test('hands the quote and the idempotency key to the repository', () async {
    const quote = CheckoutQuote(
      subtotal: 80,
      discount: 0,
      total: 80,
      deliveryFee: 9,
      grandTotal: 89,
    );
    final repository = _FakeOrdersRepository();
    final sessionRepository = InMemorySessionRepository()
      ..savedSession = const UserSession(accountType: AccountType.patient, token: 'tok-1');
    final useCase = CheckoutUseCase(repository, sessionRepository);

    await useCase(addressId: 1, quote: quote, idempotencyKey: 'key-1');

    expect(repository.lastQuote, same(quote));
    expect(repository.lastIdempotencyKey, 'key-1');
  });

  test('sends no quote and no key when none is given', () async {
    final repository = _FakeOrdersRepository();
    final sessionRepository = InMemorySessionRepository()
      ..savedSession = const UserSession(accountType: AccountType.patient, token: 'tok-1');
    final useCase = CheckoutUseCase(repository, sessionRepository);

    await useCase(addressId: 1);

    expect(repository.lastQuote, isNull);
    expect(repository.lastIdempotencyKey, isNull);
  });
}
