import 'package:daway_app/core/helpers/api_result.dart';
import 'package:daway_app/features/patient/data/datasources/orders_remote_data_source.dart';
import 'package:daway_app/features/patient/data/repositories/orders_repository_impl.dart';
import 'package:daway_app/features/patient/domain/entities/checkout_quote.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubRemoteDataSource extends OrdersRemoteDataSource {
  /// Response for page 1 when [pageResponses] has no explicit entry for it.
  Object? nextOrdersResponse;

  /// Explicit per-page responses — set these to test multi-page walks.
  final Map<int, Object?> pageResponses = {};
  Object? nextCheckoutResponse;
  Object? nextQuoteResponse;
  bool quoteThrows = false;
  int? lastQuotedDeliveryFee;
  double? lastQuotedDiscount;
  double? lastQuotedGrandTotal;
  String? lastIdempotencyKey;
  String? lastQuoteCoupon;
  bool getThrows = false;
  bool checkoutThrows = false;
  int? lastAddressId;
  final List<int> requestedPages = [];

  _StubRemoteDataSource() : super(Dio());

  @override
  Future<Response<dynamic>> getOrders({required String token, int page = 1}) async {
    if (getThrows) throw DioException(requestOptions: RequestOptions());
    requestedPages.add(page);
    final data = pageResponses[page] ?? (page == 1 ? nextOrdersResponse : null);
    return Response(requestOptions: RequestOptions(), data: data, statusCode: 200);
  }

  @override
  Future<Response<dynamic>> getCheckoutQuote({
    required String token,
    required int addressId,
    String? couponCode,
  }) async {
    if (quoteThrows) throw DioException(requestOptions: RequestOptions());
    lastAddressId = addressId;
    lastQuoteCoupon = couponCode;
    return Response(requestOptions: RequestOptions(), data: nextQuoteResponse, statusCode: 200);
  }

  @override
  Future<Response<dynamic>> checkout({
    required String token,
    required int addressId,
    String? couponCode,
    String? notes,
    int? quotedDeliveryFee,
    double? quotedDiscount,
    double? quotedGrandTotal,
    String? idempotencyKey,
  }) async {
    if (checkoutThrows) throw DioException(requestOptions: RequestOptions());
    lastQuotedDeliveryFee = quotedDeliveryFee;
    lastQuotedDiscount = quotedDiscount;
    lastQuotedGrandTotal = quotedGrandTotal;
    lastIdempotencyKey = idempotencyKey;
    lastAddressId = addressId;
    return Response(
      requestOptions: RequestOptions(),
      data: nextCheckoutResponse,
      statusCode: 200,
    );
  }
}

