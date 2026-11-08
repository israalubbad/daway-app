/// What a cash movement is for. Deposits and withdrawals are the two a pharmacy
/// records by hand; the others come from invoices and expenses.
enum CashMovementType { sale, expense, payment, deposit, withdrawal }

/// One entry of the cash book.
class CashMovement {
  final int id;
  final CashMovementType type;
  final String description;
  final DateTime date;

  /// Positive for money in, negative for money out.
  final double amount;

  const CashMovement({
    required this.id,
    required this.type,
    required this.description,
    required this.date,
    required this.amount,
  });

  bool get isIncoming => amount >= 0;
}

/// The cash book: its movements, newest first, and the balance they add up to.
class CashLedger {
  final double balance;

  /// Under this, the screen warns that the cash is low.
  final double safeLimit;
  final List<CashMovement> movements;

  const CashLedger({
    required this.balance,
    required this.safeLimit,
    required this.movements,
  });

  bool get isLow => balance < safeLimit;
}
