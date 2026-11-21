import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/theming/app_colors.dart';

/// The width the mock screens inside a [OnboardingPhoneFrame] are laid out at:
/// the app's own screen content width, so the real widgets look as they do in
/// the app, only smaller.
const double onboardingMockWidth = 392;

/// A phone's top edge with a screen of the app inside, cropped at the bottom
/// like the design's onboarding pictures. The [child] is laid out at
/// [onboardingMockWidth] and scaled down to the frame's width, so it may use
/// the app's real widgets and sizes. Not interactive: it is a picture.
class OnboardingPhoneFrame extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;

  const OnboardingPhoneFrame({
    super.key,
    required this.child,
    this.width = 330,
    this.height = 340,
  });

  @override
  Widget build(BuildContext context) {
    final radius = Radius.circular(28.r);
    return ExcludeSemantics(
      child: IgnorePointer(
        child: Container(
          width: width.w,
          height: height.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: radius, topRight: radius),
            border: Border(
              top: BorderSide(color: AppColors.textDark, width: 2.w),
              left: BorderSide(color: AppColors.textDark, width: 2.w),
              right: BorderSide(color: AppColors.textDark, width: 2.w),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.only(topLeft: radius, topRight: radius),
            child: FittedBox(
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(width: onboardingMockWidth.w, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
