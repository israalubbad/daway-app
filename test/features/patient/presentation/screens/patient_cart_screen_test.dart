import 'package:daway_app/core/erroring/failure.dart';
import 'package:daway_app/core/helpers/api_result.dart';
import 'package:daway_app/core/models/picked_location.dart';
import 'package:daway_app/core/routing/routes.dart';
import 'package:daway_app/features/patient/domain/entities/cart_item.dart';
import 'package:daway_app/features/patient/domain/entities/checkout_flow.dart';
import 'package:daway_app/features/patient/domain/repositories/checkout_flow_repository.dart';
import 'package:daway_app/features/patient/domain/usecases/checkout_flow_usecases.dart';
import 'package:daway_app/features/patient/domain/entities/checkout_quote.dart';
import 'package:daway_app/features/patient/domain/entities/order.dart';
import 'package:daway_app/features/patient/domain/entities/patient_address.dart';
import 'package:daway_app/features/patient/domain/entities/patient_profile.dart';
import 'package:daway_app/features/patient/domain/repositories/cart_repository.dart';
import 'package:daway_app/features/patient/domain/repositories/orders_repository.dart';
import 'package:daway_app/features/patient/domain/repositories/patient_addresses_repository.dart';
import 'package:daway_app/features/patient/domain/repositories/patient_profile_repository.dart';
import 'package:daway_app/features/patient/domain/usecases/checkout_usecase.dart';
import 'package:daway_app/features/patient/domain/usecases/get_checkout_quote_usecase.dart';
import 'package:daway_app/features/patient/domain/usecases/create_patient_address_usecase.dart';
import 'package:daway_app/features/patient/domain/usecases/clear_cart_usecase.dart';
import 'package:daway_app/features/patient/domain/usecases/delete_cart_item_usecase.dart';
import 'package:daway_app/features/patient/domain/usecases/get_cart_items_usecase.dart';
import 'package:daway_app/features/patient/domain/usecases/get_patient_addresses_usecase.dart';
import 'package:daway_app/features/patient/domain/usecases/get_patient_profile_usecase.dart';
import 'package:daway_app/features/patient/domain/usecases/update_cart_item_quantity_usecase.dart';
import 'package:daway_app/features/patient/presentation/cubit/cart_cubit.dart';
import 'package:daway_app/features/patient/presentation/cubit/checkout_cubit.dart';
import 'package:daway_app/features/patient/presentation/screens/patient_cart_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import '../../../../helpers/in_memory_session_repository.dart';

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

const _samePharmacyItems = [
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
    pharmacyId: 11,
    pharmacyName: 'صيدلية النور',
    price: 12,
    quantity: 2,
  ),
];

const _address = PatientAddress(
  id: 1,
  label: 'المنزل',
  recipientName: 'مريض تجريبي',
  phone: '0599112233',
  address: 'غزة',
  latitude: 31.5,
  longitude: 34.47,
  isDefault: true,
);

class _FakeCartRepository implements CartRepository {
  final List<int> deletedItemIds = [];

  @override
  Future<ApiResult<void>> deleteItem({
    required String token,
    required int itemId,
  }) async {
    deletedItemIds.add(itemId);
    return const Success(null);
  }

  @override
  Future<ApiResult<void>> clearCart({required String token}) async =>
      const Success(null);

  @override
  Future<ApiResult<void>> addItem({
    required String token,
    int? pharmacyMedicineId,
    required int pharmacyId,
    required int medicineId,
    required int quantity,
  }) async => const Success(null);
  ApiResult<List<CartItem>> itemsResult = const Success(_items);

  @override
  Future<ApiResult<List<CartItem>>> getItems({required String token}) async =>
      itemsResult;

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

class _FakeAddressesRepository implements PatientAddressesRepository {
  @override
  Future<ApiResult<void>> deleteAddress({
    required String token,
    required int addressId,
  }) async => const Success(null);
  ApiResult<List<PatientAddress>> addressesResult = const Success([]);
  ApiResult<PatientAddress> createResult = const Success(_address);

  @override
  Future<ApiResult<List<PatientAddress>>> getAddresses({
    required String token,
  }) async => addressesResult;

  @override
  Future<ApiResult<PatientAddress>> createAddress({
    required String token,
    required String label,
    required String recipientName,
    required String phone,
    required String address,
    required double latitude,
    required double longitude,
    bool isDefault = true,
  }) async => createResult;

