import 'package:daway_app/core/erroring/failure.dart';
import 'package:daway_app/core/helpers/api_result.dart';
import 'package:daway_app/features/patient/domain/entities/cart_item.dart';
import 'package:daway_app/features/patient/domain/entities/checkout_quote.dart';
import 'package:daway_app/features/patient/domain/usecases/checkout_flow_usecases.dart';
import 'package:daway_app/features/patient/domain/usecases/checkout_usecase.dart';
import 'package:daway_app/features/patient/domain/usecases/get_checkout_quote_usecase.dart';
import 'package:daway_app/features/patient/domain/usecases/create_patient_address_usecase.dart';
import 'package:daway_app/features/patient/domain/usecases/get_patient_addresses_usecase.dart';
import 'package:daway_app/features/patient/domain/usecases/get_patient_profile_usecase.dart';
import 'package:daway_app/features/patient/presentation/cubit/checkout_cubit.dart';
import 'package:daway_app/features/patient/presentation/cubit/order_tracking_cubit.dart';
import 'package:daway_app/features/patient/presentation/cubit/payment_cubit.dart';
import 'package:daway_app/features/patient/presentation/screens/checkout_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../../checkout_test_fakes.dart';

const _items = [
  CartItem(
    id: 1,
    medicineName: 'أموكسيسيلين',
    pharmacyId: 11,
    pharmacyName: 'صيدلية الشفاء',
    price: 18,
    quantity: 1,
  ),
  CartItem(
    id: 2,
    medicineName: 'باراسيتامول',
    pharmacyId: 11,
    pharmacyName: 'صيدلية الشفاء',
    price: 12,
    quantity: 2,
  ),
];

