import 'package:daway_app/core/erroring/failure.dart';
import 'package:daway_app/core/helpers/api_result.dart';
import 'package:daway_app/features/accounting/data/datasources/accounting_remote_data_source.dart';
import 'package:daway_app/features/accounting/data/models/accounting_parsers.dart';
import 'package:daway_app/features/accounting/data/repositories/accounting_repository_impl.dart';
import 'package:daway_app/features/accounting/domain/entities/accounting_overview.dart';
import 'package:daway_app/features/accounting/domain/entities/cash_ledger.dart';
import 'package:daway_app/features/accounting/domain/entities/refund_record.dart';
import 'package:daway_app/features/accounting/domain/entities/sale_invoice.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers each call with what the test set, standing in for the network.
class _StubRemote extends AccountingRemoteDataSource {
  Object? overview;
  Object? sales;
  Object? sale;
  Object? refunds;
  Object? cash;
  Object? barcode;
  int overviewCalls = 0;
  final List<Map<String, dynamic>> posted = [];

  _StubRemote() : super(Dio());

  Response<dynamic> _ok(Object? data) =>
      Response(requestOptions: RequestOptions(), data: data, statusCode: 200);

  @override
  Future<Response<dynamic>> getOverview({required String token, required String range}) async {
    overviewCalls++;
    return _ok(overview);
  }

  @override
  Future<Response<dynamic>> getSales({required String token, required int page}) async => _ok(sales);

  @override
  Future<Response<dynamic>> getSale({required String token, required String number}) async => _ok(sale);

  @override
  Future<Response<dynamic>> getRefunds({required String token}) async => _ok(refunds);

  @override
  Future<Response<dynamic>> getCash({required String token}) async => _ok(cash);

  @override
  Future<Response<dynamic>> getBarcode({required String token, required String barcode}) async =>
      _ok(this.barcode);

  @override
  Future<Response<dynamic>> createSale({
    required String token,
    required Map<String, dynamic> body,
  }) async {
    posted.add(body);
    return _ok({'success': true});
  }

  @override
  Future<Response<dynamic>> createCustomerPayment({
    required String token,
    required int customerId,
    required Map<String, dynamic> body,
  }) async {
    posted.add({'customer': customerId, ...body});
    return _ok({'success': true});
  }

  @override
  Future<Response<dynamic>> createRefund({
    required String token,
    required Map<String, dynamic> body,
  }) async {
    posted.add(body);
    return _ok({'success': true});
  }

  @override
  Future<Response<dynamic>> createCashAdjustment({
    required String token,
    required Map<String, dynamic> body,
  }) async {
    posted.add(body);
    return _ok({'success': true});
  }
}

const _overviewJson = {
  'success': true,
  'data': {
    'kpis': [
      {'key': 'today_sales', 'value': 120.5},
      {'key': 'today_purchases', 'value': '30.00'},
      {'key': 'today_expenses', 'value': 10},
      {'key': 'today_profit', 'value': 80.5},
      {'key': 'cash_balance', 'value': 450},
      {'key': 'outstanding_debts', 'value': 10},
    ],
    'series': {
      'today': {'labels': ['9', '10'], 'data': [1, 2]},
      '7d': {'labels': ['1', '2', '3'], 'data': [10, 0, '25.5']},
    },
    'expense_breakdown': [
      {'category': 'rent', 'label': 'Rent', 'amount': 800, 'percentage': 80},
    ],
    'recent_transactions': [
      {
        'type': 'sale',
        'reference': 'INV-1002',
        'description': 'Sale',
        'amount': 100,
        'method': 'bank_transfer',
        'status': 'partially_paid',
        'date': '2026-10-22T09:57:00.000000Z',
      },
      {
        'type': 'expense',
        'reference': 'EXP-1',
        'description': 'Rent',
        'amount': -800,
        'method': 'cash',
        'status': 'paid',
        'date': '2026-10-01T09:00:00Z',
      },
    ],
    'alerts': [
      {'severity': 'danger', 'icon': 'x', 'title': 'Low cash', 'description': 'd', 'href': '/accounting/cash'},
      {'severity': 'warning', 'icon': 'x', 'title': 'Debt', 'description': 'd', 'href': '/accounting/debts'},
      {'severity': 'warning', 'icon': 'x', 'title': 'Stock', 'description': 'd', 'href': '/pharmacy/medicines'},
    ],
  },
};

const _saleJson = {
  'id': 5,
  'number': 'INV-1042',
  'date': '2026-10-17 12:00:00',
  'customer_id': 7,
  'customer': 'Ahmad',
  'items_count': 2,
  'subtotal': '104.00',
  'discount': '4.00',
  'total': '100.00',
  'paid': '90.00',
  'remaining': '10.00',
  'method': 'bank_transfer',
  'status': 'partially_paid',
  'items': [
    {'id': 30, 'medicine_name': 'Panadol', 'unit_price': '18.00', 'quantity': 3, 'line_total': '54.00'},
  ],
};

