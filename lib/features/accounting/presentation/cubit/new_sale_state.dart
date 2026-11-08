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

  /// Null means the walk-in "زائر نقدي".
  final String? customerName;
  final double paid;
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
    this.customerName,
    this.paid = 0,
    this.method = PaymentMethod.cash,
    this.isSaving = false,
    this.errorMessage,
    this.completed = false,
  });

  double get subtotal => lines.fold(0, (sum, line) => sum + line.total);

  /// There is no discount or tax in the invoice yet, so the total is the
  /// subtotal.
  double get total => subtotal;

  double get remaining => (total - paid).clamp(0, double.infinity).toDouble();

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
    String? customerName,
    bool clearCustomer = false,
    double? paid,
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
      customerName: clearCustomer ? null : (customerName ?? this.customerName),
      paid: paid ?? this.paid,
      method: method ?? this.method,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      completed: completed ?? this.completed,
    );
  }
}
