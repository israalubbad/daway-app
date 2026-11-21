import '../../../../core/erroring/failure.dart';
import '../../../../core/helpers/api_result.dart';
import '../../../../core/helpers/json_list_extractor.dart';
import '../../../../core/helpers/json_parsing.dart';
import '../../../../core/helpers/server_timestamp.dart';
import '../../domain/entities/accounting_customer.dart';
import '../../domain/entities/accounting_overview.dart';
import '../../domain/entities/cash_ledger.dart';
import '../../domain/entities/refund_record.dart';
import '../../domain/entities/sale_invoice.dart';

import '../../../../core/localization/translations.dart';

/// Parsers of the accounting responses, written against the shapes the
/// "Pharmacy Accounting + Barcode Scanner" Postman collection documents.
/// Amounts may arrive as numbers or as decimal strings ("25.00").

// ---------------------------------------------------------------- helpers

DateTime _date(Object? value) => tryParseServerTimestamp(jsonString(value)) ?? DateTime.now();

/// The `data` object of a response, or the body itself when it has none.
Map<String, dynamic> dataOf(Object? body) {
  final map = jsonMap(body);
  if (map == null) throw FormatException('Unexpected response: $body');
  return jsonMap(map['data']) ?? map;
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

PaymentMethod paymentMethodFrom(Object? raw) => switch (jsonString(raw)) {
  'card' => PaymentMethod.card,
  'bank_transfer' => PaymentMethod.bankTransfer,
  'credit' => PaymentMethod.credit,
  _ => PaymentMethod.cash,
};

PaymentStatus? paymentStatusFrom(Object? raw) => switch (jsonString(raw)) {
  'paid' => PaymentStatus.paid,
  'partially_paid' || 'partial' => PaymentStatus.partial,
  'unpaid' => PaymentStatus.unpaid,
  'refunded' => PaymentStatus.refunded,
  'cancelled' || 'canceled' => PaymentStatus.cancelled,
  _ => null,
};

CashMovementType cashTypeFrom(Object? sourceType) => switch (jsonString(sourceType)) {
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
    final map = jsonMap(kpi);
    final key = jsonString(map?['key']);
    final value = jsonDouble(map?['value']);
    if (key != null && value != null) kpis[key] = value;
  }

  final series = jsonMap(jsonMap(data['series'])?[overviewRangeOf(period)]);
  final labels = series?['labels'] as List? ?? const [];
  final values = series?['data'] as List? ?? const [];
  final trend = [
    for (var i = 0; i < labels.length && i < values.length; i++)
      SalesPoint(label: '${labels[i]}', amount: jsonDouble(values[i]) ?? 0),
  ];

  final expenses = <ExpenseSlice>[];
  for (final slice in data['expense_breakdown'] as List? ?? const []) {
    final map = jsonMap(slice);
    if (map == null) continue;
    final amount = jsonDouble(map['amount']);
    if (amount == null) continue;
    expenses.add(
      ExpenseSlice(
        category: jsonString(map['label']) ?? jsonString(map['category']) ?? '',
        amount: amount,
      ),
    );
  }

  final alerts = <AccountingAlert>[];
  for (final alert in data['alerts'] as List? ?? const []) {
    final map = jsonMap(alert);
    if (map == null) continue;
    final href = jsonString(map['href']) ?? '';
    alerts.add(
      AccountingAlert(
        kind: href.contains('cash')
            ? AccountingAlertKind.lowCash
            : (href.contains('debt') || href.contains('customer') || href.contains('sales'))
            ? AccountingAlertKind.overdueDebt
            : AccountingAlertKind.lowStock,
        title: jsonString(map['title']) ?? '',
        message: jsonString(map['description']) ?? '',
      ),
    );
  }

  final transactions = <AccountingTransaction>[];
  for (final transaction in data['recent_transactions'] as List? ?? const []) {
    final map = jsonMap(transaction);
    if (map == null) continue;
    transactions.add(
      AccountingTransaction(
        reference: jsonString(map['reference']) ?? '',
        description: jsonString(map['description']) ?? '',
        // Signed: a purchase or an expense comes as a negative amount.
        amount: jsonDouble(map['amount']) ?? 0,
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
    final map = jsonMap(item);
    if (map == null) continue;
    lines.add(
      InvoiceLine(
        itemId: jsonInt(map['id']) ?? 0,
        name: jsonString(map['medicine_name']) ?? '',
        quantity: jsonInt(map['quantity']) ?? 0,
        unitPrice: jsonDouble(map['unit_price']) ?? 0,
      ),
    );
  }
  return SaleInvoice(
    id: jsonInt(json['id']) ?? 0,
    number: jsonString(json['number']) ?? '',
    date: _date(json['date'] ?? json['sold_at']),
    customerId: jsonInt(json['customer_id']),
    customerName: customer is Map ? jsonString(customer['name']) : jsonString(customer),
    itemsCount: jsonInt(json['items_count']) ?? lines.length,
    subtotal: jsonDouble(json['subtotal']) ?? 0,
    discount: jsonDouble(json['discount']) ?? 0,
    total: jsonDouble(json['total']) ?? 0,
    paid: jsonDouble(json['paid']) ?? 0,
    method: paymentMethodFrom(json['method'] ?? json['payment_method']),
    statusOverride: paymentStatusFrom(json['status']),
    lines: lines,
  );
}

/// The lines that can still be returned: each one's quantity is the units left.
List<InvoiceLine> parseRefundableLines(Map<String, dynamic> data) {
  final lines = <InvoiceLine>[];
  for (final item in data['items'] as List? ?? const []) {
    final map = jsonMap(item);
    if (map == null) continue;
    final left = jsonInt(map['available_quantity']) ??
        ((jsonInt(map['original_quantity']) ?? 0) - (jsonInt(map['refunded_quantity']) ?? 0));
    if (left <= 0) continue;
    lines.add(
      InvoiceLine(
        itemId: jsonInt(map['id']) ?? 0,
        name: jsonString(map['medicine_name']) ?? '',
        quantity: left,
        unitPrice: jsonDouble(map['unit_price']) ?? 0,
      ),
    );
  }
  return lines;
}

/// A record of `GET /refunds`, which is a raw model: the invoice sits under
/// `sale`, the amount is a decimal string and there is no refund number.
RefundRecord parseRefund(Map<String, dynamic> json) {
  final sale = jsonMap(json['sale']);
  final id = jsonInt(json['id']) ?? 0;
  return RefundRecord(
    id: id,
    number: '#$id',
    invoiceNumber: jsonString(sale?['number']) ?? jsonString(json['sale_number']) ?? '',
    date: _date(json['refunded_at'] ?? json['created_at']),
    customerName: jsonString(sale?['customer_name']),
    amount: jsonDouble(json['amount']) ?? 0,
    status: jsonString(json['status']) == 'pending' ? RefundStatus.pending : RefundStatus.completed,
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
  final map = jsonMap(body);
  if (map == null) throw FormatException('Unexpected cash response: $body');
  final list = extractJsonList(map, source: 'GET /pharmacy/accounting/cash');
  final stats = jsonMap(map['stats']);

  final movements = <CashMovement>[];
  for (final record in list) {
    final json = jsonMap(record);
    if (json == null) continue;
    final amount = jsonDouble(json['amount']) ?? 0;
    final signed = jsonDouble(json['signed_amount']) ??
        (jsonString(json['direction']) == 'out' ? -amount.abs() : amount.abs());
    movements.add(
      CashMovement(
        id: jsonInt(json['id']) ?? 0,
        type: cashTypeFrom(json['source_type']),
        description: jsonString(json['description']) ?? jsonString(json['reason']) ?? '',
        date: _date(json['date']),
        amount: signed,
      ),
    );
  }
  return CashLedger(
    balance: jsonDouble(stats?['balance_now']) ?? 0,
    // Read from the response, not fixed in the app.
    safeLimit: jsonDouble(stats?['low_threshold']) ?? 0,
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
    final json = jsonMap(row);
    if (json == null) continue;
    final id = jsonInt(json['pharmacy_medicine_id']) ?? jsonInt(json['id']);
    if (id == null) continue;
    final catalog = jsonMap(json['medicine']) ?? const <String, dynamic>{};
    final name = jsonString(json['trade_name_ar']) ??
        jsonString(catalog['trade_name_ar']) ??
        jsonString(json['trade_name']) ??
        jsonString(catalog['trade_name']) ??
        jsonString(json['name']) ??
        '';
    if (name.isEmpty) continue;
    options.add(
      SaleItemOption(
        id: id,
        name: name,
        price: jsonDouble(json['price']) ?? 0,
        stock: jsonInt(json['quantity']) ?? 9999,
      ),
    );
  }
  return options;
}

/// `GET /pharmacy/accounting/barcode/{barcode}`: found items are sellable; a
/// known medicine that cannot be sold comes back as a failure saying why; an
/// unknown barcode is null.
ApiResult<SaleItemOption?> barcodeLookupResult(Map<String, dynamic> data, String barcode) {
  switch (jsonString(data['status'])) {
    case 'found':
      final medicine = jsonMap(data['medicine']) ?? const <String, dynamic>{};
      final id = jsonInt(data['pharmacy_medicine_id']);
      if (id == null) return const Success(null);
      return Success(
        SaleItemOption(
          id: id,
          name: jsonString(medicine['trade_name_ar']) ?? jsonString(medicine['trade_name']) ?? '',
          barcode: barcode,
          price: jsonDouble(data['price']) ?? 0,
          stock: jsonInt(data['quantity']) ?? 0,
        ),
      );
    case 'out_of_stock':
      return ApiError(ApiFailure(message: 'هذا الدواء غير متوفر في المخزون'.tr));
    case 'not_in_stock':
      return ApiError(ApiFailure(message: 'هذا الدواء غير مضاف إلى مخزون صيدليتك'.tr));
    case 'ambiguous':
      return ApiError(
        ApiFailure(message: 'أكثر من صنف يطابق هذا الباركود، ابحث عنه بالاسم'.tr),
      );
    default:
      return const Success(null);
  }
}

AccountingCustomer parseCustomer(Map<String, dynamic> json) {
  return AccountingCustomer(
    id: jsonInt(json['id']) ?? 0,
    name: jsonString(json['name']) ?? '',
    phone: jsonString(json['phone']),
    balance: jsonDouble(json['current_balance']) ?? 0,
  );
}
