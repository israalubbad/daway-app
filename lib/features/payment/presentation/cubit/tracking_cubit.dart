import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/helpers/api_result.dart';
import '../../domain/entities/payment.dart';
import '../../domain/usecases/payment_usecases.dart';

class TrackingState {
  final bool isLoading;
  final OrderTracking? tracking;
  final String? error;

  const TrackingState({this.isLoading = true, this.tracking, this.error});
}

class TrackingCubit extends Cubit<TrackingState> {
  final int orderId;
  final GetOrderTrackingUseCase _getTrackingUseCase;

  TrackingCubit(this.orderId, this._getTrackingUseCase) : super(const TrackingState());

  Future<void> load() async {
    emit(const TrackingState());
    final result = await _getTrackingUseCase(orderId);
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(TrackingState(isLoading: false, tracking: data));
      case ApiError(:final failure):
        emit(TrackingState(isLoading: false, error: failure.message));
    }
  }
}
