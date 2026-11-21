import 'package:daway_app/core/erroring/failure.dart';
import 'package:daway_app/core/helpers/api_result.dart';
import 'package:daway_app/features/pharmacy/domain/entities/pharmacy_order.dart';
import 'package:daway_app/features/pharmacy/domain/repositories/pharmacy_orders_repository.dart';
import 'package:daway_app/features/pharmacy/domain/usecases/get_pharmacy_order_usecase.dart';
import 'package:daway_app/features/pharmacy/domain/usecases/get_pharmacy_orders_usecase.dart';
import 'package:daway_app/features/pharmacy/presentation/cubit/pharmacy_orders_cubit.dart';
import 'package:daway_app/features/pharmacy/presentation/cubit/pharmacy_orders_state.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../helpers/in_memory_session_repository.dart';

PharmacyOrder _order(int id) => PharmacyOrder(
  id: id,
  orderNumber: 'DW-$id',
  createdAt: DateTime(2026, 10, 27),
  itemsCount: 1,
  total: 5,
  area: 'غزة',
);

class _FakeOrdersRepository implements PharmacyOrdersRepository {
  ApiResult<List<PharmacyOrder>> orders = Success([_order(1)]);
  ApiResult<PharmacyOrder> detail = Success(_order(1));
  int fetches = 0;

  @override
  Future<ApiResult<List<PharmacyOrder>>> getOrders({required String token}) async {
    fetches++;
    return orders;
  }

  @override
  Future<ApiResult<PharmacyOrder>> getOrder({required String token, required int orderId}) async => detail;

}

void main() {
  late _FakeOrdersRepository repository;
  late PharmacyOrdersCubit cubit;

  setUp(() {
    repository = _FakeOrdersRepository();
    final session = InMemorySessionRepository.pharmacy();
    cubit = PharmacyOrdersCubit(
      GetPharmacyOrdersUseCase(repository, session),
      GetPharmacyOrderUseCase(repository, session),
    );
  });

  tearDown(() => cubit.close());

  test('loadDetails returns the full record, or null on failure', () async {
    repository.detail = Success(_order(2));
    expect((await cubit.loadDetails(_order(1)))!.id, 2);

    repository.detail = const ApiError(ApiFailure(message: 'x'));
    expect(await cubit.loadDetails(_order(1)), isNull);
  });

  test('loads the orders on creation', () async {
    await cubit.load();

    expect((cubit.state as PharmacyOrdersLoaded).orders.single.id, 1);
  });

  test('a failed load shows its message', () async {
    repository.orders = const ApiError(ApiFailure(message: 'تعذر التحميل'));
    await cubit.load();

    expect((cubit.state as PharmacyOrdersLoadFailure).message, 'تعذر التحميل');
  });
}
