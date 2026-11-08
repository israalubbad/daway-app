import 'package:daway_app/core/di/dependency_injection.dart';
import 'package:daway_app/features/accounting/data/repositories/sample_accounting_repository.dart';
import 'package:daway_app/features/accounting/domain/repositories/accounting_repository.dart';
import 'package:daway_app/features/accounting/domain/usecases/accounting_usecases.dart';
import 'package:daway_app/features/accounting/presentation/cubit/accounting_overview_cubit.dart';
import 'package:daway_app/features/accounting/presentation/cubit/cash_cubit.dart';
import 'package:daway_app/features/accounting/presentation/cubit/new_sale_cubit.dart';
import 'package:daway_app/features/accounting/presentation/cubit/refunds_cubit.dart';
import 'package:daway_app/features/accounting/presentation/cubit/sales_cubit.dart';
import 'package:daway_app/features/accounting/presentation/screens/accounting_shell_screen.dart';
import 'package:daway_app/features/auth/domain/entities/account_type.dart';
import 'package:daway_app/features/auth/domain/entities/user_session.dart';
import 'package:daway_app/features/auth/domain/repositories/session_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/arabic_test_app.dart';

class _Session implements SessionRepository {
  @override
  Future<void> saveSession(UserSession session) async {}

  @override
  Future<UserSession?> getSession() async =>
      const UserSession(accountType: AccountType.pharmacy, token: 'tok');

  @override
  Future<void> clearSession() async {}
}

