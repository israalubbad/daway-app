import '../../../../core/erroring/failure.dart';
import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../entities/checkout_flow.dart';
import '../repositories/checkout_flow_repository.dart';

ApiFailure get _sessionExpired => ApiFailure(message: sessionExpiredMessage);

class ValidateCouponUseCase {
  final CheckoutFlowRepository _repository;
  final SessionRepository _sessionRepository;

  const ValidateCouponUseCase(this._repository, this._sessionRepository);

  /// The discount [code] gives on [orderTotal].
  Future<ApiResult<double>> call({
    required String code,
    required double orderTotal,
  }) async {
    final session = await _sessionRepository.getSession();
    if (session == null) return ApiError(_sessionExpired);
    return _repository.validateCoupon(
      token: session.token,
      code: code.trim(),
      orderTotal: orderTotal,
    );
  }
}

class GetOrderPaymentUseCase {
  final CheckoutFlowRepository _repository;
  final SessionRepository _sessionRepository;

  const GetOrderPaymentUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<OrderPayment>> call(int orderId) async {
    final session = await _sessionRepository.getSession();
    if (session == null) return ApiError(_sessionExpired);
    return _repository.getPayment(token: session.token, orderId: orderId);
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
  }) async {
    final session = await _sessionRepository.getSession();
    if (session == null) return ApiError(_sessionExpired);
    return _repository.submitReceipt(
      token: session.token,
      orderId: orderId,
      bankId: bankId,
      amount: amount,
      receiptPath: receiptPath,
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
  }) async {
    final session = await _sessionRepository.getSession();
    if (session == null) return ApiError(_sessionExpired);
    return _repository.reportProblem(
      token: session.token,
      orderId: orderId,
      message: message,
    );
  }
}

class GetOrderTrackingUseCase {
  final CheckoutFlowRepository _repository;
  final SessionRepository _sessionRepository;

  const GetOrderTrackingUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<OrderTracking>> call(int orderId) async {
    final session = await _sessionRepository.getSession();
    if (session == null) return ApiError(_sessionExpired);
    return _repository.getTracking(token: session.token, orderId: orderId);
  }
}
