import '../../domain/entities/accounting_overview.dart';
import '../../domain/entities/cash_ledger.dart';
import '../../domain/entities/refund_record.dart';
import '../cubit/cash_state.dart';
import '../cubit/sales_state.dart';

import '../../../../core/localization/translations.dart';

/// An amount in shekels, always with two decimals: "₪100.00". Set it
/// left-to-right when it is drawn, so the sign and the "₪" keep their places
/// in a right-to-left line.
String formatMoney(double amount) =>
    amount < 0 ? '−₪${(-amount).toStringAsFixed(2)}' : '₪${amount.toStringAsFixed(2)}';

/// "2026-10-22 12:57".
String formatDateTime(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)} ${two(date.hour)}:${two(date.minute)}';
}

String paymentMethodLabel(PaymentMethod method) => switch (method) {
  PaymentMethod.cash => 'نقداً'.tr,
  PaymentMethod.bankTransfer => 'حوالة بنكية'.tr,
  PaymentMethod.card => 'بطاقة'.tr,
  PaymentMethod.credit => 'دين'.tr,
};

String paymentStatusLabel(PaymentStatus status) => switch (status) {
  PaymentStatus.paid => 'مدفوع'.tr,
  PaymentStatus.partial => 'مدفوع جزئياً'.tr,
  PaymentStatus.unpaid => 'غير مدفوع'.tr,
  PaymentStatus.refunded => 'مرجوعة'.tr,
  PaymentStatus.cancelled => 'ملغاة'.tr,
};

String salesPeriodLabel(SalesPeriod period) => switch (period) {
  SalesPeriod.today => 'اليوم'.tr,
  SalesPeriod.last7Days => 'آخر 7 أيام'.tr,
  SalesPeriod.last30Days => 'آخر 30 يوماً'.tr,
  SalesPeriod.thisMonth => 'هذا الشهر'.tr,
};

String dateRangeLabel(DateRangeFilter range) => switch (range) {
  DateRangeFilter.all => 'الكل'.tr,
  DateRangeFilter.today => 'اليوم'.tr,
  DateRangeFilter.last7Days => 'آخر 7 أيام'.tr,
  DateRangeFilter.thisMonth => 'هذا الشهر'.tr,
};

String refundStatusLabel(RefundStatus status) => switch (status) {
  RefundStatus.completed => 'مكتمل'.tr,
  RefundStatus.pending => 'قيد المراجعة'.tr,
};

String cashTypeFilterLabel(CashTypeFilter type) => switch (type) {
  CashTypeFilter.all => 'الكل'.tr,
  CashTypeFilter.sales => 'مبيعات'.tr,
  CashTypeFilter.expenses => 'مصروفات'.tr,
  CashTypeFilter.payments => 'دفعات'.tr,
  CashTypeFilter.adjustments => 'تسويات'.tr,
};

String cashMovementLabel(CashMovementType type) => switch (type) {
  CashMovementType.sale => 'مبيعات'.tr,
  CashMovementType.expense => 'مصروف'.tr,
  CashMovementType.purchase => 'مشتريات'.tr,
  CashMovementType.adjustment => 'تسوية'.tr,
  CashMovementType.payment => 'دفعة'.tr,
  CashMovementType.refund => 'إرجاع'.tr,
  CashMovementType.deposit => 'إيداع'.tr,
  CashMovementType.withdrawal => 'سحب'.tr,
};
