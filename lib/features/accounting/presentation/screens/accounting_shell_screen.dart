import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/dependency_injection.dart';
import '../cubit/accounting_overview_cubit.dart';
import '../cubit/cash_cubit.dart';
import '../cubit/refunds_cubit.dart';
import '../cubit/sales_cubit.dart';
import '../widgets/accounting_bottom_nav.dart';
import 'accounting_cash_screen.dart';
import 'accounting_overview_screen.dart';
import 'accounting_refunds_screen.dart';
import 'accounting_sales_screen.dart';
import 'new_sale_screen.dart';

/// The accounting area: نظرة عامة, المبيعات, الإرجاعات and الصندوق behind a
/// bottom bar. Each tab's cubit is made once here and kept while the area is
/// open, so a tab keeps its filters and scroll when it is left and returned to.
///
/// Opened from the pharmacy home; its back chips pop back to it.
class AccountingShellScreen extends StatefulWidget {
  const AccountingShellScreen({super.key});

  @override
  State<AccountingShellScreen> createState() => _AccountingShellScreenState();
}

class _AccountingShellScreenState extends State<AccountingShellScreen> {
  AccountingTab _selected = AccountingTab.overview;

  final AccountingOverviewCubit _overviewCubit = getIt<AccountingOverviewCubit>();
  final SalesCubit _salesCubit = getIt<SalesCubit>();
  final RefundsCubit _refundsCubit = getIt<RefundsCubit>();
  final CashCubit _cashCubit = getIt<CashCubit>();

  @override
  void dispose() {
    _overviewCubit.close();
    _salesCubit.close();
    _refundsCubit.close();
    _cashCubit.close();
    super.dispose();
  }

  void _select(AccountingTab tab) => setState(() => _selected = tab);

  /// Opens the new-invoice screen; after a saved sale every figure it touches
  /// is fetched again.
  Future<void> _newSale() async {
    final saved = await NewSaleScreen.open(context);
    if (saved != true) return;
    _overviewCubit.refresh();
    _salesCubit.refresh();
    _cashCubit.refresh();
  }

  void _back() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selected.index,
        children: [
          BlocProvider.value(
            value: _overviewCubit,
            child: AccountingOverviewScreen(
              onBack: _back,
              onOpenSales: () => _select(AccountingTab.sales),
              onNewSale: _newSale,
              onOpenCash: () => _select(AccountingTab.cash),
            ),
          ),
          BlocProvider.value(
            value: _salesCubit,
            child: AccountingSalesScreen(onBack: _back, onNewSale: _newSale),
          ),
          BlocProvider.value(
            value: _refundsCubit,
            child: AccountingRefundsScreen(onBack: _back),
          ),
          BlocProvider.value(
            value: _cashCubit,
            child: AccountingCashScreen(onBack: _back, onNewSale: _newSale),
          ),
        ],
      ),
      bottomNavigationBar: AccountingBottomNav(selected: _selected, onSelected: _select),
    );
  }
}
