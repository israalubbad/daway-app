import 'package:daway_app/core/erroring/failure.dart';
import 'package:daway_app/core/helpers/api_result.dart';
import 'package:daway_app/core/models/picked_location.dart';
import 'package:daway_app/core/routing/routes.dart';
import 'package:daway_app/features/auth/domain/entities/account_type.dart';
import 'package:daway_app/features/auth/domain/entities/user_session.dart';
import 'package:daway_app/features/auth/domain/repositories/session_repository.dart';
import 'package:daway_app/features/patient/domain/entities/cart_item.dart';
import 'package:daway_app/features/patient/domain/entities/order.dart';
import 'package:daway_app/features/patient/domain/entities/patient_address.dart';
import 'package:daway_app/features/patient/domain/entities/patient_profile.dart';
import 'package:daway_app/features/patient/domain/repositories/orders_repository.dart';
import 'package:daway_app/features/patient/domain/repositories/patient_addresses_repository.dart';
import 'package:daway_app/features/patient/domain/repositories/patient_profile_repository.dart';
import 'package:daway_app/features/patient/domain/usecases/checkout_usecase.dart';
import 'package:daway_app/features/patient/domain/usecases/create_patient_address_usecase.dart';
import 'package:daway_app/features/patient/domain/usecases/get_patient_addresses_usecase.dart';
import 'package:daway_app/features/patient/domain/usecases/get_patient_profile_usecase.dart';
import 'package:daway_app/features/patient/presentation/cubit/checkout_cubit.dart';
import 'package:daway_app/features/patient/presentation/screens/checkout_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:daway_app/features/payment/domain/repositories/payment_repository.dart';
import 'package:daway_app/features/payment/domain/usecases/payment_usecases.dart';
import 'package:daway_app/features/payment/presentation/cubit/coupon_cubit.dart';
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

class _FakeAddressesRepository implements PatientAddressesRepository {

  @override
  Future<ApiResult<void>> deleteAddress({required String token, required int addressId}) async =>
      const Success(null);
  ApiResult<List<PatientAddress>> addressesResult = const Success([]);
  ApiResult<PatientAddress> createResult = const Success(_address);

  @override
  Future<ApiResult<List<PatientAddress>>> getAddresses({required String token}) async =>
      addressesResult;

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
  }) async =>
      createResult;

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
  }) async =>
      createResult;
}

class _FakeProfileRepository implements PatientProfileRepository {
  @override
  Future<ApiResult<PatientProfile>> getProfile({required String token}) async =>
      const Success(PatientProfile(name: 'مريض تجريبي', phone: '0599112233'));

  @override
  Future<ApiResult<void>> updateProfile({
    required String token,
    required PatientProfile profile,
  }) async =>
      const Success(null);
}

class _FakeOrdersRepository implements OrdersRepository {

  @override
  Future<ApiResult<void>> cancelOrder({required String token, required int orderId}) async =>
      const Success(null);
  ApiResult<int> checkoutResult = const Success(1);
  int? lastAddressId;

  @override
  Future<ApiResult<List<Order>>> getOrders({required String token}) async => const Success([]);

