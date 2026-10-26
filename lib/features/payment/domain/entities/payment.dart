class PaymentBank {
  final int id;
  final String name;
  final String? accountHolder;
  final String? accountNumber;
  final String? iban;
  final String? notes;
  final String? logoUrl;

  const PaymentBank({
    required this.id,
    required this.name,
    this.accountHolder,
    this.accountNumber,
    this.iban,
    this.notes,
    this.logoUrl,
  });
}

/// `GET /patient/orders/{id}/payment`. [grandTotal] and [deliveryFee] come
/// from the server — the final amount is never computed in the app.
class PaymentSummary {
  /// 'pending', 'under_review', 'problem_reported', ... (kept as sent).
  final String status;
  final bool canSubmitReceipt;
  final List<PaymentBank> banks;
  final double? grandTotal;
  final double? deliveryFee;
  final int? latestSubmissionId;

  const PaymentSummary({
    required this.status,
    required this.canSubmitReceipt,
    this.banks = const [],
    this.grandTotal,
    this.deliveryFee,
    this.latestSubmissionId,
  });
}

/// One step of an order's timeline, with the status as the server sent it.
class TrackingStep {
  final String status;
  final DateTime? at;

  const TrackingStep({required this.status, this.at});
}

class OrderTracking {
  final String status;
  final List<TrackingStep> steps;

  const OrderTracking({required this.status, this.steps = const []});
}
