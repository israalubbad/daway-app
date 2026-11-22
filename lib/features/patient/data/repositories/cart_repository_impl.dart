import '../../../../core/erroring/error_handler.dart';
import '../../../../core/helpers/api_result.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_remote_data_source.dart';
import '../models/cart_item_model.dart';

class CartRepositoryImpl implements CartRepository {
  final CartRemoteDataSource _remoteDataSource;

  const CartRepositoryImpl(this._remoteDataSource);

  @override
  Future<ApiResult<List<CartItem>>> getItems({required String token}) {
    return guardApi(() async {
      final response = await _remoteDataSource.getCart(token: token);
      final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      final itemsRaw = data['items'];
      if (itemsRaw is! List) {
        throw FormatException('Unexpected GET /patient/cart response shape: ${response.data}');
      }
      final items = itemsRaw
          .whereType<Map<String, dynamic>>()
          .map((json) => CartItemModel.fromJson(json).toEntity())
          .toList();
      return Success(items);
    });
  }

  @override
  Future<ApiResult<void>> addItem({
    required String token,
    int? pharmacyMedicineId,
    required int pharmacyId,
    required int medicineId,
    required int quantity,
  }) {
    return guardApi(() async {
      await _remoteDataSource.addItem(
        token: token,
        pharmacyMedicineId: pharmacyMedicineId,
        pharmacyId: pharmacyId,
        medicineId: medicineId,
        quantity: quantity,
      );
      return const Success(null);
    });
  }

  @override
  Future<ApiResult<void>> deleteItem({required String token, required int itemId}) {
    return guardApi(() async {
      await _remoteDataSource.deleteItem(token: token, itemId: itemId);
      return const Success(null);
    });
  }

  @override
  Future<ApiResult<void>> clearCart({required String token}) {
    return guardApi(() async {
      await _remoteDataSource.clearCart(token: token);
      return const Success(null);
    });
  }

  @override
  Future<ApiResult<void>> updateQuantity({
    required String token,
    required int itemId,
    required int quantity,
  }) {
    return guardApi(() async {
      await _remoteDataSource.updateItemQuantity(
        token: token,
        itemId: itemId,
        quantity: quantity,
      );
      return const Success(null);
    });
  }
}
