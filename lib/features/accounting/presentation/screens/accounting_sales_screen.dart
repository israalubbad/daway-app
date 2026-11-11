import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theming/app_colors.dart';
import '../../../../core/widgets/profile_load_error.dart';
import '../../../pharmacy/presentation/widgets/pharmacy_products_header.dart';
import '../cubit/sales_cubit.dart';
import '../cubit/sales_state.dart';
import '../helpers/accounting_styles.dart';
import '../helpers/invoice_actions.dart';
import '../widgets/accounting_card.dart';
import '../widgets/accounting_empty_state.dart';
import '../widgets/accounting_filter_sheets.dart';
import '../widgets/accounting_search_bar.dart';
import '../widgets/invoice_card.dart';

import '../../../../core/localization/translations.dart';

/// "المبيعات": every sales invoice with its search, filters, totals and the
/// button that starts a new invoice.
///
/// Expects a [SalesCubit] above it.
class AccountingSalesScreen extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onNewSale;

  /// Called after a payment or a return was saved on an invoice, so the tabs
  /// that show the same money can fetch again.
  final VoidCallback onDataChanged;

  const AccountingSalesScreen({
    super.key,
    required this.onBack,
    required this.onNewSale,
    required this.onDataChanged,
  });

  Future<void> _openFilters(BuildContext context, SalesLoaded state) async {
    final cubit = context.read<SalesCubit>();
    final result = await SalesFiltersSheet.show(
      context,
      SalesFilters(range: state.range, method: state.method, status: state.status),
    );
    if (result == null) return;
    cubit.filtersApplied(range: result.range, method: result.method, status: result.status);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onNewSale,
        backgroundColor: AppColors.mainTeal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('فاتورة جديدة'.tr, style: AccountingStyles.body.copyWith(color: Colors.white)),
      ),
      body: SafeArea(
        child: BlocBuilder<SalesCubit, SalesState>(
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: context.read<SalesCubit>().refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 96.h),
                children: [
                  PharmacyProductsHeader(
                    title: 'المبيعات'.tr,
                    subtitle: 'كل فواتير البيع وقيم التحصيل'.tr,
                    onBack: onBack,
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

  List<Widget> _content(BuildContext context, SalesState state) {
    return switch (state) {
      SalesLoading() => [
        Padding(
          padding: EdgeInsets.only(top: 80.h),
          child: const Center(child: CircularProgressIndicator()),
        ),
      ],
      SalesLoadFailure(:final message) => [
        SizedBox(
          height: 300.h,
          child: ProfileLoadError(message: message, onRetry: context.read<SalesCubit>().load),
        ),
      ],
      SalesLoaded() => _loaded(context, state),
    };
  }

  List<Widget> _loaded(BuildContext context, SalesLoaded state) {
    final visible = state.visible;
    return [
      AccountingSearchBar(
        hint: 'ابحث برقم الفاتورة أو اسم العميل…'.tr,
        onChanged: context.read<SalesCubit>().queryChanged,
        onFiltersTap: () => _openFilters(context, state),
        activeFilters: state.activeFilters,
      ),
      SizedBox(height: 16.h),
      Row(
        children: [
          Expanded(child: Text('المبيعات'.tr, style: AccountingStyles.sectionTitle)),
          Text('{0} نتيجة'.trArgs([visible.length]), style: AccountingStyles.muted),
        ],
      ),
      SizedBox(height: 12.h),
      if (visible.isEmpty)
        AccountingEmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'لا توجد فواتير'.tr,
          hint: 'غيّر البحث أو الفلاتر، أو أنشئ فاتورة بيع جديدة.'.tr,
        )
      else ...[
        _TotalsCard(state: state),
        SizedBox(height: 12.h),
        for (final invoice in visible) ...[
          InvoiceCard(
            invoice: invoice,
            onAction: (action) => runInvoiceAction(
              context,
              invoice: invoice,
              action: action,
              cubit: context.read<SalesCubit>(),
              onChanged: onDataChanged,
            ),
          ),
          SizedBox(height: 8.h),
        ],
      ],
    ];
  }
}

/// The totals of the invoices listed: total, paid and still owed.
class _TotalsCard extends StatelessWidget {
  final SalesLoaded state;

  const _TotalsCard({required this.state});

  @override
  Widget build(BuildContext context) {
    Widget figure(String label, double amount, {Color? color}) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AccountingStyles.muted),
          MoneyText(amount, style: AccountingStyles.amount.copyWith(fontSize: 15.sp, color: color)),
        ],
      ),
    );

    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.permissionIconBg,
        border: Border.all(color: AppColors.iconBlueBorder),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          figure('الإجمالي'.tr, state.totalAmount),
          figure('المدفوع'.tr, state.paidAmount),
          figure(
            'المتبقي'.tr,
            state.remainingAmount,
            color: state.remainingAmount > 0 ? AppColors.logoutRed : null,
          ),
        ],
      ),
    );
  }
}
