import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../theming/app_colors.dart';

import '../../core/localization/translations.dart';
/// Shows a camera/gallery bottom sheet and returns the picked file, or null

/// if the user cancelled or picking failed (a snackbar is shown in that
/// case). Shared by every screen that lets the user pick a single image
/// (profile/logo avatars, medicine photos, ...).
Future<File?> pickImageFromSourceSheet(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 8.h),
          ListTile(
            leading: Icon(Icons.photo_camera_outlined, color: AppColors.mainTeal),
            title: Text('التقاط صورة'.tr),
            onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
          ),
          ListTile(
            leading: Icon(Icons.photo_library_outlined, color: AppColors.mainTeal),
            title: Text('اختيار من المعرض'.tr),
            onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
          ),
          SizedBox(height: 8.h),
        ],
      ),
    ),
  );
  if (source == null || !context.mounted) return null;

  try {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 80);
    if (picked == null) return null;
    return File(picked.path);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر فتح الكاميرا، تحقق من صلاحيات التطبيق'.tr)),
      );
    }
    return null;
  }
}
