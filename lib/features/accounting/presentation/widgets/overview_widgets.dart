import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theming/app_colors.dart';
import '../../../../core/widgets/app_filter_chip.dart';
import '../../domain/entities/accounting_overview.dart';
import '../helpers/accounting_format.dart';
import '../helpers/accounting_styles.dart';
import 'accounting_card.dart';

import '../../../../core/localization/translations.dart';

/// One figure of the overview's grid: a tinted icon, its title and the amount.
class KpiCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;

  const KpiCard({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AccountingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32.r,
            height: 32.r,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, size: 18.r, color: color),
          ),
          SizedBox(height: 10.h),
          Text(title, style: AccountingStyles.label),
          SizedBox(height: 2.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: MoneyText(amount, style: AccountingStyles.amount),
          ),
        ],
      ),
    );
  }
}

/// The six figures as a two-column grid.
class KpiGrid extends StatelessWidget {
  final AccountingOverview overview;

  const KpiGrid({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    final cards = [
      KpiCard(title: 'مبيعات اليوم'.tr, amount: overview.todaySales, icon: Icons.trending_up_rounded, color: AppColors.mainTeal),
      KpiCard(title: 'مشتريات اليوم'.tr, amount: overview.todayPurchases, icon: Icons.shopping_bag_outlined, color: AppColors.mainTeal),
      KpiCard(title: 'مصروفات اليوم'.tr, amount: overview.todayExpenses, icon: Icons.payments_outlined, color: AppColors.warning),
      KpiCard(title: 'ربح اليوم'.tr, amount: overview.todayProfit, icon: Icons.savings_outlined, color: AppColors.statAvailable),
      KpiCard(title: 'رصيد الصندوق'.tr, amount: overview.cashBalance, icon: Icons.account_balance_wallet_outlined, color: AppColors.logoutRed),
      KpiCard(title: 'الديون المستحقة'.tr, amount: overview.outstandingDebts, icon: Icons.request_quote_outlined, color: AppColors.logoutRed),
    ];
    return Column(
      children: [
        for (var i = 0; i < cards.length; i += 2) ...[
          if (i > 0) SizedBox(height: 8.h),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cards[i]),
                SizedBox(width: 8.w),
                Expanded(child: cards[i + 1]),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// The period buttons of the sales chart, scrolling sideways when they do not fit.
class SalesPeriodChips extends StatelessWidget {
  final SalesPeriod selected;
  final ValueChanged<SalesPeriod> onSelected;

  const SalesPeriodChips({super.key, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    // Wraps onto a second line instead of scrolling sideways, so all four
    // buttons are always on screen.
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        for (final period in SalesPeriod.values)
          AppFilterChip(
            label: salesPeriodLabel(period),
            selected: period == selected,
            onTap: () => onSelected(period),
          ),
      ],
    );
  }
}

/// One "أمور تحتاج انتباهك" row: a coloured edge, an icon, a title and a line.
class AlertTile extends StatelessWidget {
  final AccountingAlert alert;
  final VoidCallback? onTap;

  const AlertTile({super.key, required this.alert, this.onTap});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (alert.kind) {
      AccountingAlertKind.overdueDebt => (AppColors.logoutRed, Icons.schedule_rounded),
      AccountingAlertKind.lowCash => (AppColors.logoutRed, Icons.account_balance_wallet_outlined),
      AccountingAlertKind.lowStock => (AppColors.statLowStock, Icons.inventory_2_outlined),
    };
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(12.r),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4.w, color: color),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(12.r),
                  child: Row(
                    children: [
                      Icon(icon, size: 20.r, color: color),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(alert.title, style: AccountingStyles.cardTitle),
                            Text(alert.message, style: AccountingStyles.muted),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One row of "آخر الحركات": reference and status, what it was, then the date,
/// the payment method and the amount.
class TransactionCard extends StatelessWidget {
  final AccountingTransaction transaction;

  const TransactionCard({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return AccountingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    transaction.reference,
                    textDirection: TextDirection.ltr,
                    style: AccountingStyles.cardTitle,
                  ),
                ),
              ),
              PaymentStatusBadge(transaction.status),
            ],
          ),
          SizedBox(height: 4.h),
          Text(transaction.description, style: AccountingStyles.body),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${formatDateTime(transaction.date)} · ${paymentMethodLabel(transaction.method)}',
                  style: AccountingStyles.muted,
                ),
              ),
              MoneyText(transaction.amount, style: AccountingStyles.cardTitle),
            ],
          ),
        ],
      ),
    );
  }
}