  @override
  Future<ApiResult<PatientAddress>> updateAddress({
    required String token,
    required int addressId,
    required String label,
    required String recipientName,
    required String phone,
    required String address,
    required double latitude,
    required double longitude,
    required bool isDefault,
  }) async => createResult;
}

class _FakeProfileRepository implements PatientProfileRepository {
  @override
  Future<ApiResult<PatientProfile>> getProfile({required String token}) async =>
      const Success(PatientProfile(name: 'مريض تجريبي', phone: '0599112233'));

  @override
  Future<ApiResult<void>> updateProfile({
    required String token,
    required PatientProfile profile,
  }) async => const Success(null);
}

class _FakeOrdersRepository implements OrdersRepository {
  /// What the quote call answers. By default delivery pricing is off (the
  /// server answers 422), so a flow that does not care about the quote runs
  /// without one.
  ApiResult<CheckoutQuote> quoteResult =
      const ApiError(ApiFailure(message: 'pricing off', statusCode: 422));
  int quoteCallCount = 0;
  String? lastQuoteCouponCode;
  CheckoutQuote? lastQuote;
  String? lastIdempotencyKey;

  @override
  Future<ApiResult<void>> cancelOrder({
    required String token,
    required int orderId,
  }) async => const Success(null);
  ApiResult<int> checkoutResult = const Success(1);
  int? lastAddressId;

  @override
  Future<ApiResult<List<Order>>> getOrders({required String token}) async =>
      const Success([]);

  @override
  Future<ApiResult<CheckoutQuote>> getCheckoutQuote({
    required String token,
    required int addressId,
    String? couponCode,
  }) async {
    quoteCallCount++;
    lastQuoteCouponCode = couponCode;
    return quoteResult;
  }

  @override
  Future<ApiResult<int>> checkout({
    required String token,
    required int addressId,
    String? couponCode,
    String? notes,
    CheckoutQuote? quote,
    String? idempotencyKey,
  }) async {
    lastQuote = quote;
    lastIdempotencyKey = idempotencyKey;
    lastAddressId = addressId;
    return checkoutResult;
  }
}

class _FakeCheckoutFlowRepository implements CheckoutFlowRepository {
  @override
  Future<ApiResult<double>> validateCoupon({
    required String token,
    required String code,
    required double orderTotal,
  }) async => const Success(0);

  @override
  Future<ApiResult<OrderPayment>> getPayment({
    required String token,
    required int orderId,
  }) => throw UnimplementedError();

  @override
  Future<ApiResult<void>> submitReceipt({
    required String token,
    required int orderId,
    required int bankId,
    required double amount,
    required String receiptPath,
  }) => throw UnimplementedError();

  @override
  Future<ApiResult<void>> reportProblem({
    required String token,
    required int orderId,
    required String message,
  }) => throw UnimplementedError();

  @override
  Future<ApiResult<OrderTracking>> getTracking({
    required String token,
    required int orderId,
  }) => throw UnimplementedError();
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
  late _FakeAddressesRepository addressesRepository;
  late _FakeOrdersRepository ordersRepository;
  late InMemorySessionRepository sessionRepository;

  setUp(() {
    cartRepository = _FakeCartRepository();
    addressesRepository = _FakeAddressesRepository();
    ordersRepository = _FakeOrdersRepository();
    sessionRepository = InMemorySessionRepository.patient();

    getIt.registerFactory<CartCubit>(
      () => CartCubit(
        GetCartItemsUseCase(cartRepository, sessionRepository),
        UpdateCartItemQuantityUseCase(cartRepository, sessionRepository),
        DeleteCartItemUseCase(cartRepository, sessionRepository),
        ClearCartUseCase(cartRepository, sessionRepository),
      ),
    );
    getIt.registerFactoryParam<CheckoutCubit, double, void>(
      (subtotal, _) => CheckoutCubit(
        subtotal,
        GetPatientAddressesUseCase(addressesRepository, sessionRepository),
        CreatePatientAddressUseCase(addressesRepository, sessionRepository),
        GetPatientProfileUseCase(_FakeProfileRepository(), sessionRepository),
        ValidateCouponUseCase(_FakeCheckoutFlowRepository(), sessionRepository),
        CheckoutUseCase(ordersRepository, sessionRepository),
        GetCheckoutQuoteUseCase(ordersRepository, sessionRepository),
      ),
    );
  });

  tearDown(() => getIt.reset());

