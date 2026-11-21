import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';
import '../entities/checkout_quote.dart';
import '../repositories/orders_repository.dart';

/// Prices the cart delivered to an address, with the coupon applied, without
/// creating anything.
class GetCheckoutQuoteUseCase {
  final OrdersRepository _repository;
  final SessionRepository _sessionRepository;

  const GetCheckoutQuoteUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<CheckoutQuote>> call({required int addressId, String? couponCode}) =>
      withSessionToken(
        _sessionRepository,
        (token) => _repository.getCheckoutQuote(
          token: token,
          addressId: addressId,
          couponCode: couponCode,
        ),
      );
}
