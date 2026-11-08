import 'package:daway_app/features/accounting/data/repositories/sample_accounting_repository.dart';
import 'package:daway_app/features/accounting/domain/entities/accounting_overview.dart';
import 'package:daway_app/features/accounting/domain/entities/sale_invoice.dart';
import 'package:daway_app/features/accounting/domain/usecases/accounting_usecases.dart';
import 'package:daway_app/features/accounting/presentation/cubit/accounting_load_state.dart';
import 'package:daway_app/features/accounting/presentation/cubit/accounting_overview_cubit.dart';
import 'package:daway_app/features/accounting/presentation/cubit/cash_cubit.dart';
import 'package:daway_app/features/accounting/presentation/cubit/cash_state.dart';
import 'package:daway_app/features/accounting/presentation/cubit/new_sale_cubit.dart';
import 'package:daway_app/features/accounting/presentation/cubit/sales_cubit.dart';
import 'package:daway_app/features/accounting/presentation/cubit/sales_state.dart';
import 'package:daway_app/features/auth/domain/entities/account_type.dart';
import 'package:daway_app/features/auth/domain/entities/user_session.dart';
import 'package:daway_app/features/auth/domain/repositories/session_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _Session implements SessionRepository {
  @override
  Future<void> saveSession(UserSession session) async {}

  @override
  Future<UserSession?> getSession() async =>
      const UserSession(accountType: AccountType.pharmacy, token: 'tok');

  @override
  Future<void> clearSession() async {}
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late SampleAccountingRepository repository;
  late _Session session;

  setUp(() {
    repository = SampleAccountingRepository();
    session = _Session();
  });

  group('AccountingOverviewCubit', () {
    test('loads the overview for the last 7 days', () async {
      final cubit = AccountingOverviewCubit(GetAccountingOverviewUseCase(repository, session));
      addTearDown(cubit.close);
      await _settle();

      final state = cubit.state as AccountingLoaded<AccountingOverview>;
      expect(state.data.period, SalesPeriod.last7Days);
      expect(state.data.salesTrend, hasLength(7));
    });

    test('changing the period fetches that period', () async {
      final cubit = AccountingOverviewCubit(GetAccountingOverviewUseCase(repository, session));
      addTearDown(cubit.close);
      await _settle();

      await cubit.periodChanged(SalesPeriod.last30Days);

      final state = cubit.state as AccountingLoaded<AccountingOverview>;
      expect(state.data.period, SalesPeriod.last30Days);
      expect(state.data.salesTrend, hasLength(30));
    });
  });

  group('SalesCubit', () {
    late SalesCubit cubit;

    setUp(() async {
      cubit = SalesCubit(GetSalesUseCase(repository, session));
      await _settle();
    });

    tearDown(() => cubit.close());

    test('lists every invoice with its totals', () {
      final state = cubit.state as SalesLoaded;

      expect(state.visible, hasLength(2));
      expect(state.totalAmount, 200);
      expect(state.paidAmount, 90);
      expect(state.remainingAmount, 110);
    });

    test('a search matches the customer or the number', () {
      cubit.queryChanged('محمد');
      expect((cubit.state as SalesLoaded).visible.single.number, 'INV-1002');

      cubit.queryChanged('inv-1001');
      expect((cubit.state as SalesLoaded).visible.single.customerName, isNull);
    });

    test('filters narrow by status and method, and reset clears them', () {
      cubit.filtersApplied(range: DateRangeFilter.all, status: PaymentStatus.unpaid);
      expect((cubit.state as SalesLoaded).visible.single.number, 'INV-1001');
      expect((cubit.state as SalesLoaded).activeFilters, 1);

      cubit.filtersApplied(range: DateRangeFilter.all, method: PaymentMethod.bankTransfer);
      expect((cubit.state as SalesLoaded).visible.single.number, 'INV-1002');

      cubit.filtersApplied(range: DateRangeFilter.all);
      expect((cubit.state as SalesLoaded).visible, hasLength(2));
      expect((cubit.state as SalesLoaded).activeFilters, 0);
    });

    test('the date filter keeps only invoices inside the range', () {
      cubit.filtersApplied(range: DateRangeFilter.today);

      expect((cubit.state as SalesLoaded).visible, isEmpty);
    });
  });

  group('CashCubit', () {
    late CashCubit cubit;

    setUp(() async {
      cubit = CashCubit(
        GetCashLedgerUseCase(repository, session),
        RecordCashMovementUseCase(repository, session),
      );
      await _settle();
    });

    tearDown(() => cubit.close());

    test('shows the balance the movements add up to', () {
      final state = cubit.state as CashLoaded;

      expect(state.ledger.balance, 250);
      expect(state.visible, hasLength(3));
    });

    test('a withdrawal lowers the balance and appears first', () async {
      final error = await cubit.record(isDeposit: false, amount: 200, reason: 'سحب');

      final state = cubit.state as CashLoaded;
      expect(error, isNull);
      expect(state.ledger.balance, 50);
      expect(state.ledger.isLow, isTrue);
      expect(state.visible.first.amount, -200);
    });

    test('a rejected movement returns its message and changes nothing', () async {
      final error = await cubit.record(isDeposit: true, amount: 0, reason: 'x');

      expect(error, isNotNull);
      expect((cubit.state as CashLoaded).ledger.balance, 250);
    });

    test('the type filter keeps one kind of movement', () {
      cubit.filtersApplied(type: CashTypeFilter.expenses, range: DateRangeFilter.all);

      expect((cubit.state as CashLoaded).visible.single.amount, -40);
    });
  });

  group('NewSaleCubit', () {
    late NewSaleCubit cubit;

    setUp(() {
      cubit = NewSaleCubit(
        SearchSaleItemsUseCase(repository, session),
        FindSaleItemByBarcodeUseCase(repository, session),
        CreateSaleUseCase(repository, session),
      );
    });

    tearDown(() => cubit.close());

    const panadol = SaleItemOption(id: 1, name: 'Panadol', price: 18, stock: 3);

    test('adding the same item twice makes one line of two, up to the stock', () {
      cubit.addItem(panadol);
      cubit.addItem(panadol);
      cubit.addItem(panadol);
      cubit.addItem(panadol);

      expect(cubit.state.lines, hasLength(1));
      expect(cubit.state.lines.single.quantity, 3);
      expect(cubit.state.total, 54);
    });

    test('a quantity below one removes the line', () {
      cubit.addItem(panadol);

      cubit.quantityChanged(1, 0);

      expect(cubit.state.lines, isEmpty);
      expect(cubit.state.canSubmit, isFalse);
    });

    test('the remaining amount follows what was paid', () {
      cubit.addItem(panadol);
      cubit.paidChanged('10');

      expect(cubit.state.remaining, 8);

      cubit.paidChanged('abc');
      expect(cubit.state.remaining, 18);
    });

    test('a known barcode puts its medicine in the cart and recognises it', () async {
      await cubit.barcodeSubmitted('6221031234567');

      expect(cubit.state.lines.single.item.name, 'Panadol Extra 500mg');
      expect(cubit.state.recognized, isNotNull);
    });

    test('an unknown barcode adds nothing and says so', () async {
      await cubit.barcodeSubmitted('0000');

      expect(cubit.state.lines, isEmpty);
      expect(cubit.state.barcodeMessage, isNotNull);
    });

    test('searching finds a medicine by name', () async {
      await cubit.queryChanged('amox');

      expect(cubit.state.results.single.name, 'Amoxicillin 500mg');
    });

    test('submitting saves the sale and marks it completed', () async {
      cubit.addItem(panadol);
      cubit.paidChanged('18');

      await cubit.submit();

      expect(cubit.state.completed, isTrue);
      final sales = (await GetSalesUseCase(repository, session)() as dynamic).data as List<SaleInvoice>;
      expect(sales.first.total, 18);
      expect(sales.first.status, PaymentStatus.paid);
    });

    test('submitting an empty cart does nothing', () async {
      await cubit.submit();

      expect(cubit.state.completed, isFalse);
      expect(cubit.state.isSaving, isFalse);
    });
  });
}
