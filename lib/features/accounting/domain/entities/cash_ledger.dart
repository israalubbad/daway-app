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

/// What a hand-recorded cash movement must satisfy. One place for the rules, so
/// the form and the use case cannot disagree.
abstract class CashMovementRules {
  static bool isValidAmount(double amount) => amount > 0;

  static bool isValidReason(String reason) => reason.trim().isNotEmpty;

  static bool isValid({required double amount, required String reason}) =>
      isValidAmount(amount) && isValidReason(reason);

  /// A withdrawal of more than the cash balance is allowed but worth a warning.
  static bool exceedsBalance({
    required bool isDeposit,
    required double amount,
    required double balance,
  }) => !isDeposit && amount > balance;
}
