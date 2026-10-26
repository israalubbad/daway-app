import 'dart:io';

import '../../../../core/erroring/failure.dart';
import '../../../../core/helpers/api_result.dart';
import '../../../auth/domain/repositories/session_repository.dart';
import '../entities/payment.dart';
import '../repositories/payment_repository.dart';

const _sessionExpired = ApiFailure(message: 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مرة أخرى');

class GetPaymentUseCase {
  final PaymentRepository _repository;
  final SessionRepository _sessionRepository;

  const GetPaymentUseCase(this._repository, this._sessionRepository);

  /// The order's payment summary, with the bank list filled from
  /// `/patient/payment-banks` when the summary carries none of its own.
  Future<ApiResult<PaymentSummary>> call(int orderId) async {
    final session = await _sessionRepository.getSession();
    if (session == null) return const ApiError(_sessionExpired);

    final result = await _repository.getPayment(token: session.token, orderId: orderId);
    if (result is! Success<PaymentSummary> || result.data.banks.isNotEmpty) return result;

    final summary = result.data;
    final banks = await _repository.getBanks(token: session.token);
    if (banks is! Success<List<PaymentBank>>) return result;
    return Success(
      PaymentSummary(
        status: summary.status,
        canSubmitReceipt: summary.canSubmitReceipt,
        banks: banks.data,
        grandTotal: summary.grandTotal,
        deliveryFee: summary.deliveryFee,
        latestSubmissionId: summary.latestSubmissionId,
      ),
    );
  }
}

class SubmitPaymentReceiptUseCase {
  final PaymentRepository _repository;
  final SessionRepository _sessionRepository;

  const SubmitPaymentReceiptUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<void>> call({
    required int orderId,
    required int bankId,
    required double amount,
    required String senderName,
    required String transferReference,
    File? receipt,
  }) async {
    final session = await _sessionRepository.getSession();
    if (session == null) return const ApiError(_sessionExpired);
    return _repository.submitReceipt(
      token: session.token,
      orderId: orderId,
      bankId: bankId,
      amount: amount,
      senderName: senderName,
      transferReference: transferReference,
      receipt: receipt,
    );
  }
}

class ReportPaymentProblemUseCase {
  final PaymentRepository _repository;
  final SessionRepository _sessionRepository;

  const ReportPaymentProblemUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<void>> call({
    required int orderId,
    required String message,
    required int submissionId,
  }) async {
    final session = await _sessionRepository.getSession();
    if (session == null) return const ApiError(_sessionExpired);
    return _repository.reportProblem(
      token: session.token,
      orderId: orderId,
      message: message,
      submissionId: submissionId,
    );
  }
}

class ValidateCouponUseCase {
  final PaymentRepository _repository;
  final SessionRepository _sessionRepository;

  const ValidateCouponUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<double>> call({required String code, required double orderTotal}) async {
    final session = await _sessionRepository.getSession();
    if (session == null) return const ApiError(_sessionExpired);
    return _repository.validateCoupon(token: session.token, code: code, orderTotal: orderTotal);
  }
}

class GetOrderTrackingUseCase {
  final PaymentRepository _repository;
  final SessionRepository _sessionRepository;

  const GetOrderTrackingUseCase(this._repository, this._sessionRepository);

  Future<ApiResult<OrderTracking>> call(int orderId) async {
    final session = await _sessionRepository.getSession();
    if (session == null) return const ApiError(_sessionExpired);
    return _repository.getTracking(token: session.token, orderId: orderId);
  }
}
