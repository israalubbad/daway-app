import 'package:daway_app/core/erroring/failure.dart';
import 'package:daway_app/core/helpers/api_result.dart';
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

  /// Opens the payment screen and goes on to the receipt screen with [bank].
  Future<void> openReceipt(WidgetTester tester, {String bank = 'بنك فلسطين'}) async {
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
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
    });
    await tester.tap(find.text(bank));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ادفع 150 \$'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the chosen method and the upload area', (tester) async {
    await openReceipt(tester, bank: 'محفظة Jawwal Pay');

    expect(find.text('طريقة الدفع المختارة'), findsOneWidget);
    expect(find.text('محفظة Jawwal Pay'), findsOneWidget);
    expect(find.text('رفع إشعار الدفع'), findsOneWidget);
    expect(find.text('اضغط لرفع إشعار التحويل'), findsOneWidget);
    expect(find.text('لديك مشكلة في رفع الإشعار؟'), findsOneWidget);
  });

  testWidgets('completing without a picture asks for one and sends nothing', (tester) async {
    await openReceipt(tester);

    await tester.tap(find.text('إتمام الطلب'));
    await tester.pumpAndSettle();

    expect(find.text('ارفع صورة إشعار التحويل أولاً'), findsOneWidget);
    expect(repository.receiptBankId, isNull);
  });

  testWidgets('"لديك مشكلة" swaps the upload for the manual transfer fields', (tester) async {
    await openReceipt(tester);

    await tester.tap(find.text('لديك مشكلة في رفع الإشعار؟'));
    await tester.pumpAndSettle();

    expect(find.text('اكتب بيانات التحويل لإتمام الطلب'), findsOneWidget);
    expect(find.text('اسم البنك'), findsOneWidget);
    expect(find.text('اسم صاحب الحساب'), findsOneWidget);
    expect(find.text('المبلغ'), findsOneWidget);
    expect(find.text('اضغط لرفع إشعار التحويل'), findsNothing);
  });

  testWidgets('incomplete manual details are refused', (tester) async {
    await openReceipt(tester);
    await tester.tap(find.text('لديك مشكلة في رفع الإشعار؟'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('إتمام الطلب'));
    await tester.pumpAndSettle();

    expect(find.text('أكمل بيانات التحويل أولاً'), findsOneWidget);
    expect(repository.problemMessage, isNull);
  });

  testWidgets('complete manual details are handed over and the status screen opens',
      (tester) async {
    await openReceipt(tester);
    await tester.tap(find.text('لديك مشكلة في رفع الإشعار؟'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('اختر البنك'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('بنك فلسطين').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'أدخل اسم صاحب الحساب'), 'عبود');
    await tester.enterText(find.widgetWithText(TextField, 'أدخل مبلغ التحويل'), '150');
    await tester.tap(find.text('إتمام الطلب'));
    await tester.pumpAndSettle();

    expect(repository.problemMessage, contains('بنك فلسطين'));
    expect(repository.problemMessage, contains('عبود'));
    expect(repository.problemMessage, contains('150'));
    expect(find.text('تابع حالة طلبك من هنا.'), findsOneWidget);
  });

  testWidgets('a refused report shows the server message and stays here', (tester) async {
    repository.problemResult = const ApiError(ApiFailure(message: 'رقم الإشعار مطلوب'));
    await openReceipt(tester);
    await tester.tap(find.text('لديك مشكلة في رفع الإشعار؟'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('اختر البنك'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('بنك فلسطين').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'أدخل اسم صاحب الحساب'), 'عبود');
    await tester.enterText(find.widgetWithText(TextField, 'أدخل مبلغ التحويل'), '150');
    await tester.tap(find.text('إتمام الطلب'));
    await tester.pumpAndSettle();

    expect(find.text('رقم الإشعار مطلوب'), findsOneWidget);
    expect(find.text('تابع حالة طلبك من هنا.'), findsNothing);
  });
}
