import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/helpers/api_result.dart';
import '../../../../core/helpers/price_formatter.dart';
import '../../domain/entities/order.dart';
import '../../domain/usecases/checkout_flow_usecases.dart';
import 'payment_state.dart';

import '../../../../core/localization/translations.dart';

/// The payment of one order, across "طريقة الدفع" and "ارفع اشعار التحويل".
class PaymentCubit extends Cubit<PaymentState> {
  final int orderId;
  final GetOrderPaymentUseCase _getPaymentUseCase;
  final SubmitPaymentReceiptUseCase _submitReceiptUseCase;
  final ReportPaymentProblemUseCase _reportProblemUseCase;
  final GetOrderTrackingUseCase _getTrackingUseCase;

  static const pollInterval = Duration(seconds: 10);
  Timer? _poll;

  PaymentCubit(
    this.orderId,
    this._getPaymentUseCase,
    this._submitReceiptUseCase,
    this._reportProblemUseCase,
    this._getTrackingUseCase,
  ) : super(const PaymentLoading()) {
    load();
  }

  Future<void> load() async {
    emit(const PaymentLoading());
    await _fetch();
  }

  /// While the admin has not priced the delivery / approved the order, checks
  /// again every [pollInterval] so the payment opens up by itself.
  void startPolling() {
    _poll ??= Timer.periodic(pollInterval, (_) => refresh());
  }

  void stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  /// Silent reload for the waiting screen: errors are ignored, the next tick
  /// retries.
  Future<void> refresh() async {
    final current = state;
    if (current is! PaymentReady ||
        !current.awaitingAdmin ||
        current.isSubmitting) {
      return;
    }
    await _fetch(silent: true);
  }

  Future<void> _fetch({bool silent = false}) async {
    final result = await _getPaymentUseCase(orderId);
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        // An order still "pending" has not been approved by the admin yet.
        // The tracking only decides that: if it cannot be read, the payment's
        // own delivery fee field is all there is to go on.
        final tracking = await _getTrackingUseCase(orderId);
        if (isClosed) return;
        final pending = switch (tracking) {
          Success(:final data) => data.status == OrderStatus.pending,
          ApiError() => false,
        };
        // Once the transfer is approved there is nothing left to wait for.
        final awaiting = !data.isApproved && (data.awaitingDeliveryFee || pending);
        if (!awaiting) stopPolling();
        emit(
          PaymentReady(
            payment: data,
            selectedBankId: data.banks.isEmpty ? null : data.banks.first.id,
            awaitingAdmin: awaiting,
          ),
        );
      case ApiError(:final failure):
        if (!silent) emit(PaymentLoadFailure(failure.message));
    }
  }

  void selectBank(int bankId) {
    final current = state;
    if (current is! PaymentReady) return;
    emit(current.copyWith(selectedBankId: bankId));
  }

  /// Sends the transfer receipt picture for the chosen bank. Returns null on
  /// success, or a user-facing error message.
  Future<String?> submitReceipt(String receiptPath) async {
    final current = state;
    if (current is! PaymentReady || current.isSubmitting) return null;
    final bank = current.selectedBank;
    if (bank == null) return 'اختر طريقة الدفع أولاً'.tr;

    return _run(
      current,
      () => _submitReceiptUseCase(
        orderId: orderId,
        bankId: bank.id,
        amount: current.payment.grandTotal,
        receiptPath: receiptPath,
      ),
    );
  }

  /// For a patient who cannot upload the picture: hands the transfer details
  /// over as a payment problem report for the admin to check. Returns null on
  /// success, or a user-facing error message.
  Future<String?> reportTransferDetails({
    required String bankName,
    required String accountHolder,
    required double amount,
  }) async {
    final current = state;
    if (current is! PaymentReady || current.isSubmitting) return null;

    final message =
        'تعذر رفع إشعار التحويل. بيانات التحويل: البنك: {0}، صاحب الحساب: {1}، المبلغ: {2}'.trArgs([bankName, accountHolder, formatPrice(amount)]);
    return _run(
      current,
      () => _reportProblemUseCase(orderId: orderId, message: message),
    );
  }

  Future<String?> _run(
    PaymentReady current,
    Future<ApiResult<void>> Function() action,
  ) async {
    emit(current.copyWith(isSubmitting: true));
    final result = await action();
    if (isClosed) return null;
    final latest = state;
    if (latest is PaymentReady) emit(latest.copyWith(isSubmitting: false));
    return switch (result) {
      Success() => null,
      ApiError(:final failure) => failure.message,
    };
  }

  @override
  Future<void> close() {
    stopPolling();
    return super.close();
  }
}
