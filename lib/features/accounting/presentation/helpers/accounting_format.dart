import '../../domain/entities/accounting_overview.dart';
import '../../domain/entities/cash_ledger.dart';
import '../../domain/entities/refund_record.dart';
import '../cubit/cash_state.dart';
import '../cubit/sales_state.dart';

/// An amount in shekels, always with two decimals: "₪100.00". Set it
/// left-to-right when it is drawn, so the sign and the "₪" keep their places
/// in a right-to-left line.
String formatMoney(double amount) => '₪${amount.toStringAsFixed(2)}';

/// "2026-10-22 12:57".
String formatDateTime(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)} ${two(date.hour)}:${two(date.minute)}';
}

String paymentMethodLabel(PaymentMethod method) => switch (method) {
  PaymentMethod.cash => 'نقداً',
  PaymentMethod.bankTransfer => 'حوالة بنكية',
  PaymentMethod.card => 'بطاقة',
};

String paymentStatusLabel(PaymentStatus status) => switch (status) {
  PaymentStatus.paid => 'مدفوع',
  PaymentStatus.partial => 'مدفوع جزئياً',
  PaymentStatus.unpaid => 'غير مدفوع',
};

String salesPeriodLabel(SalesPeriod period) => switch (period) {
  SalesPeriod.today => 'اليوم',
  SalesPeriod.last7Days => 'آخر 7 أيام',
  SalesPeriod.last30Days => 'آخر 30 يوماً',
  SalesPeriod.thisMonth => 'هذا الشهر',
};

String dateRangeLabel(DateRangeFilter range) => switch (range) {
  DateRangeFilter.all => 'الكل',
  DateRangeFilter.today => 'اليوم',
  DateRangeFilter.last7Days => 'آخر 7 أيام',
  DateRangeFilter.thisMonth => 'هذا الشهر',
};

String refundStatusLabel(RefundStatus status) => switch (status) {
  RefundStatus.completed => 'مكتمل',
  RefundStatus.pending => 'قيد المراجعة',
};

String cashTypeFilterLabel(CashTypeFilter type) => switch (type) {
  CashTypeFilter.all => 'الكل',
  CashTypeFilter.sales => 'مبيعات',
  CashTypeFilter.expenses => 'مصروفات',
  CashTypeFilter.payments => 'دفعات',
  CashTypeFilter.adjustments => 'تسويات',
};

String cashMovementLabel(CashMovementType type) => switch (type) {
  CashMovementType.sale => 'مبيعات',
  CashMovementType.expense => 'مصروف',
  CashMovementType.payment => 'دفعة',
  CashMovementType.deposit => 'إيداع',
  CashMovementType.withdrawal => 'سحب',
};
