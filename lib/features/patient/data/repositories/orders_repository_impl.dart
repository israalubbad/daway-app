import '../../../../core/erroring/error_handler.dart';
import '../../../../core/helpers/api_result.dart';
import '../../../../core/helpers/paginated_fetch.dart';
import '../../domain/entities/checkout_quote.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/orders_repository.dart';
import '../datasources/orders_remote_data_source.dart';
import '../models/checkout_quote_model.dart';
import '../models/order_model.dart';
import '../../../../core/helpers/json_parsing.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  final OrdersRemoteDataSource _remoteDataSource;

  const OrdersRepositoryImpl(this._remoteDataSource);

  @override
  Future<ApiResult<List<Order>>> getOrders({required String token}) {
    return guardApi(() async {
      final ordersJson = await fetchAllPages(
        source: 'GET /patient/orders',
        fetchPage: (page) async =>
            (await _remoteDataSource.getOrders(token: token, page: page)).data,
      );
      final orders = ordersJson
          .map((json) => OrderModel.fromJson(json as Map<String, dynamic>).toEntity())
          .toList();
      return Success(orders);
    });
  }

  @override
  Future<ApiResult<void>> cancelOrder({required String token, required int orderId}) {
    return guardApi(() async {
      await _remoteDataSource.cancelOrder(token: token, orderId: orderId);
      return const Success(null);
    });
  }

  @override
  Future<ApiResult<CheckoutQuote>> getCheckoutQuote({
    required String token,
    required int addressId,
    String? couponCode,
  }) {
    return guardApi(() async {
      final response = await _remoteDataSource.getCheckoutQuote(
        token: token,
        addressId: addressId,
        couponCode: couponCode,
      );
      final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      return Success(CheckoutQuoteModel.fromJson(data));
    });
  }

  @override
  Future<ApiResult<int>> checkout({
    required String token,
    required int addressId,
    String? couponCode,
    String? notes,
    CheckoutQuote? quote,
    String? idempotencyKey,
  }) {
    return guardApi(() async {
      final response = await _remoteDataSource.checkout(
        token: token,
        addressId: addressId,
        couponCode: couponCode,
        notes: notes,
        quotedDeliveryFee: quote?.deliveryFee,
        quotedDiscount: quote?.discount,
        quotedGrandTotal: quote?.grandTotal,
        idempotencyKey: idempotencyKey,
      );
      final data = (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      final orderId = jsonInt(data['order_id']);
      if (orderId == null) {
        throw const FormatException('POST /patient/checkout response is missing order_id');
      }
      return Success(orderId);
    });
  }
}
