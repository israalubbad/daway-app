import 'package:daway_app/core/erroring/failure.dart';
import 'package:daway_app/core/helpers/api_result.dart';
import 'package:daway_app/features/patient/domain/entities/checkout_quote.dart';
import 'package:daway_app/features/patient/domain/entities/order.dart';
import 'package:daway_app/features/patient/domain/repositories/orders_repository.dart';
import 'package:daway_app/features/patient/domain/usecases/cancel_order_usecase.dart';
import 'package:daway_app/features/patient/domain/usecases/get_orders_usecase.dart';
import 'package:daway_app/features/patient/presentation/cubit/orders_cubit.dart';
import 'package:daway_app/features/patient/presentation/cubit/orders_state.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../helpers/in_memory_session_repository.dart';

final _order = Order(
  orderNumber: '1',
  pharmacyName: 'صيدلية الأمل',
  status: OrderStatus.confirmed,
  itemsCount: 1,
  price: 25,
  address: 'غزة',
  createdAt: DateTime(2026, 9, 29),
);

class _FakeOrdersRepository implements OrdersRepository {

  @override
  Future<ApiResult<void>> cancelOrder({required String token, required int orderId}) async =>
      const Success(null);
  ApiResult<List<Order>> ordersResult = Success([_order]);

  @override
  Future<ApiResult<List<Order>>> getOrders({required String token}) async => ordersResult;

  @override
  Future<ApiResult<CheckoutQuote>> getCheckoutQuote({
    required String token,
    required int addressId,
    String? couponCode,
  }) => throw UnimplementedError();

  @override
  Future<ApiResult<int>> checkout({
    required String token,
    required int addressId,
    String? couponCode,
    String? notes,
    CheckoutQuote? quote,
    String? idempotencyKey,
  }) async =>
      const Success(1);
}

void main() {
  late _FakeOrdersRepository repository;

  OrdersCubit buildCubit() =>
      OrdersCubit(
        GetOrdersUseCase(repository, InMemorySessionRepository.patient()),
        CancelOrderUseCase(repository, InMemorySessionRepository.patient()),
      );

  setUp(() {
    repository = _FakeOrdersRepository();
  });

  test('loads the orders on construction', () async {
    final cubit = buildCubit();
    addTearDown(cubit.close);

    await Future<void>.delayed(Duration.zero);

    expect(cubit.state, isA<OrdersLoaded>());
    expect((cubit.state as OrdersLoaded).orders, [_order]);
  });

  test('cancel reloads the list and returns null on success', () async {
    final cubit = buildCubit();
    addTearDown(cubit.close);
    await Future<void>.delayed(Duration.zero);

    final error = await cubit.cancel(_order);

    expect(error, isNull);
    expect(cubit.state, isA<OrdersLoaded>());
  });

  test('surfaces a load failure', () async {
    repository.ordersResult = const ApiError(NetworkFailure('تعذر الاتصال بالخادم'));
    final cubit = buildCubit();
    addTearDown(cubit.close);

    await Future<void>.delayed(Duration.zero);

    expect(cubit.state, isA<OrdersLoadFailure>());
  });

  test('load() refreshes the state after a failure', () async {
    repository.ordersResult = const ApiError(NetworkFailure('تعذر الاتصال بالخادم'));
    final cubit = buildCubit();
    addTearDown(cubit.close);
    await Future<void>.delayed(Duration.zero);

    repository.ordersResult = Success([_order]);
    await cubit.load();

    expect(cubit.state, isA<OrdersLoaded>());
  });
}
