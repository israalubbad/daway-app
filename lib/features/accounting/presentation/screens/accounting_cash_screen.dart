import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theming/app_colors.dart';
import '../../../../core/widgets/app_custom_button.dart';
import '../../../../core/widgets/profile_load_error.dart';
import '../../../pharmacy/presentation/widgets/pharmacy_products_header.dart';
import '../../domain/entities/cash_ledger.dart';
import '../cubit/cash_cubit.dart';
import '../cubit/cash_state.dart';
import '../helpers/accounting_format.dart';
import '../helpers/accounting_styles.dart';
import '../widgets/accounting_card.dart';
import '../widgets/accounting_empty_state.dart';
import '../widgets/accounting_filter_sheets.dart';
import '../widgets/add_cash_movement_sheet.dart';

/// "الصندوق": the cash balance (with a warning when it is low), the cash
/// book's movements, and the button that records one by hand.
///
/// Expects a [CashCubit] above it.
class AccountingCashScreen extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onNewSale;

  const AccountingCashScreen({super.key, required this.onBack, required this.onNewSale});

  Future<void> _openFilters(BuildContext context, CashLoaded state) async {
    final cubit = context.read<CashCubit>();
    final result = await CashFiltersSheet.show(
      context,
      CashFilters(type: state.type, range: state.range),
    );
    if (result == null) return;
    cubit.filtersApplied(type: result.type, range: result.range);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<CashCubit, CashState>(
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: context.read<CashCubit>().refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 24.h),
                children: [
                  PharmacyProductsHeader(
                    title: 'الصندوق',
                    subtitle: 'كل حركة نقدية داخل الصيدلية، والرصيد يُجمع ولا يُكتب يدوياً',
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

  List<Widget> _content(BuildContext context, CashState state) {
    return switch (state) {
      CashLoading() => [
        Padding(
          padding: EdgeInsets.only(top: 80.h),
          child: const Center(child: CircularProgressIndicator()),
        ),
      ],
      CashLoadFailure(:final message) => [
        SizedBox(
          height: 300.h,
          child: ProfileLoadError(message: message, onRetry: context.read<CashCubit>().load),
        ),
      ],
      CashLoaded() => _loaded(context, state),
    };
  }

  List<Widget> _loaded(BuildContext context, CashLoaded state) {
    final visible = state.visible;
    return [
      AppCustomButton(
        text: 'تسجيل حركة صندوق',
        height: 48.h,
        onPressed: () => AddCashMovementSheet.show(
          context,
          cubit: context.read<CashCubit>(),
          balance: state.ledger.balance,
        ),
      ),
      SizedBox(height: 16.h),
      _BalanceCard(ledger: state.ledger),
      SizedBox(height: 24.h),
      Row(
        children: [
          Expanded(child: Text('الحركات', style: AccountingStyles.sectionTitle)),
          Badge(
            isLabelVisible: state.activeFilters > 0,
            label: Text('${state.activeFilters}'),
            backgroundColor: AppColors.mainTeal,
            child: IconButton(
              onPressed: () => _openFilters(context, state),
              icon: const Icon(Icons.tune_rounded, color: AppColors.mainTeal),
              tooltip: 'فلاتر',
            ),
          ),
        ],
      ),
      SizedBox(height: 8.h),
      if (visible.isEmpty)
        AccountingEmptyState(
          icon: Icons.account_balance_wallet_outlined,
          title: 'لا توجد حركات صندوق',
          hint: 'ستظهر هنا كل الحركات النقدية: مبيعات، مصروفات، دفعات، وتسويات.',
          actionLabel: 'فاتورة جديدة',
          onAction: onNewSale,
        )
      else
        for (final movement in visible) ...[
          _MovementTile(movement: movement),
          SizedBox(height: 8.h),
        ],
    ];
  }
}

class _BalanceCard extends StatelessWidget {
  final CashLedger ledger;

  const _BalanceCard({required this.ledger});

  @override
  Widget build(BuildContext context) {
    return AccountingCard(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('الرصيد الحالي', style: AccountingStyles.label),
          SizedBox(height: 4.h),
          MoneyText(ledger.balance, style: AccountingStyles.bigAmount),
          if (ledger.isLow) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.logoutRedTint,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 18.r, color: AppColors.logoutRed),
                  SizedBox(width: 8.w),
                  Text(
                    'رصيد الصندوق منخفض',
                    style: AccountingStyles.label.copyWith(color: AppColors.logoutRed),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MovementTile extends StatelessWidget {
  final CashMovement movement;

  const _MovementTile({required this.movement});

  @override
  Widget build(BuildContext context) {
    final incoming = movement.isIncoming;
    final color = incoming ? AppColors.productAvailableText : AppColors.logoutRed;
    return AccountingCard(
      child: Row(
        children: [
          Container(
            width: 36.r,
            height: 36.r,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              incoming ? Icons.south_west_rounded : Icons.north_east_rounded,
              size: 18.r,
              color: color,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(movement.description, style: AccountingStyles.cardTitle),
                Text(
                  '${cashMovementLabel(movement.type)} · ${formatDateTime(movement.date)}',
                  style: AccountingStyles.muted,
                ),
              ],
            ),
          ),
          Text(
            '${incoming ? '+' : '−'}${formatMoney(movement.amount.abs())}',
            textDirection: TextDirection.ltr,
            style: AccountingStyles.cardTitle.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