void main() {
  final getIt = GetIt.instance;
  late FakeAddressesRepository addresses;
  late FakeOrdersRepository orders;
  late FakeCheckoutFlowRepository flow;

  setUp(() {
    addresses = FakeAddressesRepository();
    orders = FakeOrdersRepository();
    flow = FakeCheckoutFlowRepository();
    final session = FakeSessionRepository();

    getIt.registerFactoryParam<CheckoutCubit, double, void>(
      (subtotal, _) => CheckoutCubit(
        subtotal,
        GetPatientAddressesUseCase(addresses, session),
        CreatePatientAddressUseCase(addresses, session),
        GetPatientProfileUseCase(FakeProfileRepository(), session),
        ValidateCouponUseCase(flow, session),
        CheckoutUseCase(orders, session),
        GetCheckoutQuoteUseCase(orders, session),
      ),
    );
    getIt.registerFactoryParam<PaymentCubit, int, void>(
      (orderId, _) => PaymentCubit(
        orderId,
        GetOrderPaymentUseCase(flow, session),
        SubmitPaymentReceiptUseCase(flow, session),
        ReportPaymentProblemUseCase(flow, session),
        GetOrderTrackingUseCase(flow, session),
      ),
    );
    getIt.registerFactoryParam<OrderTrackingCubit, int, void>(
      (orderId, _) => OrderTrackingCubit(
        orderId,
        GetOrderTrackingUseCase(flow, session),
        GetOrderPaymentUseCase(flow, session),
      ),
    );
  });

  tearDown(() => getIt.reset());

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(440, 956),
        builder: (context, child) => const MaterialApp(home: CheckoutScreen(items: _items)),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('shows delivery, the default address, the order lines and the totals',
      (tester) async {
    await open(tester);

    expect(find.text('أكمل طلبك'), findsOneWidget);
    expect(find.text('التوصيل'), findsOneWidget);
    expect(find.text('دليفري'), findsOneWidget);
    expect(find.text('استلام من الصيدلية'), findsNothing);
    expect(find.text('غزة - الرمال'), findsOneWidget);
    expect(find.text('ملخص الطلب'), findsOneWidget);
    expect(find.textContaining('أموكسيسيلين'), findsOneWidget);
    // 18*1 + 12*2 = 42
    expect(find.text('سعر الطلبات : 42 \$'), findsOneWidget);
    expect(find.text('دليفري : يحدده الأدمن بعد إرسال الطلب'), findsOneWidget);
    expect(find.text('الاجمالي : 42 \$'), findsOneWidget);
  });

  testWidgets('an accepted coupon shows its discount and lowers the total', (tester) async {
    await open(tester);

    await tester.enterText(find.byType(TextField), 'SAVE4');
    await tester.tap(find.text('تطبيق'));
    await tester.pumpAndSettle();

    expect(flow.lastCoupon, 'SAVE4');
    expect(find.text('الخصم : 4 \$'), findsOneWidget);
    expect(find.text('الاجمالي : 38 \$'), findsOneWidget);
    expect(find.text('إزالة'), findsOneWidget);
  });

  testWidgets('a rejected coupon says why and changes nothing', (tester) async {
    flow.couponResult = const ApiError(ApiFailure(message: 'الكود منتهي'));
    await open(tester);

    await tester.enterText(find.byType(TextField), 'OLD');
    await tester.tap(find.text('تطبيق'));
    await tester.pumpAndSettle();

    expect(find.text('الكود منتهي'), findsOneWidget);
    expect(find.text('الاجمالي : 42 \$'), findsOneWidget);
  });

  testWidgets('"التالي" without an address asks for one and creates no order', (tester) async {
    addresses.addressesResult = const Success([]);
    await open(tester);

    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();

    expect(find.text('اختر عنوان التوصيل أولاً'), findsOneWidget);
    expect(orders.lastAddressId, isNull);
  });

  testWidgets('"التالي" creates the order and opens the payment of that order', (tester) async {
    await open(tester);

    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();

    expect(orders.lastAddressId, testAddress.id);
    expect(find.text('طريقة الدفع'), findsOneWidget);
    expect(find.text('بنك فلسطين'), findsOneWidget);
    // The cart and this screen are gone: nothing to go back to but the home.
    expect(find.text('ملخص الطلب'), findsNothing);
  });

  testWidgets('the order is created with the coupon that was accepted', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextField), 'SAVE4');
    await tester.tap(find.text('تطبيق'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();

    expect(orders.lastCouponCode, 'SAVE4');
  });

  testWidgets('a refused order shows the server message and stays on the screen',
      (tester) async {
    orders.checkoutResult = const ApiError(ApiFailure(message: 'السلة فارغة'));
    await open(tester);

    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();

    expect(find.text('السلة فارغة'), findsOneWidget);
    expect(find.text('ملخص الطلب'), findsOneWidget);
  });

  group('with the server delivery quote', () {
    const quote = CheckoutQuote(
      subtotal: 42,
      discount: 0,
      total: 42,
      deliveryFee: 9,
      grandTotal: 51,
    );

    testWidgets('shows the delivery fee and the grand total that includes it', (tester) async {
      orders.quoteResult = const Success(quote);

      await open(tester);

      expect(find.text('سعر الطلبات : 42 \$'), findsOneWidget);
      expect(find.text('دليفري : 9 \$'), findsOneWidget);
      expect(find.text('الاجمالي : 51 \$'), findsOneWidget);
      expect(find.text('دليفري : يحدده الأدمن بعد إرسال الطلب'), findsNothing);
    });

    testWidgets('an accepted coupon is priced by the server', (tester) async {
      orders.quoteResult = const Success(quote);
      await open(tester);
      orders.quoteResult = const Success(
        CheckoutQuote(subtotal: 42, discount: 4, total: 38, deliveryFee: 9, grandTotal: 47),
      );

      await tester.enterText(find.byType(TextField), 'SAVE4');
      await tester.tap(find.text('تطبيق'));
      await tester.pumpAndSettle();

      expect(find.text('الخصم : 4 \$'), findsOneWidget);
      expect(find.text('الاجمالي : 47 \$'), findsOneWidget);
    });

    testWidgets('the order is created with the quote the patient saw', (tester) async {
      orders.quoteResult = const Success(quote);
      await open(tester);

      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();

      expect(orders.lastQuote, quote);
      expect(orders.lastIdempotencyKey, isNotNull);
    });

    testWidgets('a price that moved is explained and the new total is shown', (tester) async {
      orders.quoteResult = const Success(quote);
      orders.checkoutResult = const ApiError(
        ApiFailure(message: 'quote_changed', code: 'quote_changed', statusCode: 409),
      );
      await open(tester);
      orders.quoteResult = const Success(
        CheckoutQuote(subtotal: 42, discount: 0, total: 42, deliveryFee: 15, grandTotal: 57),
      );

      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();

      expect(find.text(quoteChangedMessage), findsOneWidget);
      expect(find.text('دليفري : 15 \$'), findsOneWidget);
      expect(find.text('الاجمالي : 57 \$'), findsOneWidget);
      expect(find.text('ملخص الطلب'), findsOneWidget);
    });

    testWidgets('a quote that could not be read says so and can be retried', (tester) async {
      orders.quoteResult = const ApiError(ApiFailure(message: 'تعذر الاتصال', statusCode: 500));
      await open(tester);
      const failedLine = 'دليفري : تعذر حساب الرسوم، اضغط لإعادة المحاولة';
      expect(find.text(failedLine), findsOneWidget);

      orders.quoteResult = const Success(quote);
      await tester.tap(find.text(failedLine));
      await tester.pumpAndSettle();

      expect(find.text(failedLine), findsNothing);
      expect(find.text('دليفري : 9 \$'), findsOneWidget);
      expect(find.text('الاجمالي : 51 \$'), findsOneWidget);
    });
  });
}
