import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/helpers/api_result.dart';
import '../../domain/entities/accounting_overview.dart';
import '../../domain/usecases/accounting_usecases.dart';
import 'accounting_load_state.dart';

class AccountingOverviewCubit extends Cubit<AccountingLoad<AccountingOverview>> {
  final GetAccountingOverviewUseCase _getOverview;

  SalesPeriod _period = SalesPeriod.last7Days;

  AccountingOverviewCubit(this._getOverview) : super(const AccountingLoading()) {
    load();
  }

  Future<void> load() async {
    emit(const AccountingLoading());
    await _fetch(_period);
  }

  /// Fetches again keeping what is on screen until the new figures arrive, and
  /// keeping it if the fetch fails.
  Future<void> refresh() => _fetch(_period);

  /// Shows [period]'s chart. If its fetch fails the previous period stays, so
  /// the selected button always matches the figures under it.
  Future<void> periodChanged(SalesPeriod period) async {
    final previous = _period;
    _period = period;
    final loaded = await _fetch(period);
    if (!loaded && _period == period) _period = previous;
  }

  /// True when [requested]'s figures were fetched and shown.
  Future<bool> _fetch(SalesPeriod requested) async {
    final result = await _getOverview(requested);
    if (isClosed || requested != _period) return false;
    switch (result) {
      case Success(:final data):
        emit(AccountingLoaded(data));
        return true;
      case ApiError(:final failure):
        if (state is! AccountingLoaded<AccountingOverview>) {
          emit(AccountingLoadFailure(failure.message));
        }
        return false;
    }
  }
}
