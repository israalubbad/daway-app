import '../../domain/entities/accounting_customer.dart';
import '../../domain/entities/accounting_overview.dart';
import '../../domain/entities/sale_invoice.dart';

/// The state of "فاتورة بيع جديدة": the cart, the medicine search and what the
/// invoice summary holds.
class NewSaleState {
  final List<SaleLine> lines;
  final String query;
  final List<SaleItemOption> results;
  final bool isSearching;

  /// The medicine the last barcode matched ("تم التعرف على الدواء"), or the
  /// message to show when it matched nothing.
  final SaleItemOption? recognized;
  final String? barcodeMessage;

  /// The customer chosen for the invoice; null is the walk-in "زائر نقدي".
  final AccountingCustomer? customer;
  final List<AccountingCustomer> customerResults;

  /// What was paid. Null leaves it to the backend's default: everything for a
  /// cash, card or transfer sale, nothing for a sale on credit.
  final double? paid;
  final PaymentMethod method;
  final bool isSaving;
  final String? errorMessage;
  final bool completed;

  const NewSaleState({
    this.lines = const [],
    this.query = '',
    this.results = const [],
    this.isSearching = false,
    this.recognized,
    this.barcodeMessage,
    this.customer,
    this.customerResults = const [],
    this.paid,
    this.method = PaymentMethod.cash,
    this.isSaving = false,
    this.errorMessage,
    this.completed = false,
  });

  double get subtotal => lines.fold(0, (sum, line) => sum + line.total);

  /// There is no discount or tax in the invoice yet, so the total is the
  /// subtotal.
  double get total => subtotal;

  /// What will be recorded as paid.
  double get effectivePaid {
    final typed = paid;
    if (typed != null) return typed.clamp(0, total).toDouble();
    return method == PaymentMethod.credit ? 0 : total;
  }

  double get remaining => (total - effectivePaid).clamp(0, double.infinity).toDouble();

  int get itemsCount => lines.length;

  bool get canSubmit => lines.isNotEmpty && !isSaving;

  NewSaleState copyWith({
    List<SaleLine>? lines,
    String? query,
    List<SaleItemOption>? results,
    bool? isSearching,
    SaleItemOption? recognized,
    bool clearRecognized = false,
    String? barcodeMessage,
    bool clearBarcodeMessage = false,
    AccountingCustomer? customer,
    bool clearCustomer = false,
    List<AccountingCustomer>? customerResults,
    double? paid,
    bool clearPaid = false,
    PaymentMethod? method,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
    bool? completed,
  }) {
    return NewSaleState(
      lines: lines ?? this.lines,
      query: query ?? this.query,
      results: results ?? this.results,
      isSearching: isSearching ?? this.isSearching,
      recognized: clearRecognized ? null : (recognized ?? this.recognized),
      barcodeMessage: clearBarcodeMessage ? null : (barcodeMessage ?? this.barcodeMessage),
      customer: clearCustomer ? null : (customer ?? this.customer),
      customerResults: customerResults ?? this.customerResults,
      paid: clearPaid ? null : (paid ?? this.paid),
      method: method ?? this.method,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      completed: completed ?? this.completed,
    );
  }
}
