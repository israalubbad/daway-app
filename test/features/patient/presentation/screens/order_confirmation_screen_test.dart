import 'package:daway_app/core/erroring/failure.dart';
import 'package:daway_app/core/helpers/api_result.dart';
import 'package:daway_app/features/patient/domain/entities/order.dart';
import 'package:daway_app/features/patient/domain/usecases/checkout_flow_usecases.dart';
import 'package:daway_app/features/patient/presentation/cubit/order_tracking_cubit.dart';
import 'package:daway_app/features/patient/presentation/screens/order_confirmation_screen.dart';
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
          home: OrderConfirmationScreen(orderId: 11, pharmacyName: 'صيدلية الشفاء'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  int doneSteps() => find.byIcon(Icons.check).evaluate().length;

  /// Every stage of an order's life, with and without the admin's approval of
  /// the transfer: which chip shows and how many steps are ticked.
  final stages = <(String, OrderStatus, String, bool, String, int)>[
    ('a new unpaid order', OrderStatus.pending, 'pending', false, 'بانتظار تأكيد الدفع', 0),
    ('a paid order the pharmacy has not accepted', OrderStatus.pending, 'approved', true,
        'قيد المراجعة', 0),
    ('confirmed but the transfer is not approved', OrderStatus.confirmed, 'under_review', false,
        'بانتظار تأكيد الدفع', 0),
    ('confirmed with the transfer approved', OrderStatus.confirmed, 'approved', true, 'تم التأكيد', 1),
    ('being prepared', OrderStatus.preparing, 'approved', true, 'قيد التجهيز', 2),
    ('on the way', OrderStatus.outForDelivery, 'approved', true, 'في الطريق', 3),
    ('delivered', OrderStatus.delivered, 'approved', true, 'تم التسليم', 4),
    ('cancelled', OrderStatus.cancelled, 'approved', true, 'ملغي', 0),
  ];

  for (final (name, status, paymentStatus, _, chip, ticked) in stages) {
    testWidgets('$name shows "$chip" with $ticked step(s) done', (tester) async {
      repository.trackingResult = Success(testTracking(status));
      repository.paymentResult = Success(testPayment(paymentStatus: paymentStatus));

      await open(tester);

      expect(find.text(chip), findsOneWidget);
      expect(doneSteps(), ticked);
      expect(find.text('طلب #11'), findsOneWidget);
      expect(find.text('صيدلية الشفاء'), findsOneWidget);
    });
  }

  testWidgets('shows the time the order was confirmed on its step', (tester) async {
    repository.trackingResult = Success(testTracking(OrderStatus.confirmed));
    repository.paymentResult = Success(testPayment(paymentStatus: 'approved'));

    await open(tester);

    expect(find.text('3:36 م'), findsOneWidget);
  });

  testWidgets('a tracking failure shows the error with a working retry', (tester) async {
    repository.trackingResult = const ApiError(NetworkFailure('تعذر الاتصال بالخادم'));

    await open(tester);
    expect(find.text('تعذر الاتصال بالخادم'), findsOneWidget);

    repository.trackingResult = Success(testTracking(OrderStatus.confirmed));
    repository.paymentResult = Success(testPayment(paymentStatus: 'approved'));
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();

    expect(find.text('تعذر الاتصال بالخادم'), findsNothing);
    expect(find.text('تم التأكيد'), findsOneWidget);
  });

  testWidgets('an unreadable payment does not hide the order status', (tester) async {
    repository.trackingResult = Success(testTracking(OrderStatus.preparing));
    repository.paymentResult = const ApiError(NetworkFailure('تعذر الاتصال'));

    await open(tester);

    expect(find.text('قيد التجهيز'), findsOneWidget);
    expect(doneSteps(), 2);
  });

  testWidgets('has the notify and back-home buttons', (tester) async {
    await open(tester);

    expect(find.text('نبّهني عند اقتراب الطلب'), findsOneWidget);
    expect(find.text('العودة للرئيسية'), findsOneWidget);
  });
}
