import 'dart:io';

import '../../../../core/erroring/error_handler.dart';
import '../../../../core/helpers/api_result.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_remote_data_source.dart';
import '../models/payment_models.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource _remoteDataSource;

  const PaymentRepositoryImpl(this._remoteDataSource);

  @override
  Future<ApiResult<List<PaymentBank>>> getBanks({required String token}) async {
    try {
      final response = await _remoteDataSource.getBanks(token: token);
      final body = response.data as Map<String, dynamic>;
      return Success(parsePaymentBanks(body['data']));
    } catch (e) {
      return ApiError(mapExceptionToFailure(e));
    }
  }

  @override
  Future<ApiResult<PaymentSummary>> getPayment({
    required String token,
    required int orderId,
  }) async {
    try {
      final response = await _remoteDataSource.getPayment(token: token, orderId: orderId);
      final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return Success(parsePaymentSummary(data));
    } catch (e) {
      return ApiError(mapExceptionToFailure(e));
    }
  }

  @override
  Future<ApiResult<void>> submitReceipt({
    required String token,
    required int orderId,
    required int bankId,
    required double amount,
    required String senderName,
    required String transferReference,
    required File receipt,
  }) async {
    try {
      await _remoteDataSource.submitReceipt(
        token: token,
        orderId: orderId,
        bankId: bankId,
        amount: amount,
        senderName: senderName,
        transferReference: transferReference,
        receipt: receipt,
      );
      return const Success(null);
    } catch (e) {
      return ApiError(mapExceptionToFailure(e));
    }
  }

  @override
  Future<ApiResult<void>> reportProblem({
    required String token,
    required int orderId,
    required String message,
    required int submissionId,
    String category = 'other',
  }) async {
    try {
      await _remoteDataSource.reportProblem(
        token: token,
        orderId: orderId,
        category: category,
        message: message,
        submissionId: submissionId,
      );
      return const Success(null);
    } catch (e) {
      return ApiError(mapExceptionToFailure(e));
    }
  }

  @override
  Future<ApiResult<double>> validateCoupon({
    required String token,
    required String code,
    required double orderTotal,
  }) async {
    try {
      final response = await _remoteDataSource.validateCoupon(
        token: token,
        code: code,
        orderTotal: orderTotal,
      );
      final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
      final discount = data?['discount'];
      final value = discount is num ? discount.toDouble() : double.tryParse('$discount');
      if (value == null) {
        throw const FormatException('POST /patient/coupons/validate response is missing discount');
      }
      return Success(value);
    } catch (e) {
      return ApiError(mapExceptionToFailure(e));
    }
  }

  @override
  Future<ApiResult<OrderTracking>> getTracking({
    required String token,
    required int orderId,
  }) async {
    try {
      final response = await _remoteDataSource.getTracking(token: token, orderId: orderId);
      final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return Success(parseOrderTracking(data));
    } catch (e) {
      return ApiError(mapExceptionToFailure(e));
    }
  }
}
