import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../entities/checkout_flow.dart';
import '../repositories/checkout_flow_repository.dart';
import '../../../auth/domain/usecases/with_session_token.dart';

class ValidateCouponUseCase {
  final CheckoutFlowRepository _repository;
  final SessionRepository _sessionRepository;

  const ValidateCouponUseCase(this._repository, this._sessionRepository);

  /// The discount [code] gives on [orderTotal].
  Future<ApiResult<double>> call({
    required String code,
    required double orderTotal,
  }) {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.validateCoupon(
        token: token,
        code: code.trim(),
        orderTotal: orderTotal,
      ),
    );
  }
}

class GetOrderPaymentUseCase {
  final CheckoutFlowRepository _repository;
  final SessionRepository _sessionRepository;

  const GetOrderPaymentUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<OrderPayment>> call(int orderId) {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.getPayment(token: token, orderId: orderId),
    );
  }
}

class SubmitPaymentReceiptUseCase {
  final CheckoutFlowRepository _repository;
  final SessionRepository _sessionRepository;

  const SubmitPaymentReceiptUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<void>> call({
    required int orderId,
    required int bankId,
    required double amount,
    required String receiptPath,
  }) {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.submitReceipt(
        token: token,
        orderId: orderId,
        bankId: bankId,
        amount: amount,
        receiptPath: receiptPath,
      ),
    );
  }
}

class ReportPaymentProblemUseCase {
  final CheckoutFlowRepository _repository;
  final SessionRepository _sessionRepository;

  const ReportPaymentProblemUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<void>> call({
    required int orderId,
    required String message,
  }) {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.reportProblem(
        token: token,
        orderId: orderId,
        message: message,
      ),
    );
  }
}

class GetOrderTrackingUseCase {
  final CheckoutFlowRepository _repository;
  final SessionRepository _sessionRepository;

  const GetOrderTrackingUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<OrderTracking>> call(int orderId) {
    return withSessionToken(
      _sessionRepository,
      (token) => _repository.getTracking(token: token, orderId: orderId),
    );
  }
}
