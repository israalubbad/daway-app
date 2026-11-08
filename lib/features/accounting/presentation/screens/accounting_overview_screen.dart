import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theming/app_colors.dart';
import '../../../../core/widgets/app_custom_button.dart';
import '../../../../core/widgets/profile_load_error.dart';
import '../../../pharmacy/presentation/widgets/pharmacy_products_header.dart';
import '../../domain/entities/accounting_overview.dart';
import '../cubit/accounting_load_state.dart';
import '../cubit/accounting_overview_cubit.dart';
import '../helpers/accounting_styles.dart';
import '../widgets/accounting_card.dart';
import '../widgets/expense_donut.dart';
import '../widgets/overview_widgets.dart';
import '../widgets/sales_line_chart.dart';

/// "المحاسبة — نظرة عامة": the day's figures, the sales chart, the month's
/// expenses, what needs attention and the latest transactions.
///
/// Expects an [AccountingOverviewCubit] above it.
class AccountingOverviewScreen extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onOpenSales;
  final VoidCallback onNewSale;
  final VoidCallback onOpenCash;

  const AccountingOverviewScreen({
    super.key,
    required this.onBack,
    required this.onOpenSales,
    required this.onNewSale,
    required this.onOpenCash,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<AccountingOverviewCubit, AccountingLoad<AccountingOverview>>(
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: context.read<AccountingOverviewCubit>().refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 24.h),
                children: [
                  PharmacyProductsHeader(
                    title: 'المحاسبة',
                    subtitle: 'ملخص مالي لصيدليتك',
                    onBack: onBack,
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: AppCustomButton(
                          text: 'المبيعات',
                          height: 44.h,
                          backgroundColor: Colors.white,
                          textColor: AppColors.mainTeal,
                          borderColor: AppColors.cardBorder,
                          onPressed: onOpenSales,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: AppCustomButton(
                          text: 'فاتورة بيع جديدة',
                          height: 44.h,
                          onPressed: onNewSale,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  ..._content(context, state),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, AccountingLoad<AccountingOverview> state) {
    return switch (state) {
      AccountingLoading() => [
        Padding(
          padding: EdgeInsets.only(top: 80.h),
          child: const Center(child: CircularProgressIndicator()),
        ),
      ],
      AccountingLoadFailure(:final message) => [
        SizedBox(
          height: 300.h,
          child: ProfileLoadError(
            message: message,
            onRetry: context.read<AccountingOverviewCubit>().load,
          ),
        ),
      ],
      AccountingLoaded(:final data) => _loaded(context, data),
    };
  }

  List<Widget> _loaded(BuildContext context, AccountingOverview overview) {
    return [
      KpiGrid(overview: overview),
      SizedBox(height: 16.h),
      AccountingCard(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('حركة المبيعات', style: AccountingStyles.sectionTitle),
            Text('إجمالي المبيعات خلال الفترة المختارة', style: AccountingStyles.muted),
            SizedBox(height: 12.h),
            SalesPeriodChips(
              selected: overview.period,
              onSelected: context.read<AccountingOverviewCubit>().periodChanged,
            ),
            SizedBox(height: 16.h),
            SalesLineChart(points: overview.salesTrend),
          ],
        ),
      ),
      SizedBox(height: 16.h),
      AccountingCard(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('توزيع المصروفات', style: AccountingStyles.sectionTitle),
            Text('المصروفات حسب الفئة خلال الشهر الحالي', style: AccountingStyles.muted),
            SizedBox(height: 12.h),
            ExpenseDonut(slices: overview.expenses),
          ],
        ),
      ),
      if (overview.alerts.isNotEmpty) ...[
        SizedBox(height: 24.h),
        Text('تنبيهات', style: AccountingStyles.sectionTitle),
        Text('أمور تحتاج انتباهك', style: AccountingStyles.muted),
        SizedBox(height: 12.h),
        for (final alert in overview.alerts) ...[
          AlertTile(
            alert: alert,
            onTap: switch (alert.kind) {
              AccountingAlertKind.overdueDebt => onOpenSales,
              AccountingAlertKind.lowCash => onOpenCash,
              AccountingAlertKind.lowStock => null,
            },
          ),
          SizedBox(height: 8.h),
        ],
      ],
      SizedBox(height: 16.h),
      Text('آخر الحركات', style: AccountingStyles.sectionTitle),
      Text('أحدث العمليات المالية المسجلة', style: AccountingStyles.muted),
      SizedBox(height: 12.h),
      if (overview.recentTransactions.isEmpty)
        Text('لا توجد حركات بعد', style: AccountingStyles.muted)
      else
        for (final transaction in overview.recentTransactions) ...[
          TransactionCard(transaction: transaction),
          SizedBox(height: 8.h),
        ],
    ];
  }
}
