import '../../domain/entities/checkout_flow.dart';

sealed class PaymentState {
  const PaymentState();
}

class PaymentLoading extends PaymentState {
  const PaymentLoading();
}

class PaymentLoadFailure extends PaymentState {
  final String message;

  const PaymentLoadFailure(this.message);
}

class PaymentReady extends PaymentState {
  final OrderPayment payment;
  final int? selectedBankId;
  final bool isSubmitting;

  /// The admin has not yet priced the delivery / approved the order, so the
  /// patient cannot pay: the screen waits instead of listing the banks.
  final bool awaitingAdmin;

  const PaymentReady({
    required this.payment,
    this.selectedBankId,
    this.isSubmitting = false,
    this.awaitingAdmin = false,
  });

  PaymentBank? get selectedBank {
    for (final bank in payment.banks) {
      if (bank.id == selectedBankId) return bank;
    }
    return null;
  }

  PaymentReady copyWith({int? selectedBankId, bool? isSubmitting}) {
    return PaymentReady(
      payment: payment,
      selectedBankId: selectedBankId ?? this.selectedBankId,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      awaitingAdmin: awaitingAdmin,
    );
  }
}
