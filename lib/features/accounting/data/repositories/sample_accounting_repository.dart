import '../../../../core/helpers/api_result.dart';
import '../../domain/entities/accounting_overview.dart';
import '../../domain/entities/cash_ledger.dart';
import '../../domain/entities/refund_record.dart';
import '../../domain/entities/sale_invoice.dart';
import '../../domain/repositories/accounting_repository.dart';

/// Invented figures so the accounting screens can be looked at and tried in a
/// debug build before the API's response shapes are known. Nothing is sent
/// anywhere: sales and cash movements are kept in memory and gone on restart.
/// It is only registered in debug builds (see `core/di`); a release build gets
/// [ComingSoonAccountingRepository] instead.
class SampleAccountingRepository implements AccountingRepository {
  SampleAccountingRepository() {
    final now = DateTime.now();
    _sales = [
      SaleInvoice(
        id: 2,
        number: 'INV-1002',
        date: now.subtract(const Duration(days: 6, hours: 2)),
        customerName: 'محمد قالع',
        itemsCount: 1,
        subtotal: 100,
        total: 100,
        paid: 90,
        method: PaymentMethod.bankTransfer,
      ),
      SaleInvoice(
        id: 1,
        number: 'INV-1001',
        date: now.subtract(const Duration(days: 10, hours: 3)),
        itemsCount: 2,
        subtotal: 110,
        discount: 10,
        total: 100,
        paid: 0,
        method: PaymentMethod.cash,
      ),
    ];
    _movements = [
      CashMovement(
        id: 3,
        type: CashMovementType.sale,
        description: 'فاتورة بيع INV-1002',
        date: now.subtract(const Duration(days: 6)),
        amount: 90,
      ),
      CashMovement(
        id: 2,
        type: CashMovementType.expense,
        description: 'فاتورة كهرباء',
        date: now.subtract(const Duration(days: 8)),
        amount: -40,
      ),
      CashMovement(
        id: 1,
        type: CashMovementType.deposit,
        description: 'رصيد افتتاحي',
        date: now.subtract(const Duration(days: 12)),
        amount: 200,
      ),
    ];
  }

  late List<SaleInvoice> _sales;
  late List<CashMovement> _movements;

  static const _catalog = [
    SaleItemOption(id: 1, name: 'Panadol Extra 500mg', barcode: '6221031234567', price: 18, stock: 40),
    SaleItemOption(id: 2, name: 'Baby Diaper Cream', barcode: '6221039876543', price: 50, stock: 12),
    SaleItemOption(id: 3, name: 'Amoxicillin 500mg', barcode: '6221035551234', price: 22.5, stock: 2),
    SaleItemOption(id: 4, name: 'Vitamin C 1000mg', barcode: '6221037778888', price: 35, stock: 25),
  ];

  @override
  Future<ApiResult<AccountingOverview>> getOverview({
    required String token,
    required SalesPeriod period,
  }) async {
    final days = switch (period) {
      SalesPeriod.today => 1,
      SalesPeriod.last7Days => 7,
      SalesPeriod.last30Days => 30,
      SalesPeriod.thisMonth => DateTime.now().day,
    };
    final points = [
      for (var i = 0; i < (days == 1 ? 6 : days); i++)
        SalesPoint(
          label: '${i + 1}',
          amount: [40.0, 0.0, 120.0, 85.0, 60.0, 150.0, 90.0][i % 7] + (i ~/ 7) * 10,
        ),
    ];
    final cash = _balance;
    return Success(
      AccountingOverview(
        todaySales: 0,
        todayPurchases: 0,
        todayExpenses: 0,
        todayProfit: 0,
        cashBalance: cash,
        outstandingDebts: _sales.fold<double>(0, (sum, s) => sum + s.remaining),
        period: period,
        salesTrend: points,
        expenses: const [
          ExpenseSlice(category: 'كهرباء', amount: 40),
          ExpenseSlice(category: 'رواتب', amount: 120),
          ExpenseSlice(category: 'إيجار', amount: 80),
        ],
        alerts: [
          const AccountingAlert(
            kind: AccountingAlertKind.overdueDebt,
            title: 'دين عميل متأخر',
            message: 'متأخر 4 أيام – محمد قالع',
          ),
          if (cash < _safeLimit)
            AccountingAlert(
              kind: AccountingAlertKind.lowCash,
              title: 'رصيد الصندوق منخفض',
              message: 'الرصيد الحالي ${cash.toStringAsFixed(2)} ₪ – أقل من الحد الآمن',
            ),
          const AccountingAlert(
            kind: AccountingAlertKind.lowStock,
            title: 'مخزون منخفض',
            message: 'Amoxicillin 500mg – بقي 2 وحدة',
          ),
        ],
        recentTransactions: [
          for (final sale in _sales)
            AccountingTransaction(
              reference: sale.number,
              description: 'فاتورة بيع – ${sale.itemsCount} صنف',
              amount: sale.total,
              method: sale.method,
              status: sale.status,
              date: sale.date,
            ),
        ],
      ),
    );
  }

  @override
  Future<ApiResult<List<SaleInvoice>>> getSales({required String token}) async =>
      Success(List.of(_sales));

  @override
  Future<ApiResult<List<RefundRecord>>> getRefunds({required String token}) async =>
      const Success(<RefundRecord>[]);

  static const _safeLimit = 100.0;

  double get _balance => _movements.fold<double>(0, (sum, m) => sum + m.amount);

  @override
  Future<ApiResult<CashLedger>> getCashLedger({required String token}) async => Success(
    CashLedger(balance: _balance, safeLimit: _safeLimit, movements: List.of(_movements)),
  );

  @override
  Future<ApiResult<void>> recordCashMovement({
    required String token,
    required bool isDeposit,
    required double amount,
    required String reason,
  }) async {
    _movements.insert(
      0,
      CashMovement(
        id: DateTime.now().millisecondsSinceEpoch,
        type: isDeposit ? CashMovementType.deposit : CashMovementType.withdrawal,
        description: reason,
        date: DateTime.now(),
        amount: isDeposit ? amount : -amount,
      ),
    );
    return const Success(null);
  }

  @override
  Future<ApiResult<List<SaleItemOption>>> searchSaleItems({
    required String token,
    required String query,
  }) async {
    final q = query.toLowerCase();
    return Success([
      for (final item in _catalog)
        if (item.name.toLowerCase().contains(q)) item,
    ]);
  }

  @override
  Future<ApiResult<SaleItemOption?>> findByBarcode({
    required String token,
    required String barcode,
  }) async {
    for (final item in _catalog) {
      if (item.barcode == barcode) return Success(item);
    }
    return const Success(null);
  }

  @override
  Future<ApiResult<void>> createSale({required String token, required NewSale sale}) async {
    final total = sale.lines.fold<double>(0, (sum, line) => sum + line.total);
    final number = 1000 + _sales.length + 1;
    _sales.insert(
      0,
      SaleInvoice(
        id: number,
        number: 'INV-$number',
        date: DateTime.now(),
        customerName: sale.customerName,
        itemsCount: sale.lines.length,
        subtotal: total,
        total: total,
        paid: sale.paid,
        method: sale.method,
      ),
    );
    if (sale.paid > 0) {
      _movements.insert(
        0,
        CashMovement(
          id: DateTime.now().millisecondsSinceEpoch,
          type: CashMovementType.sale,
          description: 'فاتورة بيع INV-$number',
          date: DateTime.now(),
          amount: sale.paid,
        ),
      );
    }
    return const Success(null);
  }
}