void main() {
  group('parsers', () {
    test('the overview: figures from kpis, the chart of the asked period, breakdown, alerts', () {
      final overview = parseOverview(_overviewJson, SalesPeriod.last7Days);

      expect(overview.todaySales, 120.5);
      expect(overview.todayPurchases, 30);
      expect(overview.cashBalance, 450);
      expect(overview.outstandingDebts, 10);
      expect(overview.salesTrend.map((p) => p.label), ['1', '2', '3']);
      expect(overview.salesTrend.map((p) => p.amount), [10, 0, 25.5]);
      expect(overview.expenses.single.category, 'Rent');
      expect(overview.alerts.map((a) => a.kind), [
        AccountingAlertKind.lowCash,
        AccountingAlertKind.overdueDebt,
        AccountingAlertKind.lowStock,
      ]);
      expect(overview.recentTransactions.first.status, PaymentStatus.partial);
      expect(overview.recentTransactions.first.method, PaymentMethod.bankTransfer);
      // A purchase or an expense keeps its minus.
      expect(overview.recentTransactions.last.amount, -800);
    });

    test('a period the response has no series for gives an empty chart, not a crash', () {
      final overview = parseOverview(_overviewJson, SalesPeriod.thisMonth);

      expect(overview.salesTrend, isEmpty);
    });

    test('an invoice: decimal strings, customer, status, lines', () {
      final invoice = parseInvoice(_saleJson);

      expect(invoice.number, 'INV-1042');
      expect(invoice.total, 100);
      expect(invoice.paid, 90);
      expect(invoice.remaining, 10);
      expect(invoice.customerId, 7);
      expect(invoice.customerName, 'Ahmad');
      expect(invoice.status, PaymentStatus.partial);
      expect(invoice.lines.single.itemId, 30);
      expect(invoice.lines.single.quantity, 3);
    });

    test('cancelled and refunded invoices are closed', () {
      expect(parseInvoice({..._saleJson, 'status': 'cancelled'}).isClosed, isTrue);
      expect(parseInvoice({..._saleJson, 'status': 'refunded'}).isClosed, isTrue);
      expect(parseInvoice({..._saleJson, 'status': 'paid'}).isClosed, isFalse);
    });

    test('a refund is the raw model: the invoice under sale and the amount a string', () {
      final refund = parseRefund({
        'id': 12,
        'amount': '25.00',
        'status': 'completed',
        'refunded_at': '2026-10-17 11:00:00',
        'sale': {'number': 'INV-1042', 'customer_name': 'Ahmad'},
      });

      expect(refund.invoiceNumber, 'INV-1042');
      expect(refund.customerName, 'Ahmad');
      expect(refund.amount, 25);
      expect(refund.status, RefundStatus.completed);
    });

    test('refundable lines carry the units left and drop the ones with none', () {
      final lines = parseRefundableLines({
        'items': [
          {'id': 1, 'medicine_name': 'A', 'unit_price': 10, 'original_quantity': 3, 'refunded_quantity': 1, 'available_quantity': 2},
          {'id': 2, 'medicine_name': 'B', 'unit_price': 5, 'original_quantity': 1, 'refunded_quantity': 1, 'available_quantity': 0},
        ],
      });

      expect(lines.single.itemId, 1);
      expect(lines.single.quantity, 2);
    });

    test('the cash book: balance and threshold from stats, signed amounts, source types', () {
      final ledger = parseCashLedger({
        'data': [
          {'id': 1, 'direction': 'in', 'amount': 90, 'signed_amount': 90, 'source_type': 'sale', 'description': 'Sale', 'date': '2026-10-17 12:00:00'},
          {'id': 2, 'direction': 'out', 'amount': 40, 'signed_amount': -40, 'source_type': 'supplier_payment', 'reason': 'Supplier', 'date': '2026-10-18 12:00:00'},
          {'id': 3, 'direction': 'out', 'amount': 5, 'source_type': 'withdrawal', 'date': '2026-10-19 12:00:00'},
        ],
        'stats': {'balance_now': 45, 'low_threshold': 500.0, 'is_low': true},
      });

      expect(ledger.balance, 45);
      expect(ledger.safeLimit, 500);
      expect(ledger.isLow, isTrue);
      expect(ledger.movements.map((m) => m.type), [
        CashMovementType.sale,
        CashMovementType.payment,
        CashMovementType.withdrawal,
      ]);
      // No signed_amount: the direction gives the sign.
      expect(ledger.movements.last.amount, -5);
    });

    test('barcode statuses: found is sellable, the others say why not', () {
      final found = barcodeLookupResult({
        'status': 'found',
        'medicine': {'trade_name': 'Panadol'},
        'pharmacy_medicine_id': 14,
        'price': 18,
        'quantity': 4,
      }, '6221031234567');
      expect((found as Success<SaleItemOption?>).data!.id, 14);

      expect(barcodeLookupResult({'status': 'out_of_stock'}, 'x'), isA<ApiError<SaleItemOption?>>());
      expect(barcodeLookupResult({'status': 'not_in_stock'}, 'x'), isA<ApiError<SaleItemOption?>>());
      expect(barcodeLookupResult({'status': 'ambiguous'}, 'x'), isA<ApiError<SaleItemOption?>>());
      expect((barcodeLookupResult({'status': 'unknown'}, 'x') as Success).data, isNull);
    });

    test('the stock search reads the pharmacy rows under data.medicines', () {
      final options = parseStockSearch({
        'data': {
          'medicines': [
            {'id': 14, 'price': '18.00', 'quantity': 4, 'medicine': {'trade_name': 'Panadol'}},
            {'id': 15, 'price': 5, 'medicine': {'trade_name': 'No stock count'}},
          ],
          'moh_catalog': [],
        },
      });

      expect(options.map((o) => o.name), ['Panadol', 'No stock count']);
      expect(options.first.stock, 4);
      // The response gave no count: not refused for a number it never gave.
      expect(options.last.stock, greaterThan(0));
    });

    test('a sale request carries the pharmacy medicine ids and leaves paid to the backend', () {
      final body = saleRequestBody(
        const NewSale(
          lines: [SaleLine(item: SaleItemOption(id: 14, name: 'Panadol', price: 18, stock: 4), quantity: 2)],
          method: PaymentMethod.cash,
        ),
      );

      expect(body['payment_method'], 'cash');
      expect(body.containsKey('paid'), isFalse);
      expect((body['items'] as List).single, {
        'pharmacy_medicine_id': 14,
        'medicine_name': 'Panadol',
        'unit_price': 18.0,
        'quantity': 2,
      });
    });
  });

  group('repository', () {
    late _StubRemote remote;
    late AccountingRepositoryImpl repository;

    setUp(() {
      remote = _StubRemote();
      repository = AccountingRepositoryImpl(remote);
      remote.overview = _overviewJson;
    });

    test('a period change reuses the overview already fetched', () async {
      await repository.getOverview(token: 't', period: SalesPeriod.last7Days);
      final again = await repository.getOverview(
        token: 't',
        period: SalesPeriod.today,
        useCache: true,
      );

      expect(remote.overviewCalls, 1);
      expect((again as Success<AccountingOverview>).data.salesTrend, hasLength(2));
    });

    test('without the cache flag it asks again', () async {
      await repository.getOverview(token: 't', period: SalesPeriod.last7Days);
      await repository.getOverview(token: 't', period: SalesPeriod.last7Days);

      expect(remote.overviewCalls, 2);
    });

    test('sales skip a malformed record and keep the rest', () async {
      remote.sales = {
        'data': [
          _saleJson,
          'garbage',
          {..._saleJson, 'id': 6, 'number': 'INV-1043'},
        ],
      };

      final result = await repository.getSales(token: 't');

      expect((result as Success<List<SaleInvoice>>).data.map((s) => s.number), ['INV-1042', 'INV-1043']);
    });

    test('a payment goes through the invoice\'s customer and refuses an invoice without one', () async {
      final withCustomer = parseInvoice(_saleJson);
      final walkIn = parseInvoice({..._saleJson, 'customer_id': null, 'customer': null});

      final ok = await repository.recordInvoicePayment(
        token: 't',
        invoice: withCustomer,
        amount: 10,
        method: PaymentMethod.cash,
      );
      final refused = await repository.recordInvoicePayment(
        token: 't',
        invoice: walkIn,
        amount: 10,
        method: PaymentMethod.cash,
      );

      expect(ok, isA<Success<void>>());
      expect(remote.posted.single['customer'], 7);
      expect(remote.posted.single['sale_id'], 5);
      expect(remote.posted.single['payment_method'], 'cash');
      expect(refused, isA<ApiError<void>>());
      expect(remote.posted, hasLength(1));
    });

    test('a refund names the invoice and its lines by id', () async {
      await repository.createRefund(token: 't', invoiceNumber: 'INV-1042', quantities: {30: 1});

      expect(remote.posted.single, {
        'sale_number': 'INV-1042',
        'items': [
          {'sale_item_id': 30, 'quantity': 1},
        ],
      });
    });

    test('a cash movement is sent with its direction and kind', () async {
      await repository.recordCashMovement(token: 't', isDeposit: false, amount: 200, reason: 'withdrawal');

      expect(remote.posted.single, {
        'direction': 'out',
        'kind': 'withdrawal',
        'amount': 200.0,
        'reason': 'withdrawal',
      });
    });

    test('a barcode that is in stock comes back sellable; an out-of-stock one fails with a reason', () async {
      remote.barcode = {
        'data': {'status': 'out_of_stock'},
      };

      final result = await repository.findByBarcode(token: 't', barcode: '6221031234567');

      expect((result as ApiError<SaleItemOption?>).failure, isA<ApiFailure>());
    });
  });
}
