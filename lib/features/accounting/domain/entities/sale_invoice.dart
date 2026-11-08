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
  });

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
