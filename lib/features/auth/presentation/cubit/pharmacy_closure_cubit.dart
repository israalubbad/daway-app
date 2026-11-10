import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/helpers/api_result.dart';
import '../../domain/usecases/get_pharmacy_closure_request_usecase.dart';
import '../../domain/usecases/request_pharmacy_closure_usecase.dart';
import 'pharmacy_closure_state.dart';

/// The pharmacy's request to close its account: reads whether one exists and
/// sends a new one for the admin to review.
class PharmacyClosureCubit extends Cubit<PharmacyClosureState> {
  final GetPharmacyClosureRequestUseCase _getRequest;
  final RequestPharmacyClosureUseCase _sendRequest;

  PharmacyClosureCubit(this._getRequest, this._sendRequest)
      : super(const PharmacyClosureLoading());

  Future<void> load() async {
    emit(const PharmacyClosureLoading());
    final result = await _getRequest();
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(PharmacyClosureLoaded(request: data));
      case ApiError():
        emit(const PharmacyClosureLoadFailure());
    }
  }

  /// Sends the request. Does nothing while one is being sent or one is already
  /// waiting for the admin.
  Future<void> submit({String? reason}) async {
    final current = state;
    final known = current is PharmacyClosureLoaded ? current.request : null;
    if (current is PharmacyClosureLoaded && current.isSubmitting) return;
    if (known?.blocksNewRequest ?? false) return;

    emit(PharmacyClosureLoaded(request: known, isSubmitting: true));
    final result = await _sendRequest(reason: reason);
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(PharmacyClosureLoaded(request: data));
      case ApiError(:final failure):
        emit(PharmacyClosureLoaded(request: known, errorMessage: failure.message));
    }
  }

  /// The sheet was dismissed: a failure message belongs to the attempt that
  /// closed with it, not to the next time the sheet opens.
  void clearError() {
    final current = state;
    if (current is PharmacyClosureLoaded && current.errorMessage != null) {
      emit(PharmacyClosureLoaded(request: current.request));
    }
  }
}
