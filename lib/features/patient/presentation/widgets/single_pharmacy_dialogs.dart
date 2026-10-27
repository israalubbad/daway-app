import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_text_styles.dart';

/// An order can only be placed with one pharmacy: the pharmacies are far from
/// each other, so one delivery cannot serve two of them. These dialogs are
/// where the patient is told, and asked what to do about it.

/// Asked when a medicine from another pharmacy is about to be added to a cart
/// that holds [currentPharmacy]'s items. True = empty the cart and add it.
Future<bool> confirmReplaceCart(
  BuildContext context, {
  required String currentPharmacy,
  required String newPharmacy,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => _DialogFrame(
      title: 'صيدلية مختلفة',
      message:
          'سلتك فيها منتجات من $currentPharmacy، والصيدليات بعيدة عن بعضها، '
          'فلا يمكن طلب منتجات من أكثر من صيدلية في طلب واحد.\n\n'
          'هل تريد تفريغ السلة وإضافة المنتج من $newPharmacy؟',
      confirmLabel: 'تفريغ السلة وإضافة',
      child: null,
    ),
  );
  return confirmed ?? false;
}

/// Asked at checkout when the cart holds items from several pharmacies.
/// [pharmacies] maps pharmacy id → name. Returns the id of the pharmacy the
/// patient keeps, or null if they backed out.
Future<int?> choosePharmacyForOrder(
  BuildContext context, {
  required Map<int, String> pharmacies,
}) {
  return showDialog<int>(
    context: context,
    builder: (_) => _PharmacyChoiceDialog(pharmacies: pharmacies),
  );
}

class _PharmacyChoiceDialog extends StatefulWidget {
  final Map<int, String> pharmacies;

  const _PharmacyChoiceDialog({required this.pharmacies});

  @override
  State<_PharmacyChoiceDialog> createState() => _PharmacyChoiceDialogState();
}

class _PharmacyChoiceDialogState extends State<_PharmacyChoiceDialog> {
  late int _selected = widget.pharmacies.keys.first;

  @override
  Widget build(BuildContext context) {
    return _DialogFrame(
      title: 'اختر صيدلية واحدة',
      message:
          'سلتك فيها منتجات من أكثر من صيدلية، والصيدليات بعيدة عن بعضها. '
          'اختر الصيدلية التي تريد الطلب منها، وسيتم حذف منتجات الصيدليات الأخرى من السلة.',
      confirmLabel: 'متابعة',
      onConfirm: () => Navigator.of(context).pop(_selected),
      child: RadioGroup<int>(
        groupValue: _selected,
        onChanged: (value) => setState(() => _selected = value ?? _selected),
        child: Column(
          children: [
            for (final entry in widget.pharmacies.entries)
              RadioListTile<int>(
                value: entry.key,
                activeColor: AppColors.mainTeal,
                contentPadding: EdgeInsets.zero,
                title: Text(entry.value, style: AppTextStyles.cartItemName),
              ),
          ],
        ),
      ),
    );
  }
}

class _DialogFrame extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final VoidCallback? onConfirm;
  final Widget? child;

  const _DialogFrame({
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.onConfirm,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 24.h),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.confirmSheetTitle,
              ),
              SizedBox(height: 12.h),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.confirmSheetMessage,
              ),
              if (child != null) ...[SizedBox(height: 8.h), child!],
              SizedBox(height: 24.h),
              SizedBox(
                height: 52.h,
                child: ElevatedButton(
                  onPressed: onConfirm ?? () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainTeal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: Text(
                    confirmLabel,
                    style: AppTextStyles.sheetButtonLabel,
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              SizedBox(
                height: 52.h,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.sheetTitleText,
                    side: const BorderSide(color: AppColors.sheetOutlineBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: Text('إلغاء', style: AppTextStyles.sheetButtonLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
