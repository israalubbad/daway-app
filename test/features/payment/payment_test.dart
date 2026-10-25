import 'dart:io';

import 'package:daway_app/core/erroring/failure.dart';
import 'package:daway_app/core/helpers/api_result.dart';
import 'package:daway_app/core/helpers/idempotency_key.dart';
import 'package:daway_app/features/auth/domain/entities/account_type.dart';
import 'package:daway_app/features/auth/domain/entities/user_session.dart';
import 'package:daway_app/features/auth/domain/repositories/session_repository.dart';
import 'package:daway_app/features/payment/data/models/payment_models.dart';
import 'package:daway_app/features/payment/domain/entities/payment.dart';
import 'package:daway_app/features/payment/domain/repositories/payment_repository.dart';
import 'package:daway_app/features/payment/domain/usecases/payment_usecases.dart';
import 'package:daway_app/features/payment/presentation/cubit/payment_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePaymentRepository implements PaymentRepository {
  ApiResult<PaymentSummary> summary = const Success(
    PaymentSummary(status: 'pending', canSubmitReceipt: true, grandTotal: 60),
  );
  ApiResult<List<PaymentBank>> banks =
      const Success([PaymentBank(id: 3, name: 'بنك فلسطين')]);
  ApiResult<void> submitResult = const Success(null);
  ApiResult<void> problemResult = const Success(null);
  int? lastBankId;
  double? lastAmount;
  String? lastProblem;
  int? lastSubmissionId;
  int banksCalls = 0;

  @override
  Future<ApiResult<List<PaymentBank>>> getBanks({required String token}) async {
    banksCalls++;
    return banks;
  }

  @override
  Future<ApiResult<PaymentSummary>> getPayment({
    required String token,
    required int orderId,
  }) async =>
      summary;

  @override
  Future<ApiResult<void>> submitReceipt({
    required String token,
    required int orderId,
    required int bankId,
    required double amount,
    required String senderName,
    required String transferReference,
    required File receipt,
  }) async {
    lastBankId = bankId;
    lastAmount = amount;
    return submitResult;
  }

  @override
  Future<ApiResult<void>> reportProblem({
    required String token,
    required int orderId,
    required String message,
    required int submissionId,
    String category = 'other',
  }) async {
    lastProblem = message;
    lastSubmissionId = submissionId;
    return problemResult;
  }
}

class _FakeSession implements SessionRepository {
  final UserSession? session;

  _FakeSession([this.session = const UserSession(accountType: AccountType.patient, token: 'tok')]);

  @override
  Future<UserSession?> getSession() async => session;

  @override
  Future<void> saveSession(UserSession session) async {}

  @override
  Future<void> clearSession() async {}
}