  Widget buildTestableScreen({
    List<String>? visitedRoutes,
    PickedLocation? pickedLocation,
  }) {
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
          return MaterialPageRoute(
            builder: (_) => const Scaffold(body: SizedBox.shrink()),
          );
        },
        home: const PatientCartScreen(),
      ),
    );
  }

  testWidgets('shows the header, every line and the computed total', (
    tester,
  ) async {
    await setPhoneViewport(tester);

    await tester.pumpWidget(buildTestableScreen());
    await tester.pumpAndSettle();

    expect(find.text('السلة'), findsOneWidget);
    expect(find.textContaining('أموكسيسيلين'), findsOneWidget);
    expect(find.textContaining('باراسيتامول'), findsOneWidget);
    // 18*1 + 12*2 = 42
    expect(find.text('الاجمالي للمنتجات : 42 \$'), findsOneWidget);
  });

  testWidgets(
    'shows the empty state and its browse button when the cart is empty',
    (tester) async {
      await setPhoneViewport(tester);
      cartRepository.itemsResult = const Success([]);
      final visitedRoutes = <String>[];

      await tester.pumpWidget(
        buildTestableScreen(visitedRoutes: visitedRoutes),
      );
      await tester.pumpAndSettle();

      expect(find.text('سلتك فاضية'), findsOneWidget);
      expect(find.text('إتمام الطلب'), findsNothing);

      await tester.tap(find.text('تصفح الأقسام'));
      await tester.pumpAndSettle();

      expect(visitedRoutes, contains(Routes.allCategoriesScreen));
    },
  );

  testWidgets('tapping + increments a line\'s quantity and the total', (
    tester,
  ) async {
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

  testWidgets('a cart with one pharmacy goes straight to "أكمل طلبك"', (
    tester,
  ) async {
    await setPhoneViewport(tester);
    cartRepository.itemsResult = const Success(_samePharmacyItems);
    addressesRepository.addressesResult = const Success([_address]);

    await tester.pumpWidget(buildTestableScreen());
    await tester.pumpAndSettle();
    await tester.tap(find.text('إتمام الطلب'));
    await tester.pumpAndSettle();

    expect(find.text('اختر صيدلية واحدة'), findsNothing);
    expect(find.text('أكمل طلبك'), findsOneWidget);
    // 18*1 + 12*2 = 42
    expect(find.text('سعر الطلبات : 42 \$'), findsOneWidget);
  });

  testWidgets(
    'a cart spanning pharmacies asks which one to order from, and drops the others',
    (tester) async {
      await setPhoneViewport(tester);
      addressesRepository.addressesResult = const Success([_address]);

      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();
      await tester.tap(find.text('إتمام الطلب'));
      await tester.pumpAndSettle();

      expect(find.text('اختر صيدلية واحدة'), findsOneWidget);
      expect(find.text('صيدلية النور'), findsOneWidget);
      expect(find.text('صيدلية الأمل'), findsOneWidget);

      await tester.tap(find.text('صيدلية الأمل'));
      await tester.tap(find.text('متابعة'));
      await tester.pumpAndSettle();

      // The line of the other pharmacy (id 1, النور) is removed from the cart.
      expect(cartRepository.deletedItemIds, [1]);
      expect(find.text('أكمل طلبك'), findsOneWidget);
      // Only the kept pharmacy's line is ordered: 12*2.
      expect(find.text('سعر الطلبات : 24 \$'), findsOneWidget);
    },
  );

  testWidgets('backing out of the pharmacy choice leaves the cart untouched', (
    tester,
  ) async {
    await setPhoneViewport(tester);

    await tester.pumpWidget(buildTestableScreen());
    await tester.pumpAndSettle();
    await tester.tap(find.text('إتمام الطلب'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();

    expect(cartRepository.deletedItemIds, isEmpty);
    expect(find.text('أكمل طلبك'), findsNothing);
    expect(find.text('السلة'), findsOneWidget);
  });

  testWidgets('a load failure shows the error with a working retry button', (
    tester,
  ) async {
    await setPhoneViewport(tester);
    cartRepository.itemsResult = const ApiError(
      NetworkFailure('تعذر الاتصال بالخادم'),
    );

    await tester.pumpWidget(buildTestableScreen());
    await tester.pumpAndSettle();
    expect(find.text('تعذر الاتصال بالخادم'), findsOneWidget);

    cartRepository.itemsResult = const Success(_items);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();

    expect(find.textContaining('أموكسيسيلين'), findsOneWidget);
  });
}
