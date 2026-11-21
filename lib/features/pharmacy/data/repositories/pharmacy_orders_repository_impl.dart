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
  Future<ApiResult<List<PharmacyOrder>>> getOrders({required String token}) {
    return guardApi(() async {
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
    });
  }

  @override
  Future<ApiResult<PharmacyOrder>> getOrder({required String token, required int orderId}) {
    return guardApi(() async {
      final response = await _remoteDataSource.getOrder(token: token, orderId: orderId);
      final body = response.data;
      // The record may sit under `data` or be the body itself.
      final record = body is Map<String, dynamic>
          ? (body['data'] is Map<String, dynamic> ? body['data'] as Map<String, dynamic> : body)
          : null;
      if (record == null) {
        throw FormatException('GET /pharmacy/sub-orders/$orderId: unexpected body $body');
      }
      return Success(PharmacyOrderModel.fromJson(record).order);
    });
  }
}
