import '../../../../core/helpers/api_result.dart';
import '../entities/pharmacy_order.dart';

abstract interface class PharmacyOrdersRepository {
  Future<ApiResult<List<PharmacyOrder>>> getOrders({required String token});

  /// One sub-order in full (`GET /pharmacy/sub-orders/{id}`): the medicines
  /// with quantity and price, the patient, the payment.
  Future<ApiResult<PharmacyOrder>> getOrder({required String token, required int orderId});
}
