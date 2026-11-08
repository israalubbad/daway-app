import '../../domain/entities/accounting_overview.dart';
import '../../domain/entities/sale_invoice.dart';

/// The date ranges the sales and cash filters offer.
enum DateRangeFilter { all, today, last7Days, thisMonth }

extension DateRangeFilterX on DateRangeFilter {
  bool contains(DateTime date, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return switch (this) {
      DateRangeFilter.all => true,
      DateRangeFilter.today => !date.isBefore(today),
      DateRangeFilter.last7Days => !date.isBefore(today.subtract(const Duration(days: 6))),
      DateRangeFilter.thisMonth => date.year == now.year && date.month == now.month,
    };
  }
}

sealed class SalesState {
  const SalesState();
}

class SalesLoading extends SalesState {
  const SalesLoading();
}

class SalesLoadFailure extends SalesState {
  final String message;

  const SalesLoadFailure(this.message);
}

class SalesLoaded extends SalesState {
  final List<SaleInvoice> all;
  final String query;
  final DateRangeFilter range;
  final PaymentMethod? method;
  final PaymentStatus? status;

  const SalesLoaded({
    required this.all,
    this.query = '',
    this.range = DateRangeFilter.all,
    this.method,
    this.status,
  });

  /// How many of the three dropdown filters are set — the badge on the
  /// filters button.
  int get activeFilters =>
      (range != DateRangeFilter.all ? 1 : 0) + (method != null ? 1 : 0) + (status != null ? 1 : 0);

  List<SaleInvoice> get visible {
    final q = query.trim().toLowerCase();
    final now = DateTime.now();
    return [
      for (final sale in all)
        if ((q.isEmpty ||
                sale.number.toLowerCase().contains(q) ||
                (sale.customerName ?? '').toLowerCase().contains(q)) &&
            range.contains(sale.date, now) &&
            (method == null || sale.method == method) &&
            (status == null || sale.status == status))
          sale,
    ];
  }

  double get totalAmount => visible.fold(0, (sum, s) => sum + s.total);
  double get paidAmount => visible.fold(0, (sum, s) => sum + s.paid);
  double get remainingAmount => visible.fold(0, (sum, s) => sum + s.remaining);

  SalesLoaded copyWith({
    List<SaleInvoice>? all,
    String? query,
    DateRangeFilter? range,
    PaymentMethod? method,
    PaymentStatus? status,
    bool clearMethod = false,
    bool clearStatus = false,
  }) {
    return SalesLoaded(
      all: all ?? this.all,
      query: query ?? this.query,
      range: range ?? this.range,
      method: clearMethod ? null : (method ?? this.method),
      status: clearStatus ? null : (status ?? this.status),
    );
  }
}
