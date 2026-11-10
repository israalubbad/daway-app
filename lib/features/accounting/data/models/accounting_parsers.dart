import '../../../../core/erroring/failure.dart';
import '../../../../core/helpers/api_result.dart';
import '../../../../core/helpers/json_list_extractor.dart';
import '../../../../core/helpers/server_timestamp.dart';
import '../../domain/entities/accounting_customer.dart';
import '../../domain/entities/accounting_overview.dart';
import '../../domain/entities/cash_ledger.dart';
import '../../domain/entities/refund_record.dart';
import '../../domain/entities/sale_invoice.dart';

/// Parsers of the accounting responses, written against the shapes the
/// "Pharmacy Accounting + Barcode Scanner" Postman collection documents.
/// Amounts may arrive as numbers or as decimal strings ("25.00").

// ---------------------------------------------------------------- helpers

double? _double(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? _int(Object? value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String? _string(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

Map<String, dynamic>? _map(Object? value) => value is Map<String, dynamic> ? value : null;

DateTime _date(Object? value) => tryParseServerTimestamp(_string(value)) ?? DateTime.now();

/// The `data` object of a response, or the body itself when it has none.
Map<String, dynamic> dataOf(Object? body) {
  final map = _map(body);
  if (map == null) throw FormatException('Unexpected response: $body');
  return _map(map['data']) ?? map;
}

// ---------------------------------------------------------- enum mapping

String overviewRangeOf(SalesPeriod period) => switch (period) {
  SalesPeriod.today => 'today',
  SalesPeriod.last7Days => '7d',
  SalesPeriod.last30Days => '30d',
  SalesPeriod.thisMonth => 'month',
};

String paymentMethodApiValue(PaymentMethod method) => switch (method) {
  PaymentMethod.cash => 'cash',
  PaymentMethod.card => 'card',
  PaymentMethod.bankTransfer => 'bank_transfer',
  PaymentMethod.credit => 'credit',
};

PaymentMethod paymentMethodFrom(Object? raw) => switch (_string(raw)) {
  'card' => PaymentMethod.card,
  'bank_transfer' => PaymentMethod.bankTransfer,
  'credit' => PaymentMethod.credit,
  _ => PaymentMethod.cash,
};

PaymentStatus? paymentStatusFrom(Object? raw) => switch (_string(raw)) {
  'paid' => PaymentStatus.paid,
  'partially_paid' || 'partial' => PaymentStatus.partial,
  'unpaid' => PaymentStatus.unpaid,
  'refunded' => PaymentStatus.refunded,
  'cancelled' || 'canceled' => PaymentStatus.cancelled,
  _ => null,
};

CashMovementType cashTypeFrom(Object? sourceType) => switch (_string(sourceType)) {
  'sale' => CashMovementType.sale,
  'expense' => CashMovementType.expense,
  'purchase' => CashMovementType.purchase,
  'customer_payment' || 'supplier_payment' => CashMovementType.payment,
  'refund' => CashMovementType.refund,
  'deposit' => CashMovementType.deposit,
  'withdrawal' => CashMovementType.withdrawal,
  _ => CashMovementType.adjustment,
};

// -------------------------------------------------------------- overview

AccountingOverview parseOverview(Map<String, dynamic> body, SalesPeriod period) {
  final data = dataOf(body);

  final kpis = <String, double>{};
  for (final kpi in data['kpis'] as List? ?? const []) {
    final map = _map(kpi);
    final key = _string(map?['key']);
    final value = _double(map?['value']);
    if (key != null && value != null) kpis[key] = value;
  }

  final series = _map(_map(data['series'])?[overviewRangeOf(period)]);
  final labels = series?['labels'] as List? ?? const [];
  final values = series?['data'] as List? ?? const [];
  final trend = [
    for (var i = 0; i < labels.length && i < values.length; i++)
      SalesPoint(label: '${labels[i]}', amount: _double(values[i]) ?? 0),
  ];

  final expenses = <ExpenseSlice>[];
  for (final slice in data['expense_breakdown'] as List? ?? const []) {
    final map = _map(slice);
    if (map == null) continue;
    final amount = _double(map['amount']);
    if (amount == null) continue;
    expenses.add(
      ExpenseSlice(
        category: _string(map['label']) ?? _string(map['category']) ?? '',
        amount: amount,
      ),
    );
  }

  final alerts = <AccountingAlert>[];
  for (final alert in data['alerts'] as List? ?? const []) {
    final map = _map(alert);
    if (map == null) continue;
    final href = _string(map['href']) ?? '';
    alerts.add(
      AccountingAlert(
        kind: href.contains('cash')
            ? AccountingAlertKind.lowCash
            : (href.contains('debt') || href.contains('customer') || href.contains('sales'))
            ? AccountingAlertKind.overdueDebt
            : AccountingAlertKind.lowStock,
        title: _string(map['title']) ?? '',
        message: _string(map['description']) ?? '',
      ),
    );
  }

  final transactions = <AccountingTransaction>[];
  for (final transaction in data['recent_transactions'] as List? ?? const []) {
    final map = _map(transaction);
    if (map == null) continue;
    transactions.add(
      AccountingTransaction(
        reference: _string(map['reference']) ?? '',
        description: _string(map['description']) ?? '',
        // Signed: a purchase or an expense comes as a negative amount.
        amount: _double(map['amount']) ?? 0,
        method: paymentMethodFrom(map['method']),
        status: paymentStatusFrom(map['status']) ?? PaymentStatus.paid,
        date: _date(map['date']),
      ),
    );
  }

  return AccountingOverview(
    todaySales: kpis['today_sales'] ?? 0,
    todayPurchases: kpis['today_purchases'] ?? 0,
    todayExpenses: kpis['today_expenses'] ?? 0,
    todayProfit: kpis['today_profit'] ?? 0,
    cashBalance: kpis['cash_balance'] ?? 0,
    outstandingDebts: kpis['outstanding_debts'] ?? 0,
    period: period,
    salesTrend: trend,
    expenses: expenses,
    alerts: alerts,
    recentTransactions: transactions,
  );
}

// ----------------------------------------------------------------- sales

SaleInvoice parseInvoice(Map<String, dynamic> json) {
  final customer = json['customer'];
  final lines = <InvoiceLine>[];
  for (final item in json['items'] as List? ?? const []) {
    final map = _map(item);
    if (map == null) continue;
    lines.add(
      InvoiceLine(
        itemId: _int(map['id']) ?? 0,
        name: _string(map['medicine_name']) ?? '',
        quantity: _int(map['quantity']) ?? 0,
        unitPrice: _double(map['unit_price']) ?? 0,
      ),
    );
  }
  return SaleInvoice(
    id: _int(json['id']) ?? 0,
    number: _string(json['number']) ?? '',
    date: _date(json['date'] ?? json['sold_at']),
    customerId: _int(json['customer_id']),
    customerName: customer is Map ? _string(customer['name']) : _string(customer),
    itemsCount: _int(json['items_count']) ?? lines.length,
    subtotal: _double(json['subtotal']) ?? 0,
    discount: _double(json['discount']) ?? 0,
    total: _double(json['total']) ?? 0,
    paid: _double(json['paid']) ?? 0,
    method: paymentMethodFrom(json['method'] ?? json['payment_method']),
    statusOverride: paymentStatusFrom(json['status']),
    lines: lines,
  );
}

/// The lines that can still be returned: each one's quantity is the units left.
List<InvoiceLine> parseRefundableLines(Map<String, dynamic> data) {
  final lines = <InvoiceLine>[];
  for (final item in data['items'] as List? ?? const []) {
    final map = _map(item);
    if (map == null) continue;
    final left = _int(map['available_quantity']) ??
        ((_int(map['original_quantity']) ?? 0) - (_int(map['refunded_quantity']) ?? 0));
    if (left <= 0) continue;
    lines.add(
      InvoiceLine(
        itemId: _int(map['id']) ?? 0,
        name: _string(map['medicine_name']) ?? '',
        quantity: left,
        unitPrice: _double(map['unit_price']) ?? 0,
      ),
    );
  }
  return lines;
}

/// A record of `GET /refunds`, which is a raw model: the invoice sits under
/// `sale`, the amount is a decimal string and there is no refund number.
RefundRecord parseRefund(Map<String, dynamic> json) {
  final sale = _map(json['sale']);
  final id = _int(json['id']) ?? 0;
  return RefundRecord(
    id: id,
    number: '#$id',
    invoiceNumber: _string(sale?['number']) ?? _string(json['sale_number']) ?? '',
    date: _date(json['refunded_at'] ?? json['created_at']),
    customerName: _string(sale?['customer_name']),
    amount: _double(json['amount']) ?? 0,
    status: _string(json['status']) == 'pending' ? RefundStatus.pending : RefundStatus.completed,
  );
}

Map<String, dynamic> saleRequestBody(NewSale sale) {
  return {
    'customer_id': sale.customerId,
    'items': [
      for (final line in sale.lines)
        {
          'pharmacy_medicine_id': line.item.id,
          'medicine_name': line.item.name,
          if (line.item.barcode != null) 'barcode': line.item.barcode,
          'unit_price': line.item.price,
          'quantity': line.quantity,
        },
    ],
    if (sale.paid != null) 'paid': sale.paid,
    'payment_method': paymentMethodApiValue(sale.method),
  };
}

// ------------------------------------------------------------------ cash

CashLedger parseCashLedger(Object? body) {
  final map = _map(body);
  if (map == null) throw FormatException('Unexpected cash response: $body');
  final list = extractJsonList(map, source: 'GET /pharmacy/accounting/cash');
  final stats = _map(map['stats']);

  final movements = <CashMovement>[];
  for (final record in list) {
    final json = _map(record);
    if (json == null) continue;
    final amount = _double(json['amount']) ?? 0;
    final signed = _double(json['signed_amount']) ??
        (_string(json['direction']) == 'out' ? -amount.abs() : amount.abs());
    movements.add(
      CashMovement(
        id: _int(json['id']) ?? 0,
        type: cashTypeFrom(json['source_type']),
        description: _string(json['description']) ?? _string(json['reason']) ?? '',
        date: _date(json['date']),
        amount: signed,
      ),
    );
  }
  return CashLedger(
    balance: _double(stats?['balance_now']) ?? 0,
    // Read from the response, not fixed in the app.
    safeLimit: _double(stats?['low_threshold']) ?? 0,
    movements: movements,
  );
}

// -------------------------------------------------- medicines & customers

/// `GET /pharmacy/medicines/search`: the pharmacy's own stock rows under
/// `data.medicines`. A row with no stock count is offered with a large one, so
/// it is not refused on a number the response did not give; the backend checks
/// the stock when the sale is saved.
List<SaleItemOption> parseStockSearch(Object? body) {
  final data = dataOf(body);
  final rows = data['medicines'] as List? ?? const [];
  final options = <SaleItemOption>[];
  for (final row in rows) {
    final json = _map(row);
    if (json == null) continue;
    final id = _int(json['pharmacy_medicine_id']) ?? _int(json['id']);
    if (id == null) continue;
    final catalog = _map(json['medicine']) ?? const <String, dynamic>{};
    final name = _string(json['trade_name_ar']) ??
        _string(catalog['trade_name_ar']) ??
        _string(json['trade_name']) ??
        _string(catalog['trade_name']) ??
        _string(json['name']) ??
        '';
    if (name.isEmpty) continue;
    options.add(
      SaleItemOption(
        id: id,
        name: name,
        price: _double(json['price']) ?? 0,
        stock: _int(json['quantity']) ?? 9999,
      ),
    );
  }
  return options;
}

/// `GET /pharmacy/accounting/barcode/{barcode}`: found items are sellable; a
/// known medicine that cannot be sold comes back as a failure saying why; an
/// unknown barcode is null.
ApiResult<SaleItemOption?> barcodeLookupResult(Map<String, dynamic> data, String barcode) {
  switch (_string(data['status'])) {
    case 'found':
      final medicine = _map(data['medicine']) ?? const <String, dynamic>{};
      final id = _int(data['pharmacy_medicine_id']);
      if (id == null) return const Success(null);
      return Success(
        SaleItemOption(
          id: id,
          name: _string(medicine['trade_name_ar']) ?? _string(medicine['trade_name']) ?? '',
          barcode: barcode,
          price: _double(data['price']) ?? 0,
          stock: _int(data['quantity']) ?? 0,
        ),
      );
    case 'out_of_stock':
      return const ApiError(ApiFailure(message: 'هذا الدواء غير متوفر في المخزون'));
    case 'not_in_stock':
      return const ApiError(ApiFailure(message: 'هذا الدواء غير مضاف إلى مخزون صيدليتك'));
    case 'ambiguous':
      return const ApiError(
        ApiFailure(message: 'أكثر من صنف يطابق هذا الباركود، ابحث عنه بالاسم'),
      );
    default:
      return const Success(null);
  }
}

AccountingCustomer parseCustomer(Map<String, dynamic> json) {
  return AccountingCustomer(
    id: _int(json['id']) ?? 0,
    name: _string(json['name']) ?? '',
    phone: _string(json['phone']),
    balance: _double(json['current_balance']) ?? 0,
  );
}
