import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theming/app_colors.dart';

/// The logo of a bank or wallet when the API sends one, a neutral bank icon
/// when it does not.
class BankLogo extends StatelessWidget {
  final String? logoUrl;
  final double size;

  const BankLogo({super.key, required this.logoUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(Icons.account_balance_outlined, color: AppColors.mainTeal, size: size * 0.45);
    final url = logoUrl;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.permissionIconBg,
        borderRadius: BorderRadius.circular(8.r),
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? fallback
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => fallback,
            ),
    );
  }
}
