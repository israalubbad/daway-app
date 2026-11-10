import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/helpers/api_result.dart';
import '../../domain/entities/pharmacy_order.dart';
import '../../domain/usecases/decide_pharmacy_order_usecase.dart';
import '../../domain/usecases/get_pharmacy_order_usecase.dart';
import '../../domain/usecases/get_pharmacy_orders_usecase.dart';
import 'pharmacy_orders_state.dart';

class PharmacyOrdersCubit extends Cubit<PharmacyOrdersState> {
  final GetPharmacyOrdersUseCase _getOrdersUseCase;
  final DecidePharmacyOrderUseCase _decideOrderUseCase;
  final GetPharmacyOrderUseCase _getOrderUseCase;

  PharmacyOrdersCubit(this._getOrdersUseCase, this._decideOrderUseCase, this._getOrderUseCase)
      : super(const PharmacyOrdersLoading()) {
    load();
  }

  Future<void> load() async {
    emit(const PharmacyOrdersLoading());
    final result = await _getOrdersUseCase();
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(PharmacyOrdersLoaded(data));
      case ApiError(:final failure):
        emit(PharmacyOrdersLoadFailure(failure.message));
    }
  }

  /// Fetches again without going back to loading: what is on screen stays
  /// until the new list arrives, and stays if the fetch fails.
  Future<void> refresh() async {
    final current = state;
    if (current is PharmacyOrdersLoading) return;
    if (current is PharmacyOrdersLoadFailure) return load();

    final result = await _getOrdersUseCase();
    if (isClosed) return;
    if (result case Success(:final data)) emit(PharmacyOrdersLoaded(data));
  }

  /// The full record of [order] for the details screen; null when it cannot
  /// be fetched (the screen then keeps showing what the list gave it).
  Future<PharmacyOrder?> loadDetails(PharmacyOrder order) async {
    final result = await _getOrderUseCase(orderId: order.id);
    return switch (result) {
      Success(:final data) => data,
      ApiError() => null,
    };
  }

  void _markDecided(PharmacyOrder order, {required bool accept}) {
    final current = state;
    if (current is! PharmacyOrdersLoaded) return;
    final status = accept ? PharmacyOrderStatus.accepted : PharmacyOrderStatus.rejected;
    emit(
      PharmacyOrdersLoaded([
        for (final o in current.orders) o.id == order.id ? o.withStatus(status) : o,
      ]),
    );
  }

  /// Accepts or rejects [order]; returns the error message, or null once the
  /// backend has taken the decision (the list is refreshed by then).
  Future<String?> decide(PharmacyOrder order, {required bool accept}) async {
    final result = await _decideOrderUseCase(orderId: order.id, accept: accept);
    switch (result) {
      case Success():
        // Shown as decided at once, so a failed refetch cannot leave the
        // accept/reject buttons on an order the backend has already taken.
        _markDecided(order, accept: accept);
        await refresh();
        return null;
      case ApiError(:final failure):
        return failure.message;
    }
  }
}
