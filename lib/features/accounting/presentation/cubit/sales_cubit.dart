import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/helpers/api_result.dart';
import '../../domain/entities/accounting_overview.dart';
import '../../domain/entities/sale_invoice.dart';
import '../../domain/usecases/accounting_usecases.dart';
import 'sales_state.dart';

import '../../../../core/localization/translations.dart';

class SalesCubit extends Cubit<SalesState> {
  final GetSalesUseCase _getSales;
  final GetInvoiceUseCase _getInvoice;
  final GetRefundableLinesUseCase _getRefundableLines;
  final RecordInvoicePaymentUseCase _recordPayment;
  final CreateRefundUseCase _createRefund;

  SalesCubit(
    this._getSales,
    this._getInvoice,
    this._getRefundableLines,
    this._recordPayment,
    this._createRefund,
  ) : super(const SalesLoading()) {
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

  /// [invoice] with its lines, which the list does not carry; or the message to
  /// show when they cannot be fetched.
  Future<({SaleInvoice? invoice, String? error})> loadDetails(SaleInvoice invoice) async {
    final result = await _getInvoice(invoice.number);
    return switch (result) {
      Success(:final data) => (invoice: data, error: null),
      ApiError(:final failure) => (invoice: null, error: failure.message),
    };
  }

  /// The lines of [invoice] that can still be returned, or the message to show
  /// (a cancelled invoice, nothing left to return).
  Future<({List<InvoiceLine>? lines, String? error})> loadRefundableLines(
    SaleInvoice invoice,
  ) async {
    final result = await _getRefundableLines(invoice);
    return switch (result) {
      Success(:final data) when data.isEmpty => (
        lines: null,
        error: 'لا توجد أصناف متاحة للإرجاع'.tr,
      ),
      Success(:final data) => (lines: data, error: null),
      ApiError(:final failure) => (lines: null, error: failure.message),
    };
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
