import 'package:daway_app/core/erroring/failure.dart';
import 'package:daway_app/core/helpers/api_result.dart';
import 'package:daway_app/core/models/picked_location.dart';
import 'package:daway_app/core/routing/routes.dart';
import 'package:daway_app/features/auth/domain/entities/account_type.dart';
import 'package:daway_app/features/auth/domain/entities/user_session.dart';
import 'package:daway_app/features/auth/domain/repositories/session_repository.dart';
import 'package:daway_app/features/patient/domain/entities/cart_item.dart';
import 'package:daway_app/features/patient/domain/repositories/cart_repository.dart';
import 'package:daway_app/features/patient/domain/usecases/clear_cart_usecase.dart';
import 'package:daway_app/features/patient/domain/usecases/delete_cart_item_usecase.dart';
import 'package:daway_app/features/patient/domain/usecases/get_cart_items_usecase.dart';
import 'package:daway_app/features/patient/domain/usecases/update_cart_item_quantity_usecase.dart';
import 'package:daway_app/features/patient/presentation/cubit/cart_cubit.dart';
import 'package:daway_app/features/patient/presentation/screens/patient_cart_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

const _items = [
  CartItem(
    id: 1,
    medicineName: 'أموكسيسيلين',
    pharmacyId: 11,
    pharmacyName: 'صيدلية النور',
    price: 18,
    quantity: 1,
  ),
  CartItem(
    id: 2,
    medicineName: 'باراسيتامول',
    pharmacyId: 12,
    pharmacyName: 'صيدلية الأمل',
    price: 12,
    quantity: 2,
  ),
];


class _FakeCartRepository implements CartRepository {

  @override
  Future<ApiResult<void>> deleteItem({required String token, required int itemId}) async =>
      const Success(null);

  @override
  Future<ApiResult<void>> clearCart({required String token}) async => const Success(null);

  @override
  Future<ApiResult<void>> addItem({
    required String token,
    int? pharmacyMedicineId,
    required int pharmacyId,
    required int medicineId,
    required int quantity,
  }) async =>
      const Success(null);
  ApiResult<List<CartItem>> itemsResult = const Success(_items);

  @override
  Future<ApiResult<List<CartItem>>> getItems({required String token}) async => itemsResult;

  @override
  Future<ApiResult<void>> updateQuantity({
    required String token,
    required int itemId,
    required int quantity,
  }) async {
    final items = (itemsResult as Success<List<CartItem>>).data;
    itemsResult = Success([
      for (final item in items)
        if (item.id == itemId)
          CartItem(
            id: item.id,
            medicineName: item.medicineName,
            pharmacyId: item.pharmacyId,
            pharmacyName: item.pharmacyName,
            price: item.price,
            quantity: quantity,
          )
        else
          item,
    ]);
    return const Success(null);
  }
}

class _FakeSessionRepository implements SessionRepository {
  UserSession? savedSession = const UserSession(accountType: AccountType.patient, token: 'tok-1');

  @override
  Future<void> saveSession(UserSession session) async => savedSession = session;

  @override
  Future<UserSession?> getSession() async => savedSession;

  @override
  Future<void> clearSession() async => savedSession = null;
}

