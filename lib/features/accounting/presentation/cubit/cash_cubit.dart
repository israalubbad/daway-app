import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/helpers/api_result.dart';
import '../../domain/usecases/accounting_usecases.dart';
import 'cash_state.dart';
import 'sales_state.dart';

class CashCubit extends Cubit<CashState> {
  final GetCashLedgerUseCase _getLedger;
  final RecordCashMovementUseCase _recordMovement;

  CashCubit(this._getLedger, this._recordMovement) : super(const CashLoading()) {
    load();
  }

  Future<void> load() async {
    emit(const CashLoading());
    await refresh();
  }

  Future<void> refresh() async {
    final result = await _getLedger();
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        final current = state;
        emit(current is CashLoaded ? current.copyWith(ledger: data) : CashLoaded(ledger: data));
      case ApiError(:final failure):
        // A failed refresh (also after a saved movement) leaves the ledger
        // that is already on screen instead of an error view over a saved entry.
        if (state is! CashLoaded) emit(CashLoadFailure(failure.message));
    }
  }

  void filtersApplied({required CashTypeFilter type, required DateRangeFilter range}) {
    final current = state;
    if (current is CashLoaded) emit(current.copyWith(type: type, range: range));
  }

  /// Records a deposit or a withdrawal; returns the message to show when it
  /// fails, or null once it is saved (the balance and list are refreshed).
  Future<String?> record({
    required bool isDeposit,
    required double amount,
    required String reason,
  }) async {
    final result = await _recordMovement(isDeposit: isDeposit, amount: amount, reason: reason);
    switch (result) {
      case Success():
        await refresh();
        return null;
      case ApiError(:final failure):
        return failure.message;
    }
  }
}
