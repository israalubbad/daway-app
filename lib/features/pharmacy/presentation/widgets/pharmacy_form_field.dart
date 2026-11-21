import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_text_styles.dart';

/// A label over an outlined 56px field, as the "add medicine" pages lay out
/// their inputs. The caller owns [controller].
class PharmacyFormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hintText;
  final String? errorText;
  final bool readOnly;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const PharmacyFormField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.errorText,
    this.readOnly = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return _LabeledBox(
      label: label,
      errorText: errorText,
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: AppTextStyles.pharmacySearchText,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTextStyles.pharmacySearchText.copyWith(color: AppColors.grey),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
          border: _border(AppColors.cardBorder),
          enabledBorder: _border(AppColors.cardBorder),
          focusedBorder: _border(AppColors.mainTeal),
        ),
      ),
    );
  }
}

/// The same outlined box, holding a drop-down list of [items].
class PharmacyDropdownField<T> extends StatelessWidget {
  final String label;
  final String hintText;
  final String? errorText;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  const PharmacyDropdownField({
    super.key,
    required this.label,
    required this.hintText,
    this.errorText,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _LabeledBox(
      label: label,
      errorText: errorText,
      child: InputDecorator(
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
          border: _border(AppColors.cardBorder),
          enabledBorder: _border(AppColors.cardBorder),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            isExpanded: true,
            value: value,
            items: items,
            onChanged: onChanged,
            borderRadius: BorderRadius.circular(8.r),
            dropdownColor: Colors.white,
            icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.mainTeal),
            style: AppTextStyles.pharmacySearchText,
            hint: Text(
              hintText,
              style: AppTextStyles.pharmacySearchText.copyWith(color: AppColors.grey),
            ),
            itemHeight: 56.h,
          ),
        ),
      ),
    );
  }
}

class _LabeledBox extends StatelessWidget {
  final String label;
  final String? errorText;
  final Widget child;

  const _LabeledBox({required this.label, required this.errorText, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: AppTextStyles.pharmacySearchText),
        SizedBox(height: 8.h),
        SizedBox(height: 56.h, child: child),
        if (errorText != null) ...[
          SizedBox(height: 4.h),
          Text(errorText!, style: AppTextStyles.errorText),
        ],
      ],
    );
  }
}

OutlineInputBorder _border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.r),
      borderSide: BorderSide(color: color),
    );
