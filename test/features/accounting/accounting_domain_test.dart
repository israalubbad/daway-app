import 'package:daway_app/core/erroring/failure.dart';
import 'package:daway_app/core/helpers/api_result.dart';
import 'package:daway_app/features/accounting/data/repositories/sample_accounting_repository.dart';
import 'package:daway_app/features/accounting/domain/entities/accounting_overview.dart';
import 'package:daway_app/features/accounting/domain/entities/sale_invoice.dart';
import 'package:daway_app/features/accounting/domain/usecases/accounting_usecases.dart';
import 'package:daway_app/features/auth/domain/entities/account_type.dart';
import 'package:daway_app/features/auth/domain/entities/user_session.dart';
import 'package:daway_app/features/auth/domain/repositories/session_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _Session implements SessionRepository {
  final UserSession? session;

  const _Session([this.session = const UserSession(accountType: AccountType.pharmacy, token: 'tok')]);

  @override
  Future<void> saveSession(UserSession session) async {}

  @override
  Future<UserSession?> getSession() async => session;

  @override
  Future<void> clearSession() async {}
}

SaleInvoice _invoice({double total = 100, double paid = 0}) => SaleInvoice(
  id: 1,
  number: 'INV-1',
  date: DateTime(2026, 11, 8),
  itemsCount: 1,
  subtotal: total,
  total: total,
  paid: paid,
  method: PaymentMethod.cash,
);

void main() {
  group('SaleInvoice', () {
    test('nothing paid is unpaid, with everything remaining', () {
      final invoice = _invoice();

      expect(invoice.status, PaymentStatus.unpaid);
      expect(invoice.remaining, 100);
    });

    test('part paid is partial', () {
      final invoice = _invoice(paid: 90);

      expect(invoice.status, PaymentStatus.partial);
      expect(invoice.remaining, 10);
    });

    test('all paid is paid, and an overpayment leaves nothing remaining', () {
      expect(_invoice(paid: 100).status, PaymentStatus.paid);
      expect(_invoice(paid: 120).remaining, 0);
    });
  });

  group('use cases', () {
    late SampleAccountingRepository repository;

    setUp(() => repository = SampleAccountingRepository());

    test('without a session they answer the session-expired failure', () async {
      final result = await GetSalesUseCase(repository, const _Session(null))();

      expect(result, isA<ApiError<List<SaleInvoice>>>());
    });

    test('a deposit needs an amount above zero', () async {
      final useCase = RecordCashMovementUseCase(repository, const _Session());

      final result = await useCase(isDeposit: true, amount: 0, reason: 'x');

      expect((result as ApiError).failure, isA<ApiFailure>());
    });

    test('a movement needs a reason', () async {
      final useCase = RecordCashMovementUseCase(repository, const _Session());

      final result = await useCase(isDeposit: true, amount: 10, reason: '   ');

      expect(result, isA<ApiError<void>>());
    });

    test('a valid deposit changes the balance', () async {
      final useCase = RecordCashMovementUseCase(repository, const _Session());
      final before = (await GetCashLedgerUseCase(repository, const _Session())() as Success).data.balance;

      await useCase(isDeposit: true, amount: 50, reason: 'إيداع');

      final after = (await GetCashLedgerUseCase(repository, const _Session())() as Success).data.balance;
      expect(after, before + 50);
    });

    test('a search shorter than two characters finds nothing without asking', () async {
      final result = await SearchSaleItemsUseCase(repository, const _Session())('p');

      expect((result as Success<List<SaleItemOption>>).data, isEmpty);
    });

    test('an empty cart is not sold', () async {
      final result = await CreateSaleUseCase(repository, const _Session())(
        const NewSale(lines: [], paid: 0, method: PaymentMethod.cash),
      );

      expect(result, isA<ApiError<void>>());
    });

    test('a payment above the total is recorded as the total', () async {
      const item = SaleItemOption(id: 1, name: 'x', price: 20, stock: 5);
      await CreateSaleUseCase(repository, const _Session())(
        const NewSale(
          lines: [SaleLine(item: item, quantity: 2)],
          paid: 500,
          method: PaymentMethod.cash,
        ),
      );

      final sales = (await GetSalesUseCase(repository, const _Session())() as Success<List<SaleInvoice>>).data;
      expect(sales.first.paid, 40);
      expect(sales.first.status, PaymentStatus.paid);
    });
  });
}
