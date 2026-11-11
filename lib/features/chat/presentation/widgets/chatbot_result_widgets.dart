import '../../../../core/widgets/network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/helpers/price_formatter.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_text_styles.dart';
import '../../domain/entities/chatbot_reply.dart';

import '../../../../core/localization/translations.dart';

/// What the assistant found, under its message: the medicine, the pharmacies
/// that have it, and the alternatives. Tapping any of them opens the medicine.
class ChatbotResults extends StatelessWidget {
  final ChatbotReply reply;

  const ChatbotResults({super.key, required this.reply});

  void _openMedicine(BuildContext context, int medicineId) {
    Navigator.of(context).pushNamed(Routes.medicineDetailScreen, arguments: medicineId);
  }

  @override
  Widget build(BuildContext context) {
    final medicine = reply.medicine;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (medicine != null) ...[
          _MedicineCard(medicine: medicine, onTap: () => _openMedicine(context, medicine.id)),
          for (final pharmacy in reply.pharmacies) ...[
            SizedBox(height: 8.h),
            _PharmacyTile(pharmacy: pharmacy, onTap: () => _openMedicine(context, medicine.id)),
          ],
        ],
        if (reply.alternatives.isNotEmpty) ...[
          SizedBox(height: 12.h),
          Text('البدائل'.tr, textAlign: TextAlign.start, style: AppTextStyles.profileFieldLabel),
          for (final alternative in reply.alternatives) ...[
            SizedBox(height: 8.h),
            _MedicineCard(
              medicine: alternative,
              onTap: () => _openMedicine(context, alternative.id),
            ),
          ],
        ],
      ],
    );
  }
}

class _MedicineCard extends StatelessWidget {
  final ChatbotMedicine medicine;
  final VoidCallback onTap;

  const _MedicineCard({required this.medicine, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final arabic = medicine.nameAr;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            _Thumbnail(url: medicine.imageUrl),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    arabic ?? medicine.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cartItemName,
                  ),
                  if (arabic != null && medicine.name.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      medicine.name,
                      textDirection: TextDirection.ltr,
                      style: AppTextStyles.cartItemPharmacyName,
                    ),
                  ],
                  if (medicine.isAvailable != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      medicine.isAvailable! ? 'متوفر'.tr : 'غير متوفر'.tr,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: medicine.isAvailable!
                            ? AppColors.productAvailableText
                            : AppColors.grey,
                      ),
                    ),
                  ],
                  if (medicine.activeIngredient != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      medicine.activeIngredient!,
                      textDirection: TextDirection.ltr,
                      style: AppTextStyles.cartItemPharmacyName,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String? url;

  const _Thumbnail({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        width: 56.r,
        height: 56.r,
        color: AppColors.permissionIconBg,
        child: url == null
            ? Icon(Icons.medication_outlined, color: AppColors.mainTeal, size: 28.sp)
            : networkImage(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.medication_outlined, color: AppColors.mainTeal, size: 28.sp),
              ),
      ),
    );
  }
}

class _PharmacyTile extends StatelessWidget {
  final ChatbotPharmacy pharmacy;
  final VoidCallback onTap;

  const _PharmacyTile({required this.pharmacy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = pharmacy.availabilityLabel;
    final isOpen = pharmacy.isOpenNow;
    final details = [
      if (pharmacy.address != null) pharmacy.address!,
      if (pharmacy.distanceKm != null) '{0} كم'.trArgs([pharmacy.distanceKm!.toStringAsFixed(1)]),
    ].join(' · ');
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: AppColors.permissionIconBg,
          border: Border.all(color: AppColors.iconBlueBorder),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pharmacy.name, style: AppTextStyles.cartItemName),
                  if (details.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(details, style: AppTextStyles.cartItemPharmacyName),
                  ],
                  if (label != null || isOpen != null) ...[
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        if (label != null) _Chip(text: label, color: AppColors.productAvailableText),
                        if (label != null && isOpen != null) SizedBox(width: 8.w),
                        if (isOpen != null)
                          _Chip(
                            text: isOpen ? 'مفتوحة الآن'.tr : 'مغلقة الآن'.tr,
                            color: isOpen ? AppColors.productAvailableText : AppColors.grey,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (pharmacy.price != null)
              Text(
                '${formatPrice(pharmacy.price!)} \$',
                style: AppTextStyles.profileFieldLabel.copyWith(fontWeight: FontWeight.w700),
              ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color color;

  const _Chip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: color));
  }
}
