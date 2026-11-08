import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/helpers/api_result.dart';
import '../../domain/entities/accounting_overview.dart';
import '../../domain/entities/sale_invoice.dart';
import '../../domain/usecases/accounting_usecases.dart';
import 'new_sale_state.dart';

class NewSaleCubit extends Cubit<NewSaleState> {
  final SearchSaleItemsUseCase _searchItems;
  final FindSaleItemByBarcodeUseCase _findByBarcode;
  final CreateSaleUseCase _createSale;

  NewSaleCubit(this._searchItems, this._findByBarcode, this._createSale)
    : super(const NewSaleState());

  Future<void> queryChanged(String query) async {
    emit(state.copyWith(query: query, isSearching: query.trim().length >= 2));
    final result = await _searchItems(query);
    // An answer to an older query is dropped: the user has typed on since.
    if (isClosed || state.query != query) return;
    switch (result) {
      case Success(:final data):
        emit(state.copyWith(results: data, isSearching: false));
      case ApiError(:final failure):
        emit(state.copyWith(results: const [], isSearching: false, errorMessage: failure.message));
    }
  }

  /// A barcode was typed, or came from a scanner: a medicine it matches goes
  /// straight into the cart.
  Future<void> barcodeSubmitted(String barcode) async {
    if (barcode.trim().isEmpty) return;
    final result = await _findByBarcode(barcode);
    if (isClosed) return;
    switch (result) {
      case Success(:final data) when data != null:
        if (addItem(data)) {
          emit(state.copyWith(recognized: data, clearBarcodeMessage: true));
        } else {
          emit(state.copyWith(clearRecognized: true, barcodeMessage: _outOfStock));
        }
      case Success():
        emit(state.copyWith(clearRecognized: true, barcodeMessage: 'لم يتم العثور على دواء بهذا الباركود'));
      case ApiError(:final failure):
        emit(state.copyWith(clearRecognized: true, barcodeMessage: failure.message));
    }
  }


  static const _outOfStock = 'هذا الدواء غير متوفر في المخزون';

  /// Puts [item] in the cart; one already there gets one more unit, up to its
  /// stock. A medicine with none in stock is refused (and false returned): the
  /// pharmacy has nothing to sell.
  bool addItem(SaleItemOption item) {
    if (item.stock < 1) {
      emit(state.copyWith(errorMessage: _outOfStock));
      return false;
    }
    final existing = state.lines.indexWhere((line) => line.item.id == item.id);
    final lines = [...state.lines];
    if (existing == -1) {
      lines.add(SaleLine(item: item, quantity: 1));
    } else {
      final line = lines[existing];
      lines[existing] = line.withQuantity((line.quantity + 1).clamp(1, _maxFor(item)));
    }
    emit(state.copyWith(lines: lines, results: const [], query: '', clearError: true));
    return true;
  }

  void quantityChanged(int itemId, int quantity) {
    if (quantity < 1) return removeItem(itemId);
    emit(
      state.copyWith(
        lines: [
          for (final line in state.lines)
            if (line.item.id == itemId)
              line.withQuantity(quantity.clamp(1, _maxFor(line.item)))
            else
              line,
        ],
      ),
    );
  }

  void removeItem(int itemId) {
    emit(state.copyWith(lines: [for (final l in state.lines) if (l.item.id != itemId) l]));
  }

  void customerChanged(String name) {
    final trimmed = name.trim();
    emit(state.copyWith(customerName: trimmed, clearCustomer: trimmed.isEmpty));
  }

  void paidChanged(String text) {
    emit(state.copyWith(paid: double.tryParse(text.trim()) ?? 0));
  }

  void methodChanged(PaymentMethod method) => emit(state.copyWith(method: method));

  Future<void> submit() async {
    if (!state.canSubmit) return;
    emit(state.copyWith(isSaving: true, clearError: true));
    final result = await _createSale(
      NewSale(
        customerName: state.customerName,
        lines: state.lines,
        paid: state.paid,
        method: state.method,
      ),
    );
    if (isClosed) return;
    switch (result) {
      case Success():
        emit(state.copyWith(isSaving: false, completed: true));
      case ApiError(:final failure):
        emit(state.copyWith(isSaving: false, errorMessage: failure.message));
    }
  }

  /// A line cannot go above the stock (an item in the cart has at least one).
  int _maxFor(SaleItemOption item) => item.stock;
}
