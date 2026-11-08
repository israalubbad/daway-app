import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/helpers/api_result.dart';
import '../../domain/entities/refund_record.dart';
import '../../domain/usecases/accounting_usecases.dart';
import 'refunds_state.dart';

class RefundsCubit extends Cubit<RefundsState> {
  final GetRefundsUseCase _getRefunds;

  RefundsCubit(this._getRefunds) : super(const RefundsLoading()) {
    load();
  }

  Future<void> load() async {
    emit(const RefundsLoading());
    await refresh();
  }

  Future<void> refresh() async {
    final result = await _getRefunds();
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        final current = state;
        emit(current is RefundsLoaded ? current.copyWith(all: data) : RefundsLoaded(all: data));
      case ApiError(:final failure):
        emit(RefundsLoadFailure(failure.message));
    }
  }

  void queryChanged(String query) {
    final current = state;
    if (current is RefundsLoaded) emit(current.copyWith(query: query));
  }

  void statusChanged(RefundStatus? status) {
    final current = state;
    if (current is RefundsLoaded) {
      emit(current.copyWith(status: status, clearStatus: status == null));
    }
  }
}
