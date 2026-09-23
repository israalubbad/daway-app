import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_text_styles.dart';
import '../../../../core/widgets/dashed_border_container.dart';

/// The dashed call-to-action card shown on the pharmacy home screen while
/// its medicine list is still empty, prompting it to add its first
/// medicine.
class AddMedicineFileCard extends StatelessWidget {
  final VoidCallback onTap;

  const AddMedicineFileCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DashedBorderContainer(
        borderColor: AppColors.mainTeal,
        backgroundColor: AppColors.accountIconBg,
        borderRadius: 8,
        child: SizedBox(
          height: 156.h,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: const BoxDecoration(
                    color: AppColors.mainTeal,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    'assets/icons/uploud_icon.svg',
                    width: 16.w,
                    height: 16.w,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  'أضف ملف الأدوية',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.pharmacyAddMedicineFileText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
