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
    await _fetch();
  }

  /// Fetches again keeping what is on screen until the new figures arrive.
  Future<void> refresh() => _fetch();

  Future<void> periodChanged(SalesPeriod period) {
    _period = period;
    return _fetch();
  }

  Future<void> _fetch() async {
    final requested = _period;
    final result = await _getOverview(requested);
    if (isClosed || requested != _period) return;
    switch (result) {
      case Success(:final data):
        emit(AccountingLoaded(data));
      case ApiError(:final failure):
        emit(AccountingLoadFailure(failure.message));
    }
  }
}
