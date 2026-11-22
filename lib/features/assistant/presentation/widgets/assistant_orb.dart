import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/localization/translations.dart';
import '../../../../core/routing/routes.dart';

/// The round floating button at the bottom-left of the inquiries list that
/// opens the assistant: the glass orb on a dark disc, as in the design.
class AssistantOrb extends StatelessWidget {
  const AssistantOrb({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'المساعد الذكي'.tr,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pushNamed(Routes.assistantScreen),
        child: Container(
          width: 64.w,
          height: 64.w,
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF0C2A40),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Image.asset('assets/images/assistant_orb.png', fit: BoxFit.contain),
        ),
      ),
    );
  }
}
