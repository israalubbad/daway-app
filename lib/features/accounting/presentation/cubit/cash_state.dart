import '../../domain/entities/cash_ledger.dart';
import 'sales_state.dart';

/// The movement kinds the cash filter offers. Deposits and withdrawals made by
/// hand are "تسويات".
enum CashTypeFilter { all, sales, expenses, payments, adjustments }

extension CashTypeFilterX on CashTypeFilter {
  bool matches(CashMovementType type) => switch (this) {
    CashTypeFilter.all => true,
    CashTypeFilter.sales => type == CashMovementType.sale,
    CashTypeFilter.expenses => type == CashMovementType.expense,
    CashTypeFilter.payments => type == CashMovementType.payment,
    CashTypeFilter.adjustments =>
      type == CashMovementType.deposit || type == CashMovementType.withdrawal,
  };
}

sealed class CashState {
  const CashState();
}

class CashLoading extends CashState {
  const CashLoading();
}

class CashLoadFailure extends CashState {
  final String message;

  const CashLoadFailure(this.message);
}

class CashLoaded extends CashState {
  final CashLedger ledger;
  final CashTypeFilter type;
  final DateRangeFilter range;

  const CashLoaded({
    required this.ledger,
    this.type = CashTypeFilter.all,
    this.range = DateRangeFilter.all,
  });

  int get activeFilters =>
      (type != CashTypeFilter.all ? 1 : 0) + (range != DateRangeFilter.all ? 1 : 0);

  List<CashMovement> get visible {
    final now = DateTime.now();
    return [
      for (final movement in ledger.movements)
        if (type.matches(movement.type) && range.contains(movement.date, now)) movement,
    ];
  }

  CashLoaded copyWith({CashLedger? ledger, CashTypeFilter? type, DateRangeFilter? range}) =>
      CashLoaded(
        ledger: ledger ?? this.ledger,
        type: type ?? this.type,
        range: range ?? this.range,
      );
}
