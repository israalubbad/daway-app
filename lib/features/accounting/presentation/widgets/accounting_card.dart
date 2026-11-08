import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theming/app_colors.dart';
import '../../domain/entities/accounting_overview.dart';
import '../helpers/accounting_format.dart';
import '../helpers/accounting_styles.dart';

/// A white card with the app's 1px #DCE6E9 border and 12 corners.
class AccountingCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const AccountingCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12.r);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: AppColors.cardBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(padding: padding ?? EdgeInsets.all(12.r), child: child),
      ),
    );
  }
}

/// An amount, set left-to-right so "₪" and the figure keep their places.
class MoneyText extends StatelessWidget {
  final double amount;
  final TextStyle? style;

  const MoneyText(this.amount, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    return Text(
      formatMoney(amount),
      textDirection: TextDirection.ltr,
      style: style ?? AccountingStyles.body,
    );
  }
}

/// The small pill of an invoice's payment status: green, yellow or red.
class PaymentStatusBadge extends StatelessWidget {
  final PaymentStatus status;

  const PaymentStatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final (text, tint) = switch (status) {
      PaymentStatus.paid => (AppColors.productAvailableText, AppColors.productAvailableTint),
      PaymentStatus.partial => (const Color(0xFFB7791F), AppColors.productLowStockTint),
      PaymentStatus.unpaid => (AppColors.logoutRed, AppColors.logoutRedTint),
    };
    return _Pill(label: paymentStatusLabel(status), color: text, background: tint);
  }
}

/// A small tinted label, like the payment method on an invoice.
class AccountingChip extends StatelessWidget {
  final String label;

  const AccountingChip(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return _Pill(
      label: label,
      color: AppColors.mainTeal,
      background: AppColors.permissionIconBg,
      border: AppColors.iconBlueBorder,
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;
  final Color? border;

  const _Pill({required this.label, required this.color, required this.background, this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: background,
        border: border == null ? null : Border.all(color: border!),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(label, style: AccountingStyles.label.copyWith(color: color)),
    );
  }
}
