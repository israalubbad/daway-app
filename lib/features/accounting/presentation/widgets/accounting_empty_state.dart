import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theming/app_colors.dart';
import '../../../../core/widgets/app_custom_button.dart';
import '../helpers/accounting_styles.dart';

/// An icon, a title, a hint line and an optional button: the empty state of
/// the accounting lists.
class AccountingEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? hint;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AccountingEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.hint,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 40.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64.r,
            height: 64.r,
            decoration: const BoxDecoration(
              color: AppColors.permissionIconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30.r, color: AppColors.mainTeal),
          ),
          SizedBox(height: 16.h),
          Text(title, textAlign: TextAlign.center, style: AccountingStyles.sectionTitle),
          if (hint != null) ...[
            SizedBox(height: 6.h),
            Text(hint!, textAlign: TextAlign.center, style: AccountingStyles.muted),
          ],
          if (actionLabel != null) ...[
            SizedBox(height: 20.h),
            SizedBox(
              width: 200.w,
              child: AppCustomButton(text: actionLabel!, onPressed: onAction ?? () {}),
            ),
          ],
        ],
      ),
    );
  }
}
