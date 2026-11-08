import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_text_styles.dart';

enum AccountingTab { overview, sales, refunds, cash }

/// The 4-item bottom bar of the accounting area, drawn like the pharmacy
/// dashboard's: an icon and a label per tab and a bar above the selected one.
class AccountingBottomNav extends StatelessWidget {
  final AccountingTab selected;
  final ValueChanged<AccountingTab> onSelected;

  const AccountingBottomNav({super.key, required this.selected, required this.onSelected});

  static const _items = [
    (AccountingTab.overview, 'نظرة عامة', Icons.space_dashboard_outlined),
    (AccountingTab.sales, 'المبيعات', Icons.receipt_long_outlined),
    (AccountingTab.refunds, 'الإرجاعات', Icons.assignment_return_outlined),
    (AccountingTab.cash, 'الصندوق', Icons.account_balance_wallet_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 12.h),
          child: Row(
            children: [
              for (final (tab, label, icon) in _items)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: tab == selected,
                    label: label,
                    excludeSemantics: true,
                    onTap: () => onSelected(tab),
                    child: GestureDetector(
                      onTap: () => onSelected(tab),
                      behavior: HitTestBehavior.opaque,
                      child: _NavItem(label: label, icon: icon, selected: tab == selected),
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

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;

  const _NavItem({required this.label, required this.icon, required this.selected});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.mainTeal : AppColors.authInputBorder;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40.w,
          height: 2.h,
          color: selected ? AppColors.mainTeal : Colors.transparent,
        ),
        SizedBox(height: 8.h),
        Icon(icon, size: 24.r, color: color),
        SizedBox(height: 4.h),
        Text(label, style: AppTextStyles.pharmacyNavLabel.copyWith(color: color)),
      ],
    );
  }
}
