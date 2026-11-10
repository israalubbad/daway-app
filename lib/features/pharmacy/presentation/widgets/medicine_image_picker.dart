import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/helpers/image_source_picker.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_text_styles.dart';

/// The dashed "أضف صورة" box for the medicine's (optional) photo, on the "add
/// medicine" screen: a camera in a round chip over the label, replaced by the
/// photo once one is picked. Picking goes through [pickImageFromSourceSheet].
class MedicineImagePicker extends StatelessWidget {
  final String? imageLocalPath;
  final String? imageUrl;
  final bool isUploading;
  final String? errorMessage;
  final ValueChanged<File> onImagePicked;

  const MedicineImagePicker({
    super.key,
    required this.imageLocalPath,
    this.imageUrl,
    required this.isUploading,
    required this.errorMessage,
    required this.onImagePicked,
  });

  Future<void> _pickImage(BuildContext context) async {
    final file = await pickImageFromSourceSheet(context);
    if (file != null) onImagePicked(file);
  }

  Widget _buildContent() {
    if (isUploading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (imageLocalPath != null) {
      return Image.file(File(imageLocalPath!), fit: BoxFit.cover);
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(imageUrl!, fit: BoxFit.cover);
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 48.r,
          height: 48.r,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accountIconBg,
          ),
          child: Icon(Icons.photo_camera_outlined, size: 24.sp, color: AppColors.mainTeal),
        ),
        SizedBox(height: 8.h),
        Text('أضف صورة', style: AppTextStyles.footerText.copyWith(color: AppColors.mainTeal)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Semantics(
          button: true,
          label: 'أضف صورة',
          child: GestureDetector(
            onTap: () => _pickImage(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: CustomPaint(
                painter: const _DashedBorderPainter(color: AppColors.iconBlueBorder),
                child: Container(
                  width: 106.r,
                  height: 106.r,
                  color: AppColors.permissionIconBg,
                  child: _buildContent(),
                ),
              ),
            ),
          ),
        ),
        if (errorMessage != null) ...[
          SizedBox(height: 8.h),
          Text(errorMessage!, style: AppTextStyles.errorText, textAlign: TextAlign.center),
        ],
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;

  const _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(12),
    );
    final path = Path()..addRRect(rrect);
    final dashedPath = Path();
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        const dashLength = 6.0;
        const gapLength = 4.0;
        dashedPath.addPath(
          metric.extractPath(distance, distance + dashLength),
          Offset.zero,
        );
        distance += dashLength + gapLength;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) => oldDelegate.color != color;
}
