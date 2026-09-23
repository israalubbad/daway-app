import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../core/theming/app_text_styles.dart';
import '../../../../core/widgets/bordered_icon_button.dart';
import '../cubit/pharmacy_profile_cubit.dart';
import '../cubit/pharmacy_profile_state.dart';

/// Greeting + notification bell + the pharmacy's address — the top block of
/// [PharmacyHomeScreen], styled after the patient home screen's
/// [HomeHeader] (same greeting/location text styles, same bordered bell
/// icon) per the redesign spec.
class PharmacyHomeHeader extends StatelessWidget {
  final VoidCallback onNotificationsTap;

  const PharmacyHomeHeader({super.key, required this.onNotificationsTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            // Greeting first so it lands on the physical right under this
            // app's RTL 'ar' locale — the bell icon sits on the left.
            Expanded(
              child: BlocBuilder<PharmacyProfileCubit, PharmacyProfileState>(
                builder: (context, state) {
                  final name = state is PharmacyProfileLoaded
                      ? state.profile.name
                      : '';
                  return Text.rich(
                    TextSpan(
                      style: AppTextStyles.homeGreetingRegular,
                      children: [
                        const TextSpan(text: 'أهلا بك '),
                        TextSpan(
                          text: name,
                          style: AppTextStyles.homeGreetingName,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );
                },
              ),
            ),
            SizedBox(width: 16.w),
            BorderedIconButton(
              assetName: 'assets/icons/notification_icon.svg',
              onTap: onNotificationsTap,
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            SvgPicture.asset(
              'assets/icons/location_icon.svg',
              width: 18.w,
              height: 18.w,
            ),
            SizedBox(width: 4.w),
            BlocBuilder<PharmacyProfileCubit, PharmacyProfileState>(
              builder: (context, state) {
                final address = state is PharmacyProfileLoaded
                    ? state.profile.address
                    : null;
                return Text(
                  (address == null || address.isEmpty) ? 'حدد الموقع' : address,
                  style: AppTextStyles.pharmacyHomeLocationText,
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
