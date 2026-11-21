import 'package:daway_app/core/helpers/api_result.dart';
import 'package:daway_app/features/auth/domain/entities/account_type.dart';
import 'package:daway_app/features/auth/domain/entities/user_session.dart';
import 'package:daway_app/features/patient/domain/entities/checkout_quote.dart';
import 'package:daway_app/features/patient/domain/usecases/get_checkout_quote_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../checkout_test_fakes.dart';

void main() {
  const quote = CheckoutQuote(
    subtotal: 80,
    discount: 0,
    total: 80,
    deliveryFee: 9,
    grandTotal: 89,
  );

  test('asks for the quote with the session token, address and coupon', () async {
    final repository = FakeOrdersRepository()..quoteResult = const Success(quote);
    final session = FakeSessionRepository()
      ..savedSession = const UserSession(accountType: AccountType.patient, token: 'tok-1');

    final result = await GetCheckoutQuoteUseCase(repository, session)(
      addressId: 3,
      couponCode: 'SAVE10',
    );

    expect((result as Success<CheckoutQuote>).data, same(quote));
    expect(repository.lastQuoteCouponCode, 'SAVE10');
    expect(repository.quoteCallCount, 1);
  });

  test('is a session failure, without calling the repository, when logged out', () async {
    final repository = FakeOrdersRepository();

    final loggedOut = FakeSessionRepository()..savedSession = null;

    final result = await GetCheckoutQuoteUseCase(repository, loggedOut)(addressId: 3);

    expect(result, isA<ApiError<CheckoutQuote>>());
    expect(repository.quoteCallCount, 0);
  });
}
