import '../../../../core/helpers/api_result.dart';
import '../entities/pharmacy_order.dart';

abstract interface class PharmacyOrdersRepository {
  Future<ApiResult<List<PharmacyOrder>>> getOrders({required String token});

  /// Accepts or rejects the sub-order.
  Future<ApiResult<void>> decide({
    required String token,
    required int orderId,
    required bool accept,
  });
}