void main() {
  setUp(() {
    final repository = SampleAccountingRepository();
    final session = _Session();
    getIt
      ..registerSingleton<AccountingRepository>(repository)
      ..registerFactory(() => AccountingOverviewCubit(GetAccountingOverviewUseCase(repository, session)))
      ..registerFactory(() => SalesCubit(GetSalesUseCase(repository, session)))
      ..registerFactory(() => RefundsCubit(GetRefundsUseCase(repository, session)))
      ..registerFactory(
        () => CashCubit(
          GetCashLedgerUseCase(repository, session),
          RecordCashMovementUseCase(repository, session),
        ),
      )
      ..registerFactory(
        () => NewSaleCubit(
          SearchSaleItemsUseCase(repository, session),
          FindSaleItemByBarcodeUseCase(repository, session),
          CreateSaleUseCase(repository, session),
        ),
      );
  });

  tearDown(() => getIt.reset());

  /// A tall viewport, so a whole scrolling screen is built and found at once.
  Future<void> pumpShell(WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(buildArabicTestApp(home: const AccountingShellScreen()));
    await tester.pumpAndSettle();
  }

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  testWidgets('the overview shows the figures, the charts, the alerts and the latest transactions', (
    tester,
  ) async {
    await pumpShell(tester);

    expect(find.text('المحاسبة'), findsOneWidget);
    for (final title in [
      'مبيعات اليوم',
      'مشتريات اليوم',
      'مصروفات اليوم',
      'ربح اليوم',
      'رصيد الصندوق',
      'الديون المستحقة',
    ]) {
      expect(find.text(title), findsOneWidget);
    }
    expect(find.text('حركة المبيعات'), findsOneWidget);
    expect(find.text('آخر 7 أيام'), findsOneWidget);
    expect(find.text('توزيع المصروفات'), findsOneWidget);
    expect(find.text('دين عميل متأخر'), findsOneWidget);
    expect(find.text('مخزون منخفض'), findsOneWidget);
    expect(find.text('INV-1002'), findsOneWidget);
    // The debts card shows what the two invoices leave owing.
    expect(find.text('₪110.00'), findsWidgets);
  });

  testWidgets('the period buttons reload the chart', (tester) async {
    await pumpShell(tester);

    await tester.tap(find.text('آخر 30 يوماً'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('حركة المبيعات'), findsOneWidget);
  });

  testWidgets('the sales tab lists the invoices with their totals', (tester) async {
    await pumpShell(tester);

    await openTab(tester, 'المبيعات');

    expect(find.text('INV-1002'), findsOneWidget);
    expect(find.text('INV-1001'), findsOneWidget);
    expect(find.text('2 نتيجة'), findsOneWidget);
    expect(find.text('مدفوع جزئياً'), findsOneWidget);
    expect(find.text('غير مدفوع'), findsOneWidget);
    expect(find.text('زائر نقدي · 2 صنف', skipOffstage: false), findsNothing);
  });

  testWidgets('searching the sales narrows the list', (tester) async {
    await pumpShell(tester);
    await openTab(tester, 'المبيعات');

    await tester.enterText(find.byType(TextField), 'قالع');
    await tester.pumpAndSettle();

    expect(find.text('1 نتيجة'), findsOneWidget);
    expect(find.text('INV-1001'), findsNothing);
  });

  testWidgets('the filters sheet applies a status filter', (tester) async {
    await pumpShell(tester);
    await openTab(tester, 'المبيعات');

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('غير مدفوع').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('تطبيق'));
    await tester.pumpAndSettle();

    expect(find.text('1 نتيجة'), findsOneWidget);
    expect(find.text('INV-1001'), findsOneWidget);
    expect(find.text('INV-1002'), findsNothing);
  });

  testWidgets('the refunds tab shows its empty state', (tester) async {
    await pumpShell(tester);

    await openTab(tester, 'الإرجاعات');

    expect(find.text('لا توجد إرجاعات'), findsOneWidget);
    expect(
      find.text('ستظهر هنا كل عمليات الإرجاع التي تُنفّذ على فواتير البيع.'),
      findsOneWidget,
    );
  });

  testWidgets('the cash tab shows the balance and its movements', (tester) async {
    await pumpShell(tester);

    await openTab(tester, 'الصندوق');

    expect(find.text('الرصيد الحالي'), findsOneWidget);
    expect(find.text('₪250.00'), findsWidgets);
    expect(find.text('رصيد افتتاحي'), findsOneWidget);
    expect(find.text('+₪200.00'), findsOneWidget);
    expect(find.text('−₪40.00'), findsOneWidget);
    // 250 is above the safe limit of 100: no low-cash warning.
    expect(find.text('رصيد الصندوق منخفض'), findsNothing);
  });

  testWidgets('recording a withdrawal asks to confirm, then updates the balance and warns', (
    tester,
  ) async {
    await pumpShell(tester);
    await openTab(tester, 'الصندوق');

    await tester.tap(find.text('تسجيل حركة صندوق'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('سحب'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, '200');
    await tester.enterText(find.byType(TextField).last, 'دفع مورد');
    await tester.pump();
    await tester.tap(find.text('تسجيل'));
    await tester.pumpAndSettle();

    expect(find.textContaining('تأكيد سحب'), findsOneWidget);
    await tester.tap(find.text('تأكيد'));
    await tester.pumpAndSettle();

    expect(find.text('تم تسجيل الحركة'), findsOneWidget);
    expect(find.text('دفع مورد'), findsOneWidget);
    expect(find.text('رصيد الصندوق منخفض'), findsOneWidget);
  });

  testWidgets('the movement button refuses until the amount and the reason are filled', (
    tester,
  ) async {
    await pumpShell(tester);
    await openTab(tester, 'الصندوق');

    await tester.tap(find.text('تسجيل حركة صندوق'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تسجيل'));
    await tester.pumpAndSettle();

    expect(find.textContaining('تأكيد'), findsNothing);
    expect(find.text('أدخل المبلغ وسبب الحركة'), findsOneWidget);
  });

  testWidgets('a new sale: scan a barcode, see it in the cart and complete it', (tester) async {
    await pumpShell(tester);

    await tester.tap(find.text('فاتورة بيع جديدة'));
    await tester.pumpAndSettle();
    expect(find.text('السلة فارغة'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '6221031234567');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Panadol Extra 500mg'), findsOneWidget);
    expect(find.textContaining('تم التعرف على الدواء'), findsOneWidget);

    await tester.tap(find.text('إتمام البيع'));
    await tester.pumpAndSettle();
    expect(find.text('ملخص الفاتورة'), findsOneWidget);
    expect(find.text('غير مدعومة في النظام الحالي'), findsOneWidget);

    await tester.tap(find.text('إتمام البيع').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('إتمام البيع بإجمالي'), findsOneWidget);
    await tester.tap(find.text('تأكيد'));
    await tester.pumpAndSettle();

    // Back on the overview, which has refreshed with the new invoice.
    expect(find.text('المحاسبة'), findsOneWidget);
    expect(find.text('تم إتمام البيع'), findsOneWidget);
  });

  testWidgets('searching by name adds the medicine to the cart', (tester) async {
    await pumpShell(tester);
    await tester.tap(find.text('فاتورة بيع جديدة'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(1), 'vita');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vitamin C 1000mg'));
    await tester.pumpAndSettle();

    expect(find.text('أصناف السلة'), findsOneWidget);
    expect(find.text('Vitamin C 1000mg'), findsOneWidget);
    expect(find.text('السلة فارغة'), findsNothing);
  });
}
