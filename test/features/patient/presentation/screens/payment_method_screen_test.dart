import 'package:daway_app/core/helpers/api_result.dart';
import 'package:daway_app/features/patient/domain/entities/order.dart';
import 'package:daway_app/features/patient/domain/usecases/checkout_flow_usecases.dart';
import 'package:daway_app/features/patient/presentation/cubit/order_tracking_cubit.dart';
import 'package:daway_app/features/patient/presentation/cubit/payment_cubit.dart';
import 'package:daway_app/features/patient/presentation/screens/payment_method_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../../checkout_test_fakes.dart';

void main() {
  final getIt = GetIt.instance;
  late FakeCheckoutFlowRepository repository;

  setUp(() {
    repository = FakeCheckoutFlowRepository();
    final session = FakeSessionRepository();
    getIt.registerFactoryParam<PaymentCubit, int, void>(
      (orderId, _) => PaymentCubit(
        orderId,
        GetOrderPaymentUseCase(repository, session),
        SubmitPaymentReceiptUseCase(repository, session),
        ReportPaymentProblemUseCase(repository, session),
        GetOrderTrackingUseCase(repository, session),
      ),
    );
    getIt.registerFactoryParam<OrderTrackingCubit, int, void>(
      (orderId, _) => OrderTrackingCubit(
        orderId,
        GetOrderTrackingUseCase(repository, session),
        GetOrderPaymentUseCase(repository, session),
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
        builder: (context, child) => const MaterialApp(
          home: PaymentMethodScreen(orderId: 11, pharmacyName: 'صيدلية الشفاء'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // The screen polls while it waits for the admin; end the test without the
    // timer still running.
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('lists the banks with the delivery price and the total before paying',
      (tester) async {
    await open(tester);

    expect(find.text('بنك فلسطين'), findsOneWidget);
    expect(find.text('محفظة PalPay'), findsOneWidget);
    expect(find.text('محفظة Jawwal Pay'), findsOneWidget);
    expect(find.text('0597601911'), findsNWidgets(3));
    expect(find.text('سعر التوصيل : 15 \$'), findsOneWidget);
    expect(find.text('الإجمالي : 150 \$'), findsOneWidget);
    expect(find.text('ادفع 150 \$'), findsOneWidget);
  });

  testWidgets('nothing can be paid until the admin has set the delivery price', (tester) async {
    repository.paymentResult = Success(
      testPayment(deliveryFee: null, awaitingDeliveryFee: true),
    );

    await open(tester);

    expect(find.text('بانتظار موافقة الأدمن'), findsOneWidget);
    expect(find.text('بنك فلسطين'), findsNothing);
    expect(find.textContaining('ادفع'), findsNothing);
    expect(find.text('تحديث'), findsOneWidget);
  });

  testWidgets('a pending order waits for the admin even with a delivery price', (tester) async {
    repository.trackingResult = Success(testTracking(OrderStatus.pending));

    await open(tester);

    expect(find.text('بانتظار موافقة الأدمن'), findsOneWidget);
    expect(find.text('بنك فلسطين'), findsNothing);
  });

  testWidgets('the waiting screen opens up when the admin has priced the order', (tester) async {
    repository.paymentResult = Success(
      testPayment(deliveryFee: null, awaitingDeliveryFee: true),
    );
    await open(tester);
    expect(find.text('بانتظار موافقة الأدمن'), findsOneWidget);

    repository.paymentResult = Success(testPayment(deliveryFee: 20, grandTotal: 70));
    await tester.tap(find.text('تحديث'));
    await tester.pumpAndSettle();

    expect(find.text('بانتظار موافقة الأدمن'), findsNothing);
    expect(find.text('سعر التوصيل : 20 \$'), findsOneWidget);
    expect(find.text('ادفع 70 \$'), findsOneWidget);
  });

  testWidgets('an order that is already paid goes straight to its status', (tester) async {
    repository.paymentResult = Success(
      testPayment(paymentStatus: 'approved', canSubmitReceipt: false, deliveryFee: null),
    );

    await open(tester);

    expect(find.text('تابع حالة طلبك من هنا.'), findsOneWidget);
    expect(find.text('طلب #11'), findsOneWidget);
    expect(find.text('بنك فلسطين'), findsNothing);
  });

  testWidgets('a receipt already under review goes straight to the status too', (tester) async {
    repository.paymentResult = Success(
      testPayment(paymentStatus: 'under_review', canSubmitReceipt: false),
    );

    await open(tester);

    expect(find.text('تابع حالة طلبك من هنا.'), findsOneWidget);
  });

  testWidgets('"ادفع" goes on to the receipt upload with the chosen bank', (tester) async {
    await open(tester);

    await tester.tap(find.text('محفظة PalPay'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ادفع 150 \$'));
    await tester.pumpAndSettle();

    expect(find.text('ارفع اشعار التحويل'), findsOneWidget);
    expect(find.text('محفظة PalPay'), findsOneWidget);
    expect(find.text('اضغط لرفع إشعار التحويل'), findsOneWidget);
  });
}
