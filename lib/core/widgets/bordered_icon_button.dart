import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import '../theming/app_colors.dart';

/// The bordered square icon button used next to a screen's greeting header
/// (patient home's notification/cart icons, pharmacy home's notification
/// icon) — a white square with a light border around an SVG glyph.
class BorderedIconButton extends StatelessWidget {
  final String assetName;
  final VoidCallback onTap;

  const BorderedIconButton({
    super.key,
    required this.assetName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42.w,
        height: 42.w,
        alignment: Alignment.center,
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppColors.iconBlueBorder),
        ),
        child: SvgPicture.asset(assetName, width: 22.w, height: 22.w),
      ),
    );
  }
}