void main() {
  Future<void> setPhoneViewport(WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  final getIt = GetIt.instance;
  late _FakeCartRepository cartRepository;
  late _FakeSessionRepository sessionRepository;

  setUp(() {
    cartRepository = _FakeCartRepository();
    sessionRepository = _FakeSessionRepository();

    getIt.registerFactory<CartCubit>(
      () => CartCubit(
        GetCartItemsUseCase(cartRepository, sessionRepository),
        UpdateCartItemQuantityUseCase(cartRepository, sessionRepository),
        DeleteCartItemUseCase(cartRepository, sessionRepository),
        ClearCartUseCase(cartRepository, sessionRepository),
      ),
    );
  });

  tearDown(() => getIt.reset());

  Widget buildTestableScreen({List<String>? visitedRoutes, PickedLocation? pickedLocation}) {
    return ScreenUtilInit(
      designSize: const Size(440, 956),
      builder: (context, child) => MaterialApp(
        onGenerateRoute: (settings) {
          visitedRoutes?.add(settings.name ?? '');
          if (settings.name == Routes.locationPickerScreen) {
            return MaterialPageRoute<PickedLocation>(
              builder: (_) => Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => Navigator.of(context).pop(pickedLocation),
                    child: const Text('pick'),
                  ),
                ),
              ),
            );
          }
          if (settings.name == Routes.checkoutDetailsScreen) {
            return MaterialPageRoute<int>(builder: (_) => const Scaffold(body: SizedBox.shrink()));
          }
          return MaterialPageRoute(builder: (_) => const Scaffold(body: SizedBox.shrink()));
        },
        home: const PatientCartScreen(),
      ),
    );
  }

  testWidgets('shows the header, every line and the computed total', (tester) async {
    await setPhoneViewport(tester);

    await tester.pumpWidget(buildTestableScreen());
    await tester.pumpAndSettle();

    expect(find.text('السلة'), findsOneWidget);
    expect(find.textContaining('أموكسيسيلين'), findsOneWidget);
    expect(find.textContaining('باراسيتامول'), findsOneWidget);
    // 18*1 + 12*2 = 42
    expect(find.text('الاجمالي للمنتجات : 42 \$'), findsOneWidget);
  });

  testWidgets('shows the empty state and its browse button when the cart is empty',
      (tester) async {
    await setPhoneViewport(tester);
    cartRepository.itemsResult = const Success([]);
    final visitedRoutes = <String>[];

    await tester.pumpWidget(buildTestableScreen(visitedRoutes: visitedRoutes));
    await tester.pumpAndSettle();

    expect(find.text('سلتك فاضية'), findsOneWidget);
    expect(find.text('إتمام الطلب'), findsNothing);

    await tester.tap(find.text('تصفح الأقسام'));
    await tester.pumpAndSettle();

    expect(visitedRoutes, contains(Routes.allCategoriesScreen));
  });

  testWidgets('tapping + increments a line\'s quantity and the total', (tester) async {
    await setPhoneViewport(tester);

    await tester.pumpWidget(buildTestableScreen());
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();

    expect(find.text('2'), findsWidgets); // أموكسيسيلين's quantity is now 2
    // (18*2) + (12*2) = 60
    expect(find.text('الاجمالي للمنتجات : 60 \$'), findsOneWidget);
  });

  testWidgets('tapping - stops at a quantity of 1', (tester) async {
    await setPhoneViewport(tester);

    await tester.pumpWidget(buildTestableScreen());
    await tester.pumpAndSettle();
    // أموكسيسيلين already has quantity 1.
    await tester.tap(find.byIcon(Icons.remove).first);
    await tester.pumpAndSettle();

    expect(find.text('الاجمالي للمنتجات : 42 \$'), findsOneWidget);
  });




  testWidgets('tapping "إتمام الطلب" opens the checkout page with the cart lines',
      (tester) async {
    await setPhoneViewport(tester);
    cartRepository.itemsResult = const Success(_items);
    final visitedRoutes = <String>[];

    await tester.pumpWidget(buildTestableScreen(visitedRoutes: visitedRoutes));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إتمام الطلب'));
    await tester.pumpAndSettle();

    expect(visitedRoutes, contains(Routes.checkoutDetailsScreen));
  });

  testWidgets('a load failure shows the error with a working retry button', (tester) async {
    await setPhoneViewport(tester);
    cartRepository.itemsResult = const ApiError(NetworkFailure('تعذر الاتصال بالخادم'));

    await tester.pumpWidget(buildTestableScreen());
    await tester.pumpAndSettle();
    expect(find.text('تعذر الاتصال بالخادم'), findsOneWidget);

    cartRepository.itemsResult = const Success(_items);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();

    expect(find.textContaining('أموكسيسيلين'), findsOneWidget);
  });
}
