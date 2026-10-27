import '../../../../core/erroring/error_handler.dart';
import '../../../../core/helpers/api_result.dart';
import '../../../../core/helpers/json_list_extractor.dart';
import '../../domain/entities/pharmacy_order.dart';
import '../../domain/repositories/pharmacy_orders_repository.dart';
import '../datasources/pharmacy_orders_remote_data_source.dart';
import '../models/pharmacy_order_model.dart';

class PharmacyOrdersRepositoryImpl implements PharmacyOrdersRepository {
  final PharmacyOrdersRemoteDataSource _remoteDataSource;

  const PharmacyOrdersRepositoryImpl(this._remoteDataSource);

  @override
  Future<ApiResult<List<PharmacyOrder>>> getOrders({required String token}) async {
    try {
      final response = await _remoteDataSource.getOrders(token: token);
      final json = extractJsonList(response.data, source: 'GET /pharmacy/sub-orders');
      final orders = <PharmacyOrder>[];
      for (final record in json) {
        try {
          orders.add(
            PharmacyOrderModel.fromJson(record as Map<String, dynamic>).order,
          );
        } catch (_) {
          // One malformed record must not hide the others.
        }
      }
      return Success(orders);
    } catch (e) {
      return ApiError(mapExceptionToFailure(e));
    }
  }

  @override
  Future<ApiResult<void>> decide({
    required String token,
    required int orderId,
    required bool accept,
  }) async {
    try {
      await _remoteDataSource.updateStatus(
        token: token,
        orderId: orderId,
        status: accept ? 'accepted' : 'rejected',
      );
      return const Success(null);
    } catch (e) {
      return ApiError(mapExceptionToFailure(e));
    }
  }
}
