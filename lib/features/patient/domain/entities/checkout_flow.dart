import 'order.dart';

/// A bank / wallet the patient can transfer the order's total to, as the
/// backend lists it (`GET /patient/orders/{id}/payment` → `banks`).
class PaymentBank {
  final int id;
  final String name;
  final String accountNumber;

  const PaymentBank({
    required this.id,
    required this.name,
    required this.accountNumber,
  });
}

/// What the patient owes for an order and where to pay it. Every amount comes
/// from the server — the app never works out the total or the delivery fee.
const _unapprovedStatuses = {'', 'pending', 'under_review', 'problem_reported', 'rejected'};

class OrderPayment {
  final int orderId;
  final double grandTotal;
  final double? deliveryFee;
  final double? discount;
  final String paymentStatus;

  /// False while a receipt is already under review (or the order is paid).
  final bool canSubmitReceipt;

  /// The server sent a delivery fee field but left it empty: the admin has
  /// not priced the delivery yet, so there is nothing to pay.
  final bool awaitingDeliveryFee;
  final List<PaymentBank> banks;

  const OrderPayment({
    required this.orderId,
    required this.grandTotal,
    this.deliveryFee,
    this.discount,
    required this.paymentStatus,
    required this.canSubmitReceipt,
    this.awaitingDeliveryFee = false,
    required this.banks,
  });

  /// The admin has approved the transfer (any status other than the ones in
  /// which it is still waiting or was refused).
  bool get isApproved => !_unapprovedStatuses.contains(paymentStatus);

  OrderPayment withBanks(List<PaymentBank> banks) => OrderPayment(
    orderId: orderId,
    grandTotal: grandTotal,
    deliveryFee: deliveryFee,
    discount: discount,
    paymentStatus: paymentStatus,
    canSubmitReceipt: canSubmitReceipt,
    awaitingDeliveryFee: awaitingDeliveryFee,
    banks: banks,
  );
}

/// One step of an order's history (`GET /patient/orders/{id}/tracking`).
class OrderTrackingEvent {
  final OrderStatus status;
  final DateTime? at;

  const OrderTrackingEvent({required this.status, this.at});
}

class OrderTracking {
  final OrderStatus status;

  /// Oldest first.
  final List<OrderTrackingEvent> history;

  const OrderTracking({required this.status, required this.history});

  /// When the order reached [step], or null if it has not (or the server did
  /// not say).
  DateTime? timeOf(OrderStatus step) {
    for (final event in history) {
      if (event.status == step) return event.at;
    }
    return null;
  }
}
