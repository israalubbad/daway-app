import 'dart:io';

import 'package:daway_app/core/helpers/api_result.dart';
import 'package:daway_app/core/routing/routes.dart';
import 'package:daway_app/features/auth/domain/entities/account_type.dart';
import 'package:daway_app/features/auth/domain/entities/user_session.dart';
import 'package:daway_app/features/auth/domain/repositories/session_repository.dart';
import 'package:daway_app/features/patient/domain/entities/patient_profile.dart';
import 'package:daway_app/features/patient/domain/repositories/patient_profile_repository.dart';
import 'package:daway_app/features/patient/domain/usecases/get_patient_profile_usecase.dart';
import 'package:daway_app/features/payment/domain/entities/payment.dart';
import 'package:daway_app/features/payment/domain/repositories/payment_repository.dart';
import 'package:daway_app/features/payment/domain/usecases/payment_usecases.dart';
import 'package:daway_app/features/payment/presentation/cubit/payment_cubit.dart';
import 'package:daway_app/features/payment/presentation/cubit/tracking_cubit.dart';
import 'package:daway_app/features/payment/presentation/screens/order_tracking_screen.dart';
import 'package:daway_app/features/payment/presentation/screens/payment_method_screen.dart';
import 'package:daway_app/features/payment/presentation/screens/upload_receipt_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

const _bank = PaymentBank(id: 3, name: 'بنك فلسطين', accountNumber: '0595554729');

class _FakePaymentRepository implements PaymentRepository {
  PaymentSummary summary = const PaymentSummary(
    status: 'pending',
    canSubmitReceipt: true,
    banks: [_bank, PaymentBank(id: 4, name: 'محفظة بال باي')],
    grandTotal: 150,
  );
  OrderTracking tracking = const OrderTracking(status: 'preparing');
  int? lastBankId;
  double? lastAmount;
  String? lastSender;
  bool lastHadReceipt = false;

  @override
  Future<ApiResult<PaymentSummary>> getPayment({
    required String token,
    required int orderId,
  }) async =>
      Success(summary);

  @override
  Future<ApiResult<List<PaymentBank>>> getBanks({required String token}) async =>
      Success(summary.banks);

  @override
  Future<ApiResult<OrderTracking>> getTracking({
    required String token,
    required int orderId,
  }) async =>
      Success(tracking);

