import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../entities/checkout_quote.dart';
import '../repositories/orders_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class CheckoutUseCase {
  final OrdersRepository _repository;
  final SessionRepository _sessionRepository;

  const CheckoutUseCase(this._repository, this._sessionRepository);

  /// Creates the order. Give the [quote] the patient saw and an
  /// [idempotencyKey] that stays the same for every retry of this one order:
  /// the server then refuses (409) an order whose price has moved, and never
  /// makes two orders from a repeated tap or a retried request.
  Future<ApiResult<int>> call({
    required int addressId,
    String? couponCode,
    String? notes,
    CheckoutQuote? quote,
    String? idempotencyKey,
  }) {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.checkout(
        token: token,
        addressId: addressId,
        couponCode: couponCode,
        notes: notes,
        quote: quote,
        idempotencyKey: idempotencyKey,
      ),
    );
  }
}