  @override
  Future<ApiResult<int>> checkout({
    required String token,
    required int addressId,
    String? couponCode,
    String? notes,
  }) async {
    lastAddressId = addressId;
    return checkoutResult;
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


class _FakePaymentRepository implements PaymentRepository {
  ApiResult<double> couponResult = const Success(4);
  String? lastCode;
  double? lastTotal;

  @override
  Future<ApiResult<double>> validateCoupon({
    required String token,
    required String code,
    required double orderTotal,
  }) async {
    lastCode = code;
    lastTotal = orderTotal;
    return couponResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Future<void> setPhoneViewport(WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  final getIt = GetIt.instance;
  late _FakeAddressesRepository addressesRepository;
  late _FakeOrdersRepository ordersRepository;
  late _FakePaymentRepository paymentRepository;
  late _FakeSessionRepository sessionRepository;

  setUp(() {
    addressesRepository = _FakeAddressesRepository();
    ordersRepository = _FakeOrdersRepository();
    paymentRepository = _FakePaymentRepository();
    sessionRepository = _FakeSessionRepository();

    getIt.registerFactory<CouponCubit>(
      () => CouponCubit(ValidateCouponUseCase(paymentRepository, sessionRepository)),
    );
    getIt.registerFactory<CheckoutCubit>(
      () => CheckoutCubit(
        GetPatientAddressesUseCase(addressesRepository, sessionRepository),
        CreatePatientAddressUseCase(addressesRepository, sessionRepository),
        GetPatientProfileUseCase(_FakeProfileRepository(), sessionRepository),
        CheckoutUseCase(ordersRepository, sessionRepository),
      ),
    );
  });

  tearDown(() => getIt.reset());

  /// The page is opened from a host route so the id it pops with can be read.
  Widget buildTestableScreen({
    List<String>? visitedRoutes,
    PickedLocation? pickedLocation,
    required ValueNotifier<int?> result,
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
          return MaterialPageRoute(builder: (_) => const Scaffold(body: SizedBox.shrink()));
        },
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result.value = await Navigator.of(context).push<int>(
                  MaterialPageRoute(
                    builder: (_) => const CheckoutDetailsScreen(items: _items),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> open(WidgetTester tester, Widget app) async {
    await setPhoneViewport(tester);
    await tester.pumpWidget(app);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the lines, the totals of the items and the pending delivery fee',
      (tester) async {
    await open(tester, buildTestableScreen(result: ValueNotifier(null)));

    expect(find.text('أكمل طلبك'), findsOneWidget);
    expect(find.text('سعر الطلبات : \$42'), findsOneWidget);
    expect(find.text('الإجمالي : \$42'), findsOneWidget);
    expect(find.textContaining('يُحسب بعد تأكيد الطلب'), findsOneWidget);
    expect(find.textContaining('12 \$/الشريط × 2 = 24 \$'), findsOneWidget);
  });

  testWidgets('"التالي" with a saved default address checks out and pops with the order id',
      (tester) async {
    addressesRepository.addressesResult = const Success([_address]);
    ordersRepository.checkoutResult = const Success(7);
    final result = ValueNotifier<int?>(null);
    await open(tester, buildTestableScreen(result: result));

    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();

    expect(ordersRepository.lastAddressId, 1);
    expect(result.value, 7);
  });

  testWidgets('with no saved address the patient picks one first, then the order is created',
      (tester) async {
    addressesRepository.addressesResult = const Success([]);
    const location = PickedLocation(latitude: 31.5, longitude: 34.47, address: 'غزة');
    final visitedRoutes = <String>[];
    final result = ValueNotifier<int?>(null);
    await open(
      tester,
      buildTestableScreen(visitedRoutes: visitedRoutes, pickedLocation: location, result: result),
    );

    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    expect(visitedRoutes, contains(Routes.locationPickerScreen));
    await tester.tap(find.text('pick'));
    await tester.pumpAndSettle();

    expect(ordersRepository.lastAddressId, 1);
    expect(result.value, 1);
  });

  testWidgets('a checkout failure shows its message and stays on the page', (tester) async {
    addressesRepository.addressesResult = const Success([_address]);
    ordersRepository.checkoutResult = const ApiError(ApiFailure(message: 'السلة فارغة'));
    final result = ValueNotifier<int?>(null);
    await open(tester, buildTestableScreen(result: result));

    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();

    expect(find.text('السلة فارغة'), findsOneWidget);
    expect(find.text('أكمل طلبك'), findsOneWidget);
    expect(result.value, isNull);
  });

  testWidgets('an accepted coupon shows the discount and lowers the total', (tester) async {
    await open(tester, buildTestableScreen(result: ValueNotifier(null)));

    await tester.enterText(find.byType(TextField), 'SAVE4');
    await tester.tap(find.text('تطبيق'));
    await tester.pumpAndSettle();

    expect(paymentRepository.lastCode, 'SAVE4');
    expect(paymentRepository.lastTotal, 42);
    expect(find.text('الخصم : \$4'), findsOneWidget);
    expect(find.text('الإجمالي : \$38'), findsOneWidget);
  });

  testWidgets('a rejected coupon shows the message and leaves the total alone', (tester) async {
    paymentRepository.couponResult = const ApiError(ValidationFailure('الكود منتهي'));
    await open(tester, buildTestableScreen(result: ValueNotifier(null)));

    await tester.enterText(find.byType(TextField), 'OLD');
    await tester.tap(find.text('تطبيق'));
    await tester.pumpAndSettle();

    expect(find.text('الكود منتهي'), findsOneWidget);
    expect(find.text('الإجمالي : \$42'), findsOneWidget);
  });

  testWidgets('pickup from the pharmacy answers "قريباً"', (tester) async {
    await open(tester, buildTestableScreen(result: ValueNotifier(null)));

    await tester.tap(find.text('استلام من الصيدلية'));
    await tester.pump();

    expect(find.text('قريباً'), findsOneWidget);
  });
}
