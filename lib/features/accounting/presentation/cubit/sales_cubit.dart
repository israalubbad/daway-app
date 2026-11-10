import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/helpers/api_result.dart';
import '../../domain/entities/accounting_overview.dart';
import '../../domain/entities/sale_invoice.dart';
import '../../domain/usecases/accounting_usecases.dart';
import 'sales_state.dart';

class SalesCubit extends Cubit<SalesState> {
  final GetSalesUseCase _getSales;
  final RecordInvoicePaymentUseCase _recordPayment;
  final CreateRefundUseCase _createRefund;

  SalesCubit(this._getSales, this._recordPayment, this._createRefund)
    : super(const SalesLoading()) {
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

  /// Records a payment against [invoice]; returns the message to show when it
  /// fails, or null once it is saved (the list is refreshed by then).
  Future<String?> recordPayment(
    SaleInvoice invoice, {
    required double amount,
    required PaymentMethod method,
  }) async {
    final result = await _recordPayment(invoice: invoice, amount: amount, method: method);
    return _afterChange(result);
  }

  /// Returns units of an invoice; the same contract as [recordPayment].
  Future<String?> refund(RefundRequest request) async => _afterChange(await _createRefund(request));

  Future<String?> _afterChange(ApiResult<void> result) async {
    switch (result) {
      case Success():
        await refresh();
        return null;
      case ApiError(:final failure):
        return failure.message;
    }
  }
}
