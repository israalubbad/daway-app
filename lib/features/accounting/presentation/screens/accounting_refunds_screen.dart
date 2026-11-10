import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theming/app_colors.dart';
import '../../../../core/widgets/app_filter_chip.dart';
import '../../../../core/widgets/profile_load_error.dart';
import '../../../pharmacy/presentation/widgets/pharmacy_products_header.dart';
import '../../domain/entities/refund_record.dart';
import '../cubit/refunds_cubit.dart';
import '../cubit/refunds_state.dart';
import '../helpers/accounting_format.dart';
import '../helpers/accounting_styles.dart';
import '../widgets/accounting_card.dart';
import '../widgets/accounting_empty_state.dart';
import '../widgets/accounting_search_bar.dart';

/// "الإرجاعات": the log of sales returns, searchable and filterable by status.
/// A return is started from an invoice's menu in المبيعات.
///
/// Expects a [RefundsCubit] above it.
class AccountingRefundsScreen extends StatelessWidget {
  final VoidCallback onBack;

  const AccountingRefundsScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<RefundsCubit, RefundsState>(
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: context.read<RefundsCubit>().refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 24.h),
                children: [
                  PharmacyProductsHeader(
                    title: 'الإرجاعات',
                    subtitle: 'سجل مرتجعات البيع لهذه الصيدلية',
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

  List<Widget> _content(BuildContext context, RefundsState state) {
    return switch (state) {
      RefundsLoading() => [
        Padding(
          padding: EdgeInsets.only(top: 80.h),
          child: const Center(child: CircularProgressIndicator()),
        ),
      ],
      RefundsLoadFailure(:final message) => [
        SizedBox(
          height: 300.h,
          child: ProfileLoadError(message: message, onRetry: context.read<RefundsCubit>().load),
        ),
      ],
      RefundsLoaded() => _loaded(context, state),
    };
  }

  List<Widget> _loaded(BuildContext context, RefundsLoaded state) {
    final cubit = context.read<RefundsCubit>();
    final visible = state.visible;
    return [
      AccountingSearchBar(
        hint: 'ابحث برقم الإرجاع أو الفاتورة…',
        onChanged: cubit.queryChanged,
      ),
      SizedBox(height: 12.h),
      Wrap(
        spacing: 8.w,
        children: [
          AppFilterChip(label: 'الكل', selected: state.status == null, onTap: () => cubit.statusChanged(null)),
          for (final status in RefundStatus.values)
            AppFilterChip(
              label: refundStatusLabel(status),
              selected: state.status == status,
              onTap: () => cubit.statusChanged(status),
            ),
        ],
      ),
      SizedBox(height: 16.h),
      if (visible.isEmpty)
        AccountingEmptyState(
          icon: Icons.assignment_return_outlined,
          title: 'لا توجد إرجاعات',
          hint: state.all.isEmpty
              ? 'ستظهر هنا كل عمليات الإرجاع التي تُنفّذ على فواتير البيع.'
              : 'لا توجد نتائج مطابقة لبحثك.',
        )
      else
        for (final refund in visible) ...[
          _RefundCard(refund: refund),
          SizedBox(height: 8.h),
        ],
    ];
  }
}

class _RefundCard extends StatelessWidget {
  final RefundRecord refund;

  const _RefundCard({required this.refund});

  @override
  Widget build(BuildContext context) {
    final completed = refund.status == RefundStatus.completed;
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
                    refund.number,
                    textDirection: TextDirection.ltr,
                    style: AccountingStyles.cardTitle,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: completed ? AppColors.productAvailableTint : AppColors.productLowStockTint,
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  refundStatusLabel(refund.status),
                  style: AccountingStyles.label.copyWith(
                    color: completed ? AppColors.productAvailableText : const Color(0xFFB7791F),
                  ),
                ),
              ),
            ],
          ),
          Text(
            'على الفاتورة ${refund.invoiceNumber} · ${refund.customerName ?? 'زائر نقدي'}',
            style: AccountingStyles.muted,
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(child: Text(formatDateTime(refund.date), style: AccountingStyles.muted)),
              MoneyText(refund.amount, style: AccountingStyles.cardTitle),
            ],
          ),
        ],
      ),
    );
  }
}