  @override
  Future<ApiResult<void>> submitReceipt({
    required String token,
    required int orderId,
    required int bankId,
    required double amount,
    required String senderName,
    required String transferReference,
    File? receipt,
  }) async {
    lastBankId = bankId;
    lastAmount = amount;
    lastSender = senderName;
    lastHadReceipt = receipt != null;
    return const Success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeProfileRepository implements PatientProfileRepository {
  @override
  Future<ApiResult<PatientProfile>> getProfile({required String token}) async =>
      const Success(PatientProfile(name: 'أحمد', phone: '0599'));

  @override
  Future<ApiResult<void>> updateProfile({
    required String token,
    required PatientProfile profile,
  }) async =>
      const Success(null);
}

class _FakeSession implements SessionRepository {
  @override
  Future<UserSession?> getSession() async =>
      const UserSession(accountType: AccountType.patient, token: 'tok');

  @override
  Future<void> saveSession(UserSession session) async {}

  @override
  Future<void> clearSession() async {}
}

void main() {
  final getIt = GetIt.instance;
  late _FakePaymentRepository repository;

  setUp(() {
    repository = _FakePaymentRepository();
    final session = _FakeSession();
    getIt.registerFactoryParam<PaymentCubit, int, void>(
      (orderId, _) => PaymentCubit(
        orderId,
        GetPaymentUseCase(repository, session),
        SubmitPaymentReceiptUseCase(repository, session),
        ReportPaymentProblemUseCase(repository, session),
        GetPatientProfileUseCase(_FakeProfileRepository(), session),
      ),
    );
    getIt.registerFactoryParam<TrackingCubit, int, void>(
      (orderId, _) => TrackingCubit(orderId, GetOrderTrackingUseCase(repository, session)),
    );
  });

  tearDown(() => getIt.reset());

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    List<String>? visitedRoutes,
  }) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(440, 956),
        builder: (context, child) => MaterialApp(
          onGenerateRoute: (settings) {
            visitedRoutes?.add(settings.name ?? '');
            return MaterialPageRoute(builder: (_) => const Scaffold(body: SizedBox.shrink()));
          },
          home: screen,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('PaymentMethodScreen', () {
    testWidgets('lists the banks and pays the amount of the server', (tester) async {
      await pumpScreen(tester, const PaymentMethodScreen(orderId: 9));

      expect(find.text('طريقة الدفع'), findsOneWidget);
      expect(find.text('بنك فلسطين'), findsOneWidget);
      expect(find.text('0595554729'), findsOneWidget);
      expect(find.text('محفظة بال باي'), findsOneWidget);
      expect(find.text('ادفع \$150'), findsOneWidget);
    });

    testWidgets('paying without a choice asks for one, with a choice goes on to the receipt',
        (tester) async {
      final visited = <String>[];
      await pumpScreen(tester, const PaymentMethodScreen(orderId: 9), visitedRoutes: visited);

      await tester.tap(find.text('ادفع \$150'));
      await tester.pump();
      expect(find.text('اختر طريقة الدفع'), findsOneWidget);
      expect(visited, isNot(contains(Routes.uploadReceiptScreen)));

      await tester.tap(find.text('بنك فلسطين'));
      await tester.pump();
      await tester.tap(find.text('ادفع \$150'));
      await tester.pumpAndSettle();
      expect(visited, contains(Routes.uploadReceiptScreen));
    });

    testWidgets('an order whose receipt is already under review offers tracking instead',
        (tester) async {
      repository.summary = const PaymentSummary(
        status: 'under_review',
        canSubmitReceipt: false,
        grandTotal: 150,
      );
      await pumpScreen(tester, const PaymentMethodScreen(orderId: 9));

      expect(find.textContaining('قيد المراجعة'), findsOneWidget);
      expect(find.text('تتبع الطلب'), findsOneWidget);
      expect(find.textContaining('ادفع'), findsNothing);
    });
  });

  group('UploadReceiptScreen', () {
    testWidgets('shows the chosen bank and asks for the photo before sending', (tester) async {
      await pumpScreen(
        tester,
        const UploadReceiptScreen(args: UploadReceiptArgs(orderId: 9, bank: _bank)),
      );

      expect(find.text('طريقة الدفع المختارة'), findsOneWidget);
      expect(find.text('اضغط لرفع إشعار التحويل'), findsOneWidget);

      await tester.tap(find.text('إتمام الطلب'));
      await tester.pump();

      expect(find.text('أرفق صورة إشعار التحويل'), findsOneWidget);
      expect(repository.lastBankId, isNull);
    });

    testWidgets('typed details replace the photo: bank, holder and amount are sent',
        (tester) async {
      final visited = <String>[];
      await pumpScreen(
        tester,
        const UploadReceiptScreen(args: UploadReceiptArgs(orderId: 9, bank: _bank)),
        visitedRoutes: visited,
      );

      await tester.tap(find.text('لديك مشكلة في رفع الإشعار؟'));
      await tester.pumpAndSettle();
      expect(find.text('اكتب بيانات التحويل لإتمام الطلب'), findsOneWidget);

      await tester.tap(find.text('إتمام الطلب'));
      await tester.pump();
      expect(find.byType(SnackBar), findsOneWidget);

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'سالم');
      await tester.enterText(fields.at(1), '150');
      await tester.tap(find.text('إتمام الطلب'));
      await tester.pumpAndSettle();

      expect(repository.lastBankId, 3);
      expect(repository.lastAmount, 150);
      expect(repository.lastSender, 'سالم');
      expect(repository.lastHadReceipt, isFalse);
      expect(visited, contains(Routes.orderTrackingScreen));
    });
  });

  group('OrderTrackingScreen', () {
    testWidgets('shows the order, its status and the steps reached', (tester) async {
      await pumpScreen(tester, const OrderTrackingScreen(orderId: 9));

      expect(find.text('طلب #9'), findsOneWidget);
      expect(find.text('قيد التجهيز'), findsOneWidget);
      expect(find.text('تم تأكيد طلبك'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget); // confirmed is done, preparing is current
      expect(find.text('جاري تجهيز الأدوية'), findsOneWidget);
      expect(find.text('تم تسليم طلبك بنجاح'), findsOneWidget);
    });

    testWidgets('a delivered order has every step checked', (tester) async {
      repository.tracking = const OrderTracking(status: 'delivered');
      await pumpScreen(tester, const OrderTrackingScreen(orderId: 9));

      expect(find.byIcon(Icons.check), findsNWidgets(4));
    });

    testWidgets('the notify button says "قريباً" and home goes back to the start',
        (tester) async {
      final visited = <String>[];
      await pumpScreen(tester, const OrderTrackingScreen(orderId: 9), visitedRoutes: visited);
      await tester.ensureVisible(find.text('نبّهني عند اقتراب الطلب'));

      await tester.tap(find.text('نبّهني عند اقتراب الطلب'));
      await tester.pump();
      expect(find.text('قريباً'), findsOneWidget);

      await tester.ensureVisible(find.text('العودة للرئيسية'));
      await tester.tap(find.text('العودة للرئيسية'));
      await tester.pumpAndSettle();
      expect(visited, contains(Routes.patientHomeScreen));
    });
  });
}
