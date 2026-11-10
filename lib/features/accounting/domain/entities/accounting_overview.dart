/// How an invoice has been paid so far.
enum PaymentStatus { paid, partial, unpaid, refunded, cancelled }

/// How money was handed over.
enum PaymentMethod { cash, bankTransfer, card, credit }

/// The range the overview's sales chart covers.
enum SalesPeriod { today, last7Days, last30Days, thisMonth }

/// One point of the sales chart: the day's label ("1", "2", ...) and its sales.
class SalesPoint {
  final String label;
  final double amount;

  const SalesPoint({required this.label, required this.amount});
}

/// One slice of the expenses donut.
class ExpenseSlice {
  final String category;
  final double amount;

  const ExpenseSlice({required this.category, required this.amount});
}

enum AccountingAlertKind { overdueDebt, lowCash, lowStock }

/// An item of "أمور تحتاج انتباهك".
class AccountingAlert {
  final AccountingAlertKind kind;
  final String title;
  final String message;

  const AccountingAlert({required this.kind, required this.title, required this.message});
}

/// One row of "آخر الحركات".
class AccountingTransaction {
  /// "INV-1002".
  final String reference;
  final String description;
  final double amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final DateTime date;

  const AccountingTransaction({
    required this.reference,
    required this.description,
    required this.amount,
    required this.method,
    required this.status,
    required this.date,
  });
}

/// Everything the accounting overview screen shows, in shekels.
class AccountingOverview {
  final double todaySales;
  final double todayPurchases;
  final double todayExpenses;
  final double todayProfit;
  final double cashBalance;
  final double outstandingDebts;
  final SalesPeriod period;
  final List<SalesPoint> salesTrend;
  final List<ExpenseSlice> expenses;
  final List<AccountingAlert> alerts;
  final List<AccountingTransaction> recentTransactions;

  const AccountingOverview({
    required this.todaySales,
    required this.todayPurchases,
    required this.todayExpenses,
    required this.todayProfit,
    required this.cashBalance,
    required this.outstandingDebts,
    required this.period,
    required this.salesTrend,
    required this.expenses,
    required this.alerts,
    required this.recentTransactions,
  });
}
