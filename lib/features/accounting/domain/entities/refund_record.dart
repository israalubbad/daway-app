enum RefundStatus { completed, pending }

/// A sales return, as the refunds list shows it.
class RefundRecord {
  final int id;

  /// "RET-3001".
  final String number;

  /// The invoice it returns goods from ("INV-1002").
  final String invoiceNumber;
  final DateTime date;
  final String? customerName;
  final double amount;
  final RefundStatus status;

  const RefundRecord({
    required this.id,
    required this.number,
    required this.invoiceNumber,
    required this.date,
    this.customerName,
    required this.amount,
    required this.status,
  });
}
