import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/helpers/api_result.dart';
import '../../domain/entities/payment.dart';
import '../../domain/usecases/payment_usecases.dart';

class PaymentState {
  final bool isLoading;
  final String? loadError;
  final PaymentSummary? summary;
  final bool isBusy;

  /// A one-off message for a snackbar (success or failure of an action);
  /// [messageId] changes on every new one so listeners can tell them apart.
  final String? message;
  final int messageId;

  const PaymentState({
    this.isLoading = true,
    this.loadError,
    this.summary,
    this.isBusy = false,
    this.message,
    this.messageId = 0,
  });

  PaymentState copyWith({
    bool? isLoading,
    String? loadError,
    PaymentSummary? summary,
    bool? isBusy,
    String? message,
    bool clearLoadError = false,
  }) {
    return PaymentState(
      isLoading: isLoading ?? this.isLoading,
      loadError: clearLoadError ? null : (loadError ?? this.loadError),
      summary: summary ?? this.summary,
      isBusy: isBusy ?? this.isBusy,
      message: message ?? this.message,
      messageId: message == null ? messageId : messageId + 1,
    );
  }
}

/// Payment instructions for one order: the amount and banks to transfer to,
/// the receipt upload ("تم التأكيد") and the payment problem report.
class PaymentCubit extends Cubit<PaymentState> {
  static const receiptSentMessage = 'تم إرسال الإشعار للمراجعة';
  static const problemSentMessage = 'تم إرسال البلاغ';

  final int orderId;
  final GetPaymentUseCase _getPaymentUseCase;
  final SubmitPaymentReceiptUseCase _submitReceiptUseCase;
  final ReportPaymentProblemUseCase _reportProblemUseCase;

  PaymentCubit(
    this.orderId,
    this._getPaymentUseCase,
    this._submitReceiptUseCase,
    this._reportProblemUseCase,
  ) : super(const PaymentState());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, clearLoadError: true));
    final result = await _getPaymentUseCase(orderId);
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(state.copyWith(isLoading: false, summary: data));
      case ApiError(:final failure):
        emit(state.copyWith(isLoading: false, loadError: failure.message));
    }
  }

  /// Sends the transfer receipt. The server only moves the payment to
  /// "under review" — reloaded here so the screen shows that status.
  Future<void> submitReceipt({
    required int bankId,
    required double amount,
    required String senderName,
    required String transferReference,
    required File receipt,
  }) async {
    if (state.isBusy) return;
    emit(state.copyWith(isBusy: true));
    final result = await _submitReceiptUseCase(
      orderId: orderId,
      bankId: bankId,
      amount: amount,
      senderName: senderName,
      transferReference: transferReference,
      receipt: receipt,
    );
    if (isClosed) return;
    switch (result) {
      case Success():
        emit(state.copyWith(isBusy: false, message: receiptSentMessage));
        await load();
      case ApiError(:final failure):
        emit(state.copyWith(isBusy: false, message: failure.message));
    }
  }

  Future<void> reportProblem(String message) async {
    final submissionId = state.summary?.latestSubmissionId;
    final text = message.trim();
    if (state.isBusy || submissionId == null || text.isEmpty) return;
    emit(state.copyWith(isBusy: true));
    final result = await _reportProblemUseCase(
      orderId: orderId,
      message: text,
      submissionId: submissionId,
    );
    if (isClosed) return;
    switch (result) {
      case Success():
        emit(state.copyWith(isBusy: false, message: problemSentMessage));
        await load();
      case ApiError(:final failure):
        emit(state.copyWith(isBusy: false, message: failure.message));
    }
  }
}
