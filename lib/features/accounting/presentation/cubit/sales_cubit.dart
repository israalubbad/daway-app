import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/helpers/api_result.dart';
import '../../domain/entities/accounting_overview.dart';
import '../../domain/usecases/accounting_usecases.dart';
import 'sales_state.dart';

class SalesCubit extends Cubit<SalesState> {
  final GetSalesUseCase _getSales;

  SalesCubit(this._getSales) : super(const SalesLoading()) {
    load();
  }

  Future<void> load() async {
    emit(const SalesLoading());
    await refresh();
  }

  Future<void> refresh() async {
    final result = await _getSales();
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        final current = state;
        emit(current is SalesLoaded ? current.copyWith(all: data) : SalesLoaded(all: data));
      case ApiError(:final failure):
        // A failed refresh leaves the list that is already on screen.
        if (state is! SalesLoaded) emit(SalesLoadFailure(failure.message));
    }
  }

  void queryChanged(String query) {
    final current = state;
    if (current is SalesLoaded) emit(current.copyWith(query: query));
  }

  /// Applies the filters sheet's choices at once; a null [method] or [status]
  /// means "الكل".
  void filtersApplied({
    required DateRangeFilter range,
    PaymentMethod? method,
    PaymentStatus? status,
  }) {
    final current = state;
    if (current is! SalesLoaded) return;
    emit(
      current.copyWith(
        range: range,
        method: method,
        status: status,
        clearMethod: method == null,
        clearStatus: status == null,
      ),
    );
  }
}
