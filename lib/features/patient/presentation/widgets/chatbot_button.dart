import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theming/app_colors.dart';

import '../../../../core/localization/translations.dart';
/// The 64×64 round chatbot launcher that floats above the patient bottom nav.

/// Purely presentational: the caller decides what tapping it does.
class ChatbotButton extends StatelessWidget {
  final VoidCallback onTap;

  const ChatbotButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'المساعد الذكي'.tr,
      child: Material(
        color: AppColors.chatbotButtonBackground,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 64.r,
            height: 64.r,
            child: Padding(
              padding: EdgeInsets.all(12.r),
              child: Image.asset('assets/images/chatbot_orb.png', fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}