void main() {
  group('payment parsing', () {
    test('reads a summary with banks, total, fee and the latest submission', () {
      final summary = parsePaymentSummary({
        'payment_status': 'under_review',
        'can_submit_receipt': false,
        'grand_total': '65.50',
        'delivery_fee': 5,
        'banks': [
          {'id': 1, 'bank_name': 'بنك فلسطين', 'account_number': '123', 'iban': 'PS00'},
          {'id': 2},
        ],
        'latest_submission': {'id': 9, 'status': 'under_review'},
      });

      expect(summary.status, 'under_review');
      expect(summary.canSubmitReceipt, isFalse);
      expect(summary.grandTotal, 65.5);
      expect(summary.deliveryFee, 5);
      expect(summary.banks.single.name, 'بنك فلسطين');
      expect(summary.banks.single.accountNumber, '123');
      expect(summary.latestSubmissionId, 9);
    });

    test('a bare summary does not throw', () {
      final summary = parsePaymentSummary({});

      expect(summary.status, 'pending');
      expect(summary.canSubmitReceipt, isFalse);
      expect(summary.banks, isEmpty);
      expect(summary.grandTotal, isNull);
    });

    test('idempotency keys are unique and 32 hex characters', () {
      final a = newIdempotencyKey();
      final b = newIdempotencyKey();

      expect(a, matches(RegExp(r'^[0-9a-f]{32}$')));
      expect(a, isNot(b));
    });
  });

  group('GetPaymentUseCase', () {
    test('fills the banks from /payment-banks when the summary has none', () async {
      final repository = _FakePaymentRepository();
      final useCase = GetPaymentUseCase(repository, _FakeSession());

      final result = await useCase(5);

      expect((result as Success<PaymentSummary>).data.banks.single.id, 3);
      expect(result.data.grandTotal, 60);
    });

    test('does not fetch banks when the summary already has them', () async {
      final repository = _FakePaymentRepository()
        ..summary = const Success(
          PaymentSummary(
            status: 'pending',
            canSubmitReceipt: true,
            banks: [PaymentBank(id: 1, name: 'x')],
          ),
        );

      await GetPaymentUseCase(repository, _FakeSession())(5);

      expect(repository.banksCalls, 0);
    });

    test('a missing session is an error without calling the server', () async {
      final result = await GetPaymentUseCase(_FakePaymentRepository(), _FakeSession(null))(5);

      expect(result, isA<ApiError<PaymentSummary>>());
    });
  });

  group('PaymentCubit', () {
    late _FakePaymentRepository repository;

    PaymentCubit build() {
      final session = _FakeSession();
      final cubit = PaymentCubit(
        5,
        GetPaymentUseCase(repository, session),
        SubmitPaymentReceiptUseCase(repository, session),
        ReportPaymentProblemUseCase(repository, session),
      );
      addTearDown(cubit.close);
      return cubit;
    }

    setUp(() => repository = _FakePaymentRepository());

    test('load shows the summary', () async {
      final cubit = build();

      await cubit.load();

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.summary?.grandTotal, 60);
    });

    test('a failed load keeps the error for the retry screen', () async {
      repository.summary = const ApiError(NetworkFailure('تعذر الاتصال بالخادم'));
      final cubit = build();

      await cubit.load();

      expect(cubit.state.summary, isNull);
      expect(cubit.state.loadError, 'تعذر الاتصال بالخادم');
    });

    test('a sent receipt says it is under review and reloads the summary', () async {
      final cubit = build();
      await cubit.load();
      repository.summary = const Success(
        PaymentSummary(status: 'under_review', canSubmitReceipt: false, grandTotal: 60),
      );

      await cubit.submitReceipt(
        bankId: 3,
        amount: 60,
        senderName: 'أحمد',
        transferReference: 'R1',
        receipt: File('r.jpg'),
      );

      expect(repository.lastBankId, 3);
      expect(repository.lastAmount, 60);
      expect(cubit.state.message, PaymentCubit.receiptSentMessage);
      expect(cubit.state.summary?.status, 'under_review');
      expect(cubit.state.isBusy, isFalse);
    });

    test('a rejected receipt surfaces the server message', () async {
      repository.submitResult = const ApiError(ValidationFailure('المبلغ غير صحيح'));
      final cubit = build();
      await cubit.load();

      await cubit.submitReceipt(
        bankId: 3,
        amount: 60,
        senderName: 'أحمد',
        transferReference: 'R1',
        receipt: File('r.jpg'),
      );

      expect(cubit.state.message, 'المبلغ غير صحيح');
      expect(cubit.state.isBusy, isFalse);
    });

    test('a problem report carries the latest submission id', () async {
      repository.summary = const Success(
        PaymentSummary(
          status: 'under_review',
          canSubmitReceipt: false,
          latestSubmissionId: 9,
        ),
      );
      final cubit = build();
      await cubit.load();

      await cubit.reportProblem('  المبلغ خاطئ ');

      expect(repository.lastProblem, 'المبلغ خاطئ');
      expect(repository.lastSubmissionId, 9);
      expect(cubit.state.message, PaymentCubit.problemSentMessage);
    });

    test('a problem report without a submission or text is ignored', () async {
      final cubit = build();
      await cubit.load();

      await cubit.reportProblem('مشكلة');
      expect(repository.lastProblem, isNull);

      await cubit.reportProblem('   ');
      expect(repository.lastProblem, isNull);
    });
  });
}

