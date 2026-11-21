import '../../../../core/erroring/error_handler.dart';
import '../../../../core/helpers/api_result.dart';
import '../../../../core/helpers/server_timestamp.dart';
import '../../domain/entities/checkout_flow.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/checkout_flow_repository.dart';
import '../datasources/checkout_flow_remote_data_source.dart';

class CheckoutFlowRepositoryImpl implements CheckoutFlowRepository {
  final CheckoutFlowRemoteDataSource _remoteDataSource;

  const CheckoutFlowRepositoryImpl(this._remoteDataSource);

  @override
  Future<ApiResult<double>> validateCoupon({
    required String token,
    required String code,
    required double orderTotal,
  }) {
    return guardApi(() async {
      final response = await _remoteDataSource.validateCoupon(
        token: token,
        code: code,
        orderTotal: orderTotal,
      );
      final discount = (_data(response.data)['discount'] as num?)?.toDouble();
      if (discount == null) {
        throw const FormatException(
          'POST /patient/coupons/validate response is missing discount',
        );
      }
      return Success(discount);
    });
  }

  @override
  Future<ApiResult<OrderPayment>> getPayment({
    required String token,
    required int orderId,
  }) {
    return guardApi(() async {
      final response = await _remoteDataSource.getPayment(
        token: token,
        orderId: orderId,
      );
      var payment = parsePayment(orderId, _data(response.data));
      // The summary can come back without the banks; the active banks have
      // their own endpoint, so ask it before telling the patient there is
      // nothing to pay with.
      if (payment.banks.isEmpty) {
        final banksResponse = await _remoteDataSource.getPaymentBanks(
          token: token,
        );
        final body = banksResponse.data;
        final banks = parseBanks(
          body is Map<String, dynamic> ? body['data'] : null,
        );
        payment = payment.withBanks(banks);
      }
      return Success(payment);
    });
  }

  @override
  Future<ApiResult<void>> submitReceipt({
    required String token,
    required int orderId,
    required int bankId,
    required double amount,
    required String receiptPath,
  }) {
    return guardApi(() async {
      await _remoteDataSource.submitReceipt(
        token: token,
        orderId: orderId,
        bankId: bankId,
        amount: amount,
        receiptPath: receiptPath,
      );
      return const Success(null);
    });
  }

  @override
  Future<ApiResult<void>> reportProblem({
    required String token,
    required int orderId,
    required String message,
  }) {
    return guardApi(() async {
      await _remoteDataSource.reportProblem(
        token: token,
        orderId: orderId,
        message: message,
      );
      return const Success(null);
    });
  }

  @override
  Future<ApiResult<OrderTracking>> getTracking({
    required String token,
    required int orderId,
  }) {
    return guardApi(() async {
      final response = await _remoteDataSource.getTracking(
        token: token,
        orderId: orderId,
      );
      return Success(parseTracking(_data(response.data)));
    });
  }

  static Map<String, dynamic> _data(Object? body) {
    final data = body is Map<String, dynamic> ? body['data'] : null;
    if (data is! Map<String, dynamic>) {
      throw FormatException('Unexpected response shape: $body');
    }
    return data;
  }

  /// The bank rows are read with a few alternative field names because the
  /// payment payload's bank shape is not documented beyond "name and account".
  static List<PaymentBank> parseBanks(Object? list) {
    return [
      for (final raw in (list as List?) ?? const [])
        if (raw is Map<String, dynamic>)
          PaymentBank(
            id: (raw['id'] as num?)?.toInt() ?? 0,
            name: (raw['name'] ?? raw['bank_name'] ?? '').toString(),
            accountNumber:
                (raw['account_number'] ??
                        raw['account'] ??
                        raw['iban'] ??
                        raw['phone'] ??
                        '')
                    .toString(),
          ),
    ];
  }

  static OrderPayment parsePayment(int orderId, Map<String, dynamic> data) {
    final banks = parseBanks(data['banks'] ?? data['payment_banks']);
    return OrderPayment(
      orderId: orderId,
      grandTotal: (data['grand_total'] as num?)?.toDouble() ?? 0,
      deliveryFee: (data['delivery_fee'] as num?)?.toDouble(),
      discount: (data['discount'] as num?)?.toDouble(),
      paymentStatus: data['payment_status'] as String? ?? '',
      canSubmitReceipt: data['can_submit_receipt'] as bool? ?? false,
      // A delivery_fee sent but empty = the admin has not set the price yet.
      // A payload without the field says nothing, so it is not waited on.
      awaitingDeliveryFee:
          data.containsKey('delivery_fee') && data['delivery_fee'] == null,
      banks: banks,
    );
  }

  static OrderTracking parseTracking(Map<String, dynamic> data) {
    final history = [
      for (final raw in (data['status_histories'] as List?) ?? const [])
        if (raw is Map<String, dynamic>)
          OrderTrackingEvent(
            status: OrderStatus.fromApi(raw['status'] as String? ?? ''),
            at: tryParseServerTimestamp(raw['created_at'] as String?),
          ),
    ];
    return OrderTracking(
      status: OrderStatus.fromApi(data['status'] as String? ?? ''),
      history: history,
    );
  }
}
