import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_text_styles.dart';

import '../../../../core/localization/translations.dart';

/// The pharmacy home's way into the accounting area: a tinted card with an
/// icon, "المحاسبة", a line about what is inside, and an arrow.
class AccountingEntryCard extends StatelessWidget {
  final VoidCallback onTap;

  const AccountingEntryCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'المحاسبة'.tr,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: AppColors.permissionIconBg,
            border: Border.all(color: AppColors.iconBlueBorder),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            children: [
              Container(
                width: 40.r,
                height: 40.r,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.iconBlueBorder),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(Icons.account_balance_wallet_outlined, size: 22.r, color: AppColors.mainTeal),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('المحاسبة'.tr, style: AppTextStyles.pharmacyOrderNumber),
                    Text(
                      'المبيعات والإرجاعات والصندوق'.tr,
                      style: AppTextStyles.pharmacyOrderTime,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 24.r, color: AppColors.mainTeal),
            ],
          ),
        ),
      ),
    );
  }
}