void main() {
  late _StubRemoteDataSource remoteDataSource;
  late OrdersRepositoryImpl repository;

  setUp(() {
    remoteDataSource = _StubRemoteDataSource();
    repository = OrdersRepositoryImpl(remoteDataSource);
  });

  group('getOrders', () {
    test('parses the order rows out of the data list', () async {
      remoteDataSource.nextOrdersResponse = {
        'success': true,
        'data': [
          {'id': 1, 'status': 'confirmed', 'total': 25.0, 'items_count': 1},
        ],
        'pagination': {'total': 1, 'last_page': 1},
      };

      final result = await repository.getOrders(token: 'tok');

      expect(result, isA<Success<Object?>>());
      final orders = (result as Success).data;
      expect(orders, hasLength(1));
      expect(orders.first.orderNumber, '1');
    });

    test('walks every page instead of only returning the first 20 orders', () async {
      remoteDataSource.pageResponses[1] = {
        'success': true,
        'data': [
          {'id': 1, 'status': 'confirmed', 'total': 10.0, 'items_count': 1},
        ],
        'pagination': {'total': 2, 'last_page': 2},
      };
      remoteDataSource.pageResponses[2] = {
        'success': true,
        'data': [
          {'id': 2, 'status': 'pending', 'total': 20.0, 'items_count': 1},
        ],
        'pagination': {'total': 2, 'last_page': 2},
      };

      final result = await repository.getOrders(token: 'tok');

      expect(result, isA<Success<Object?>>());
      final orders = (result as Success).data;
      expect(orders.map((o) => o.orderNumber), ['1', '2']);
      expect(remoteDataSource.requestedPages, [1, 2]);
    });

    test('surfaces a network failure instead of throwing', () async {
      remoteDataSource.getThrows = true;

      final result = await repository.getOrders(token: 'tok');

      expect(result, isA<ApiError<Object?>>());
    });
  });

  group('checkout', () {
    test('sends the address id and returns the new order id', () async {
      remoteDataSource.nextCheckoutResponse = {
        'success': true,
        'data': {'order_id': 42, 'subtotal': 25.0, 'discount': 0, 'total': 25.0},
      };

      final result = await repository.checkout(token: 'tok', addressId: 1);

      expect(result, isA<Success<Object?>>());
      expect((result as Success).data, 42);
      expect(remoteDataSource.lastAddressId, 1);
    });

    test('a response missing order_id is an error, not a fabricated order 0', () async {
      remoteDataSource.nextCheckoutResponse = {
        'success': true,
        'data': {'subtotal': 25.0, 'discount': 0, 'total': 25.0},
      };

      final result = await repository.checkout(token: 'tok', addressId: 1);

      expect(result, isA<ApiError<Object?>>());
    });

    test('surfaces a network failure instead of throwing', () async {
      remoteDataSource.checkoutThrows = true;

      final result = await repository.checkout(token: 'tok', addressId: 1);

      expect(result, isA<ApiError<Object?>>());
    });
  });

  group('checkout with a quote', () {
    const quote = CheckoutQuote(
      subtotal: 80,
      discount: 5,
      total: 75,
      deliveryFee: 9,
      grandTotal: 84,
    );

    test('sends the quoted amounts and the idempotency key', () async {
      remoteDataSource.nextCheckoutResponse = {
        'data': {'order_id': 7},
      };

      final result = await repository.checkout(
        token: 'tok',
        addressId: 1,
        quote: quote,
        idempotencyKey: 'key-1',
      );

      expect((result as Success).data, 7);
      expect(remoteDataSource.lastQuotedDeliveryFee, 9);
      expect(remoteDataSource.lastQuotedDiscount, 5);
      expect(remoteDataSource.lastQuotedGrandTotal, 84);
      expect(remoteDataSource.lastIdempotencyKey, 'key-1');
    });

    test('sends none of them without a quote', () async {
      remoteDataSource.nextCheckoutResponse = {
        'data': {'order_id': 7},
      };

      await repository.checkout(token: 'tok', addressId: 1);

      expect(remoteDataSource.lastQuotedDeliveryFee, isNull);
      expect(remoteDataSource.lastQuotedDiscount, isNull);
      expect(remoteDataSource.lastQuotedGrandTotal, isNull);
      expect(remoteDataSource.lastIdempotencyKey, isNull);
    });
  });

  group('getCheckoutQuote', () {
    test('reads the amounts, the whole-number fee and the pricing details', () async {
      remoteDataSource.nextQuoteResponse = {
        'success': true,
        'data': {
          'subtotal': 80,
          'discount': 5,
          'total': 75,
          'delivery_fee': 9,
          'grand_total': 84,
          'distance_meters': 2300,
          'pricing_mode': 'distance',
          'tier_id': 3,
        },
      };

      final result = await repository.getCheckoutQuote(
        token: 'tok',
        addressId: 4,
        couponCode: 'SAVE10',
      );

      final quote = (result as Success<CheckoutQuote>).data;
      expect(quote.subtotal, 80);
      expect(quote.discount, 5);
      expect(quote.total, 75);
      expect(quote.deliveryFee, 9);
      expect(quote.grandTotal, 84);
      expect(quote.distanceMeters, 2300);
      expect(quote.pricingMode, 'distance');
      expect(quote.tierId, 3);
      expect(remoteDataSource.lastAddressId, 4);
      expect(remoteDataSource.lastQuoteCoupon, 'SAVE10');
    });

    test('amounts sent as decimal strings are read as numbers', () async {
      remoteDataSource.nextQuoteResponse = {
        'data': {
          'subtotal': '80.00',
          'discount': '0.00',
          'total': '80.00',
          'delivery_fee': '9',
          'grand_total': '89.00',
        },
      };

      final result = await repository.getCheckoutQuote(token: 'tok', addressId: 4);

      final quote = (result as Success<CheckoutQuote>).data;
      expect(quote.deliveryFee, 9);
      expect(quote.grandTotal, 89);
      expect(quote.distanceMeters, isNull);
    });

    test('a response without a delivery fee is an error, not a free delivery', () async {
      remoteDataSource.nextQuoteResponse = {
        'data': {'subtotal': 80, 'total': 80, 'grand_total': 80},
      };

      final result = await repository.getCheckoutQuote(token: 'tok', addressId: 4);

      expect(result, isA<ApiError<CheckoutQuote>>());
    });

    test('surfaces a network failure instead of throwing', () async {
      remoteDataSource.quoteThrows = true;

      final result = await repository.getCheckoutQuote(token: 'tok', addressId: 4);

      expect(result, isA<ApiError<CheckoutQuote>>());
    });
  });
}
