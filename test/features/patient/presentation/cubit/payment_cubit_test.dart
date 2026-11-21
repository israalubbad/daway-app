import 'package:daway_app/core/erroring/failure.dart';
import 'package:daway_app/core/helpers/api_result.dart';
import 'package:daway_app/features/patient/data/repositories/checkout_flow_repository_impl.dart';
import 'package:daway_app/features/patient/domain/entities/checkout_flow.dart';
import 'package:daway_app/features/patient/domain/entities/order.dart';
import 'package:daway_app/features/patient/domain/repositories/checkout_flow_repository.dart';
import 'package:daway_app/features/patient/domain/usecases/checkout_flow_usecases.dart';
import 'package:daway_app/features/patient/presentation/cubit/order_tracking_cubit.dart';
import 'package:daway_app/features/patient/presentation/cubit/payment_cubit.dart';
import 'package:daway_app/features/patient/presentation/cubit/payment_state.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../helpers/in_memory_session_repository.dart';

const _payment = OrderPayment(
  orderId: 7,
  grandTotal: 150,
  deliveryFee: 15,
  paymentStatus: 'pending',
  canSubmitReceipt: true,
  banks: [
    PaymentBank(id: 1, name: 'بنك فلسطين', accountNumber: '0595554729'),
    PaymentBank(id: 2, name: 'محفظة جوال باي', accountNumber: '0595554730'),
  ],
);

class _FakeFlowRepository implements CheckoutFlowRepository {
  ApiResult<OrderPayment> paymentResult = const Success(_payment);
  ApiResult<void> receiptResult = const Success(null);
  ApiResult<void> problemResult = const Success(null);
  ApiResult<OrderTracking> trackingResult = const Success(
    OrderTracking(status: OrderStatus.confirmed, history: []),
  );

  int? receiptBankId;
  double? receiptAmount;
  String? receiptPath;
  String? problemMessage;

  @override
  Future<ApiResult<double>> validateCoupon({
    required String token,
    required String code,
    required double orderTotal,
  }) => throw UnimplementedError();

  @override
  Future<ApiResult<OrderPayment>> getPayment({
    required String token,
    required int orderId,
  }) async => paymentResult;

  @override
  Future<ApiResult<void>> submitReceipt({
    required String token,
    required int orderId,
    required int bankId,
    required double amount,
    required String receiptPath,
  }) async {
    receiptBankId = bankId;
    receiptAmount = amount;
    this.receiptPath = receiptPath;
    return receiptResult;
  }

  @override
  Future<ApiResult<void>> reportProblem({
    required String token,
    required int orderId,
    required String message,
  }) async {
    problemMessage = message;
    return problemResult;
  }

  @override
  Future<ApiResult<OrderTracking>> getTracking({
    required String token,
    required int orderId,
  }) async => trackingResult;
}

