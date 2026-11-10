import 'accounting_overview.dart';

/// A sales invoice, as the sales list shows it.
class SaleInvoice {
  final int id;

  /// "INV-1002".
  final String number;
  final DateTime date;

  /// Null for a walk-in cash customer.
  final String? customerName;
  final int itemsCount;
  final double subtotal;
  final double discount;
  final double total;
  final double paid;
  final PaymentMethod method;

  /// What was sold, line by line. A list response may leave it out.
  final List<InvoiceLine> lines;

  const SaleInvoice({
    required this.id,
    required this.number,
    required this.date,
    this.customerName,
    required this.itemsCount,
    required this.subtotal,
    this.discount = 0,
    required this.total,
    required this.paid,
    required this.method,
    this.lines = const [],
  });

  /// This invoice after [amount] more was paid by [method].
  SaleInvoice withPayment(double amount, PaymentMethod method) => SaleInvoice(
    id: id,
    number: number,
    date: date,
    customerName: customerName,
    itemsCount: itemsCount,
    subtotal: subtotal,
    discount: discount,
    total: total,
    paid: paid + amount,
    method: method,
    lines: lines,
  );

  double get remaining => (total - paid).clamp(0, double.infinity).toDouble();

  PaymentStatus get status {
    if (paid <= 0) return PaymentStatus.unpaid;
    return paid >= total ? PaymentStatus.paid : PaymentStatus.partial;
  }
}

/// A sale being made: what the cart holds and how it is paid.
class NewSale {
  final String? customerName;
  final List<SaleLine> lines;
  final double paid;
  final PaymentMethod method;

  const NewSale({
    this.customerName,
    required this.lines,
    required this.paid,
    required this.method,
  });
}

/// A medicine that can be put in the cart (a hit of the search or the barcode).
class SaleItemOption {
  final int id;
  final String name;
  final String? barcode;
  final double price;

  /// Units in stock.
  final int stock;

  const SaleItemOption({
    required this.id,
    required this.name,
    this.barcode,
    required this.price,
    required this.stock,
  });
}

/// One line of the cart: [item] and how many units.
class SaleLine {
  final SaleItemOption item;
  final int quantity;

  const SaleLine({required this.item, required this.quantity});

  double get total => item.price * quantity;

  SaleLine withQuantity(int quantity) => SaleLine(item: item, quantity: quantity);
}

/// One line of an invoice: what was sold, how many and at what price.
class InvoiceLine {
  /// The medicine's id, what a return refers to.
  final int itemId;
  final String name;
  final int quantity;
  final double unitPrice;

  const InvoiceLine({
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => unitPrice * quantity;
}

/// A return of some units of an invoice's lines: item id to units given back.
class RefundRequest {
  final SaleInvoice invoice;
  final Map<int, int> quantities;

  const RefundRequest({required this.invoice, required this.quantities});

  /// What is paid back: each returned unit at the price it was sold for.
  double get amount {
    var sum = 0.0;
    for (final line in invoice.lines) {
      sum += line.unitPrice * (quantities[line.itemId] ?? 0);
    }
    return sum;
  }

  int get unitsCount => quantities.values.fold(0, (a, b) => a + b);

  /// At least one unit, and no line returned beyond what was sold.
  bool get isValid =>
      unitsCount > 0 &&
      quantities.entries.every((e) {
        final line = invoice.lines.where((l) => l.itemId == e.key);
        return e.value >= 0 && line.isNotEmpty && e.value <= line.first.quantity;
      });
}

/// What a payment recorded against an invoice must satisfy.
abstract class PaymentRules {
  static bool isValidAmount(double amount, {required double remaining}) =>
      amount > 0 && amount <= remaining;
}
