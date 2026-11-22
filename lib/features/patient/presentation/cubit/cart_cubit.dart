import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/helpers/api_result.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/usecases/clear_cart_usecase.dart';
import '../../domain/usecases/delete_cart_item_usecase.dart';
import '../../domain/usecases/get_cart_items_usecase.dart';
import '../../domain/usecases/update_cart_item_quantity_usecase.dart';
import 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  final GetCartItemsUseCase _getCartItemsUseCase;
  final UpdateCartItemQuantityUseCase _updateCartItemQuantityUseCase;
  final DeleteCartItemUseCase _deleteCartItemUseCase;
  final ClearCartUseCase _clearCartUseCase;

  CartCubit(
    this._getCartItemsUseCase,
    this._updateCartItemQuantityUseCase,
    this._deleteCartItemUseCase,
    this._clearCartUseCase,
  ) : super(const CartLoading()) {
    load();
  }

  Future<void> load() async {
    emit(const CartLoading());
    final result = await _getCartItemsUseCase();
    if (isClosed) return;
    switch (result) {
      case Success(:final data):
        emit(CartLoaded(data));
      case ApiError(:final failure):
        emit(CartLoadFailure(failure.message));
    }
  }

  /// Returns null on success, or a user-facing error message (same
  /// contract as MedicineDetailCubit.toggleFavorite).
  Future<String?> deleteItem(CartItem item) async {
    final current = state;
    if (current is! CartLoaded || current.updatingIds.contains(item.id)) return null;

    emit(current.copyWith(updatingIds: {...current.updatingIds, item.id}));
    final result = await _deleteCartItemUseCase(item.id);
    if (isClosed) return null;

    final latest = state;
    if (latest is! CartLoaded) return null;
    switch (result) {
      case Success():
        emit(
          latest.copyWith(
            items: [
              for (final existing in latest.items)
                if (existing.id != item.id) existing,
            ],
            updatingIds: latest.updatingIds.difference({item.id}),
          ),
        );
        return null;
      case ApiError(:final failure):
        emit(latest.copyWith(updatingIds: latest.updatingIds.difference({item.id})));
        return failure.message;
    }
  }

  /// Drops every line that is not from [pharmacyId] — the patient picked the
  /// one pharmacy to order from. Returns null on success, or an error
  /// message (the lines that were removed stay removed).
  Future<String?> keepOnlyPharmacy(int pharmacyId) async {
    final current = state;
    if (current is! CartLoaded) return null;

    var items = current.items;
    for (final item in current.items.where((i) => i.pharmacyId != pharmacyId)) {
      final result = await _deleteCartItemUseCase(item.id);
      if (isClosed) return null;
      if (result case ApiError(:final failure)) {
        emit(CartLoaded(items));
        return failure.message;
      }
      items = [
        for (final i in items)
          if (i.id != item.id) i,
      ];
    }
    emit(CartLoaded(items));
    return null;
  }

  /// Empties the cart. Returns null on success, or an error message.
  Future<String?> clear() async {
    final current = state;
    if (current is! CartLoaded || current.items.isEmpty) return null;

    final result = await _clearCartUseCase();
    if (isClosed) return null;

    switch (result) {
      case Success():
        emit(const CartLoaded([]));
        return null;
      case ApiError(:final failure):
        return failure.message;
    }
  }

  /// Returns null on success, or the server message when the change was
  /// refused (e.g. not enough stock), for the screen to show.
  Future<String?> incrementQuantity(CartItem item) => _setQuantity(item, item.quantity + 1);

  /// Clamped at 1 — there is no delete affordance on this screen's cards
  /// (see MedicineCartOptionCard's doc comment), so the minus button simply
  /// stops decrementing rather than removing the line.
  Future<String?> decrementQuantity(CartItem item) {
    if (item.quantity <= 1) return Future.value();
    return _setQuantity(item, item.quantity - 1);
  }

  Future<String?> _setQuantity(CartItem item, int quantity) async {
    final current = state;
    if (current is! CartLoaded || current.updatingIds.contains(item.id)) return null;

    emit(current.copyWith(updatingIds: {...current.updatingIds, item.id}));
    final result = await _updateCartItemQuantityUseCase(itemId: item.id, quantity: quantity);
    if (isClosed) return null;

    final latest = state;
    if (latest is! CartLoaded) return null;
    switch (result) {
      case Success():
        // Patch the one line locally instead of re-fetching the whole cart —
        // the new quantity is already known, and a full reload would emit
        // CartLoading and tear down every row for a one-line change.
        emit(
          latest.copyWith(
            items: [
              for (final existing in latest.items)
                if (existing.id == item.id) existing.copyWith(quantity: quantity) else existing,
            ],
            updatingIds: latest.updatingIds.difference({item.id}),
          ),
        );
        return null;
      case ApiError(:final failure):
        emit(latest.copyWith(updatingIds: latest.updatingIds.difference({item.id})));
        return failure.message;
    }
  }
}