void main() {
  late _FakeFlowRepository repository;
  late InMemorySessionRepository sessionRepository;

  PaymentCubit buildCubit() => PaymentCubit(
    7,
    GetOrderPaymentUseCase(repository, sessionRepository),
    SubmitPaymentReceiptUseCase(repository, sessionRepository),
    ReportPaymentProblemUseCase(repository, sessionRepository),
    GetOrderTrackingUseCase(repository, sessionRepository),
  );

  Future<PaymentCubit> readyCubit() async {
    final cubit = buildCubit();
    addTearDown(cubit.close);
    await Future<void>.delayed(Duration.zero);
    return cubit;
  }

  setUp(() {
    repository = _FakeFlowRepository();
    sessionRepository = InMemorySessionRepository.patient();
  });

  group('PaymentCubit', () {
    test('waits for the admin while the delivery fee is not set', () async {
      repository.paymentResult = const Success(
        OrderPayment(
          orderId: 7,
          grandTotal: 135,
          paymentStatus: 'pending',
          canSubmitReceipt: true,
          awaitingDeliveryFee: true,
          banks: [PaymentBank(id: 1, name: 'بنك فلسطين', accountNumber: '1')],
        ),
      );

      final cubit = await readyCubit();

      expect((cubit.state as PaymentReady).awaitingAdmin, isTrue);
    });

    test('waits for the admin while the order is still pending', () async {
      repository.trackingResult = const Success(
        OrderTracking(status: OrderStatus.pending, history: []),
      );

      final cubit = await readyCubit();

      expect((cubit.state as PaymentReady).awaitingAdmin, isTrue);
    });

    test('opens up once the admin has approved the order', () async {
      repository.trackingResult = const Success(
        OrderTracking(status: OrderStatus.pending, history: []),
      );
      final cubit = await readyCubit();
      expect((cubit.state as PaymentReady).awaitingAdmin, isTrue);

      repository.trackingResult = const Success(
        OrderTracking(status: OrderStatus.confirmed, history: []),
      );
      await cubit.refresh();

      expect((cubit.state as PaymentReady).awaitingAdmin, isFalse);
    });

    test(
      'an approved payment never waits, even without a delivery fee',
      () async {
        repository.paymentResult = const Success(
          OrderPayment(
            orderId: 7,
            grandTotal: 599.91,
            paymentStatus: 'approved',
            canSubmitReceipt: false,
            awaitingDeliveryFee: true,
            banks: [],
          ),
        );
        repository.trackingResult = const Success(
          OrderTracking(status: OrderStatus.pending, history: []),
        );

        final cubit = await readyCubit();

        expect((cubit.state as PaymentReady).awaitingAdmin, isFalse);
        expect((cubit.state as PaymentReady).payment.isApproved, isTrue);
      },
    );

    test('is not waiting when the order is confirmed and priced', () async {
      final cubit = await readyCubit();

      expect((cubit.state as PaymentReady).awaitingAdmin, isFalse);
    });

    test('loads the payment and selects the first bank', () async {
      final cubit = await readyCubit();

      final state = cubit.state as PaymentReady;
      expect(state.payment.grandTotal, 150);
      expect(state.selectedBank?.name, 'بنك فلسطين');
    });

    test(
      'fails with the server message when the payment cannot load',
      () async {
        repository.paymentResult = const ApiError(
          ApiFailure(message: 'الطلب غير موجود'),
        );

        final cubit = await readyCubit();

        expect((cubit.state as PaymentLoadFailure).message, 'الطلب غير موجود');
      },
    );

    test('selectBank changes the chosen bank', () async {
      final cubit = await readyCubit();

      cubit.selectBank(2);

      expect(
        (cubit.state as PaymentReady).selectedBank?.name,
        'محفظة جوال باي',
      );
    });

    test(
      'submitReceipt sends the chosen bank, the server total and the picture',
      () async {
        final cubit = await readyCubit();
        cubit.selectBank(2);

        final error = await cubit.submitReceipt('/tmp/receipt.jpg');

        expect(error, isNull);
        expect(repository.receiptBankId, 2);
        expect(repository.receiptAmount, 150);
        expect(repository.receiptPath, '/tmp/receipt.jpg');
        expect((cubit.state as PaymentReady).isSubmitting, isFalse);
      },
    );

    test(
      'submitReceipt returns the server message when it is refused',
      () async {
        repository.receiptResult = const ApiError(
          ApiFailure(message: 'الملف غير صالح'),
        );
        final cubit = await readyCubit();

        expect(await cubit.submitReceipt('/tmp/receipt.jpg'), 'الملف غير صالح');
        expect((cubit.state as PaymentReady).isSubmitting, isFalse);
      },
    );

    test(
      'reportTransferDetails hands the typed details over as a problem report',
      () async {
        final cubit = await readyCubit();

        final error = await cubit.reportTransferDetails(
          bankName: 'بنك فلسطين',
          accountHolder: 'أحمد',
          amount: 150,
        );

        expect(error, isNull);
        expect(repository.problemMessage, contains('بنك فلسطين'));
        expect(repository.problemMessage, contains('أحمد'));
        expect(repository.problemMessage, contains('150'));
      },
    );
  });

  group('OrderTrackingCubit', () {
    test('loads the tracking of the order', () async {
      repository.trackingResult = const Success(
        OrderTracking(status: OrderStatus.preparing, history: []),
      );
      final cubit = OrderTrackingCubit(
        7,
        GetOrderTrackingUseCase(repository, sessionRepository),
        GetOrderPaymentUseCase(repository, sessionRepository),
      );
      addTearDown(cubit.close);
      await Future<void>.delayed(Duration.zero);

      expect(
        (cubit.state as OrderTrackingLoaded).tracking.status,
        OrderStatus.preparing,
      );
    });
    test(
      'the order is not approved while the transfer is under review',
      () async {
        repository.paymentResult = const Success(
          OrderPayment(
            orderId: 7,
            grandTotal: 150,
            paymentStatus: 'under_review',
            canSubmitReceipt: false,
            banks: [],
          ),
        );
        final cubit = OrderTrackingCubit(
          7,
          GetOrderTrackingUseCase(repository, sessionRepository),
          GetOrderPaymentUseCase(repository, sessionRepository),
        );
        addTearDown(cubit.close);
        await Future<void>.delayed(Duration.zero);

        expect((cubit.state as OrderTrackingLoaded).paymentApproved, isFalse);
      },
    );

    test('an approved transfer approves the order', () async {
      repository.paymentResult = const Success(
        OrderPayment(
          orderId: 7,
          grandTotal: 150,
          paymentStatus: 'approved',
          canSubmitReceipt: false,
          banks: [],
        ),
      );
      final cubit = OrderTrackingCubit(
        7,
        GetOrderTrackingUseCase(repository, sessionRepository),
        GetOrderPaymentUseCase(repository, sessionRepository),
      );
      addTearDown(cubit.close);
      await Future<void>.delayed(Duration.zero);

      expect((cubit.state as OrderTrackingLoaded).paymentApproved, isTrue);
    });

    test('shows the failure when tracking cannot load', () async {
      repository.trackingResult = const ApiError(
        ApiFailure(message: 'تعذر التحميل'),
      );
      final cubit = OrderTrackingCubit(
        7,
        GetOrderTrackingUseCase(repository, sessionRepository),
        GetOrderPaymentUseCase(repository, sessionRepository),
      );
      addTearDown(cubit.close);
      await Future<void>.delayed(Duration.zero);

      expect((cubit.state as OrderTrackingFailure).message, 'تعذر التحميل');
    });
  });

  group('CheckoutFlowRepositoryImpl parsing', () {
    test(
      'parsePayment sees an empty delivery_fee, not a missing one, as awaiting the admin',
      () {
        expect(
          CheckoutFlowRepositoryImpl.parsePayment(7, {
            'grand_total': 100,
            'delivery_fee': null,
          }).awaitingDeliveryFee,
          isTrue,
        );
        expect(
          CheckoutFlowRepositoryImpl.parsePayment(7, {
            'grand_total': 100,
          }).awaitingDeliveryFee,
          isFalse,
        );
        expect(
          CheckoutFlowRepositoryImpl.parsePayment(7, {
            'grand_total': 100,
            'delivery_fee': 15,
          }).awaitingDeliveryFee,
          isFalse,
        );
      },
    );

    test('parsePayment reads the totals, status and banks', () {
      final payment = CheckoutFlowRepositoryImpl.parsePayment(7, {
        'grand_total': 150,
        'delivery_fee': 15.5,
        'payment_status': 'pending',
        'can_submit_receipt': true,
        'banks': [
          {'id': 1, 'name': 'بنك فلسطين', 'account_number': '0595554729'},
          {'id': 2, 'bank_name': 'محفظة', 'iban': 'PS00'},
        ],
      });

      expect(payment.grandTotal, 150);
      expect(payment.deliveryFee, 15.5);
      expect(payment.canSubmitReceipt, isTrue);
      expect(payment.banks.map((b) => b.name), ['بنك فلسطين', 'محفظة']);
      expect(payment.banks.map((b) => b.accountNumber), ['0595554729', 'PS00']);
    });

    test('parseBanks reads a bare list, and tolerates junk rows', () {
      final banks = CheckoutFlowRepositoryImpl.parseBanks([
        {'id': 3, 'name': 'بال باي', 'account_number': '0597601911'},
        'junk',
      ]);

      expect(banks, hasLength(1));
      expect(banks.single.accountNumber, '0597601911');
      expect(CheckoutFlowRepositoryImpl.parseBanks(null), isEmpty);
    });

    test('parsePayment also reads the banks from payment_banks', () {
      final payment = CheckoutFlowRepositoryImpl.parsePayment(7, {
        'grand_total': 15.57,
        'payment_banks': [
          {'id': 1, 'name': 'بنك فلسطين', 'account_number': '0597601911'},
        ],
      });

      expect(payment.banks.single.name, 'بنك فلسطين');
    });

    test('parseTracking reads the status and when each step happened', () {
      final tracking = CheckoutFlowRepositoryImpl.parseTracking({
        'status': 'preparing',
        'status_histories': [
          {'status': 'confirmed', 'created_at': '2026-10-27T07:14:00Z'},
          {'status': 'preparing', 'created_at': '2026-10-27T07:22:00Z'},
        ],
      });

      expect(tracking.status, OrderStatus.preparing);
      expect(tracking.history, hasLength(2));
      expect(tracking.timeOf(OrderStatus.confirmed), isNotNull);
      expect(tracking.timeOf(OrderStatus.delivered), isNull);
    });
  });
}
