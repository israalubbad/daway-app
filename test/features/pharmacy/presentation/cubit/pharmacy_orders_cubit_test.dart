import 'package:daway_app/core/erroring/failure.dart';
import 'package:daway_app/core/helpers/api_result.dart';
import 'package:daway_app/features/auth/domain/entities/account_type.dart';
import 'package:daway_app/features/auth/domain/entities/user_session.dart';
import 'package:daway_app/features/auth/domain/repositories/session_repository.dart';
import 'package:daway_app/features/pharmacy/domain/entities/pharmacy_order.dart';
import 'package:daway_app/features/pharmacy/domain/repositories/pharmacy_orders_repository.dart';
import 'package:daway_app/features/pharmacy/domain/usecases/decide_pharmacy_order_usecase.dart';
import 'package:daway_app/features/pharmacy/domain/usecases/get_pharmacy_orders_usecase.dart';
import 'package:daway_app/features/pharmacy/presentation/cubit/pharmacy_orders_cubit.dart';
import 'package:daway_app/features/pharmacy/presentation/cubit/pharmacy_orders_state.dart';
import 'package:flutter_test/flutter_test.dart';

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
  ApiResult<void> decision = const Success(null);
  int? decidedId;
  bool? accepted;
  int fetches = 0;

  @override
  Future<ApiResult<List<PharmacyOrder>>> getOrders({required String token}) async {
    fetches++;
    return orders;
  }

  @override
  Future<ApiResult<void>> decide({
    required String token,
    required int orderId,
    required bool accept,
  }) async {
    decidedId = orderId;
    accepted = accept;
    return decision;
  }
}

class _FakeSessionRepository implements SessionRepository {
  @override
  Future<void> saveSession(UserSession session) async {}

  @override
  Future<UserSession?> getSession() async =>
      const UserSession(accountType: AccountType.pharmacy, token: 'tok-1');

  @override
  Future<void> clearSession() async {}
}

void main() {
  late _FakeOrdersRepository repository;
  late PharmacyOrdersCubit cubit;

  setUp(() {
    repository = _FakeOrdersRepository();
    final session = _FakeSessionRepository();
    cubit = PharmacyOrdersCubit(
      GetPharmacyOrdersUseCase(repository, session),
      DecidePharmacyOrderUseCase(repository, session),
    );
  });

  tearDown(() => cubit.close());

  test('loads the orders on creation', () async {
    await cubit.load();

    expect((cubit.state as PharmacyOrdersLoaded).orders.single.id, 1);
  });

  test('a failed load shows its message', () async {
    repository.orders = const ApiError(ApiFailure(message: 'تعذر التحميل'));
    await cubit.load();

    expect((cubit.state as PharmacyOrdersLoadFailure).message, 'تعذر التحميل');
  });

  test('accepting sends the id and refreshes the list', () async {
    await cubit.load();
    final fetchesBefore = repository.fetches;

    final error = await cubit.decide(_order(1), accept: true);

    expect(error, isNull);
    expect(repository.decidedId, 1);
    expect(repository.accepted, isTrue);
    expect(repository.fetches, greaterThan(fetchesBefore));
  });

  test('a rejected decision returns the backend message and keeps the list', () async {
    await cubit.load();
    repository.decision = const ApiError(ApiFailure(message: 'الطلب تم البت فيه'));

    final error = await cubit.decide(_order(1), accept: false);

    expect(error, 'الطلب تم البت فيه');
    expect(cubit.state, isA<PharmacyOrdersLoaded>());
  });

  test('a decided order shows as decided even when the refetch fails', () async {
    await cubit.load();
    repository.orders = const ApiError(ApiFailure(message: 'offline'));

    final error = await cubit.decide(_order(1), accept: true);

    expect(error, isNull);
    final orders = (cubit.state as PharmacyOrdersLoaded).orders;
    expect(orders.single.status, PharmacyOrderStatus.accepted);
  });

  test('a rejection is shown as rejected', () async {
    await cubit.load();
    repository.orders = const ApiError(ApiFailure(message: 'offline'));

    await cubit.decide(_order(1), accept: false);

    expect((cubit.state as PharmacyOrdersLoaded).orders.single.status, PharmacyOrderStatus.rejected);
  });
}
