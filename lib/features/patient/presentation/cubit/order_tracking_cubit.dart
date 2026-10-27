import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/helpers/api_result.dart';
import '../../domain/entities/checkout_flow.dart';
import '../../domain/usecases/checkout_flow_usecases.dart';

sealed class OrderTrackingState {
  const OrderTrackingState();
}

class OrderTrackingLoading extends OrderTrackingState {
  const OrderTrackingLoading();
}

class OrderTrackingFailure extends OrderTrackingState {
  final String message;

  const OrderTrackingFailure(this.message);
}

class OrderTrackingLoaded extends OrderTrackingState {
  final OrderTracking tracking;

  /// False while the admin has not approved the transfer yet: the order is
  /// not confirmed to the patient until then.
  final bool paymentApproved;

  const OrderTrackingLoaded(this.tracking, {this.paymentApproved = true});
}
/// The status timeline of an order, shown on "تم تأكيد الطلب".
class OrderTrackingCubit extends Cubit<OrderTrackingState> {
  final int orderId;
  final GetOrderTrackingUseCase _getTrackingUseCase;
  final GetOrderPaymentUseCase _getPaymentUseCase;

  OrderTrackingCubit(
    this.orderId,
    this._getTrackingUseCase,
    this._getPaymentUseCase,
  ) : super(const OrderTrackingLoading()) {
    load();
  }

  Future<void> load() async {
    emit(const OrderTrackingLoading());
    final result = await _getTrackingUseCase(orderId);
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        // The payment status only decides the first step: if it cannot be
        // read, the order's own status is trusted.
        final payment = await _getPaymentUseCase(orderId);
        if (isClosed) return;
        final approved = switch (payment) {
          Success(:final data) => data.isApproved,
          ApiError() => true,
        };
        emit(OrderTrackingLoaded(data, paymentApproved: approved));
      case ApiError(:final failure):
        emit(OrderTrackingFailure(failure.message));
    }
  }
}
