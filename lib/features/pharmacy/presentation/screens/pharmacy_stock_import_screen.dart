import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../core/helpers/api_result.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_text_styles.dart';
import '../../../../core/widgets/app_custom_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/dashed_border_box.dart';
import '../../domain/entities/inventory_import_preview.dart';
import '../cubit/pharmacy_stock_import_cubit.dart';
import '../cubit/pharmacy_stock_import_state.dart';
import '../widgets/pharmacy_products_header.dart';

/// "تحديث المنتجات": pick a stock spreadsheet, have it analysed, and confirm
/// the update. Pops `true` once the update went through.
///
/// Expects a [PharmacyStockImportCubit] above it.
class PharmacyStockImportScreen extends StatelessWidget {
  const PharmacyStockImportScreen({super.key});

  Future<void> _pickFile(BuildContext context) async {
    final cubit = context.read<PharmacyStockImportCubit>();
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'xls'],
    );
    final path = picked?.path;
    if (picked == null || path == null) return;
    final size = await picked.length() ?? 0;
    cubit.fileSelected(PickedStockFile(path: path, name: picked.name, sizeBytes: size));
  }

  Future<void> _downloadTemplate(BuildContext context) async {
    final cubit = context.read<PharmacyStockImportCubit>();
    final result = await cubit.downloadTemplate();
    if (!context.mounted) return;

    switch (result) {
      case Success(:final data):
        final saved = await FilePicker.saveFile(
          dialogTitle: 'حفظ قالب Excel',
          fileName: 'products-template.xlsx',
          bytes: data,
        );
        if (saved != null && context.mounted) {
          AppSnackbar.show(context, 'تم حفظ القالب');
        }
      case ApiError(:final failure):
        AppSnackbar.show(context, failure.message);
    }
  }

  void _onPrimaryTap(BuildContext context, PharmacyStockImportState state) {
    final cubit = context.read<PharmacyStockImportCubit>();
    switch (state) {
      case StockImportIdle(file: null):
        AppSnackbar.show(context, 'اختر ملف المنتجات أولاً');
      case StockImportIdle():
        cubit.analyze();
      case StockImportAnalyzed(:final preview) when !preview.canCommit:
        AppSnackbar.show(context, 'لا يمكن تحديث المنتجات من هذا الملف، راجع الأخطاء فيه');
      case StockImportAnalyzed():
        cubit.update();
      case StockImportAnalyzing() || StockImportUpdating() || StockImportUpdated():
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocConsumer<PharmacyStockImportCubit, PharmacyStockImportState>(
          listener: (context, state) {
            switch (state) {
              case StockImportIdle(:final message?):
                AppSnackbar.show(context, message);
              case StockImportAnalyzed(:final updateError?):
                AppSnackbar.show(context, updateError);
              case StockImportUpdated():
                Navigator.of(context).pop(true);
              default:
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 24.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PharmacyProductsHeader(
                          title: 'تحديث المنتجات',
                          subtitle: 'حدث قائمة منتجاتك بسهولة',
                          onBack: () => Navigator.of(context).pop(false),
                        ),
                        SizedBox(height: 24.h),
                        _UploadBox(
                          file: state.file,
                          onPick: () => _pickFile(context),
                          isBusy: state is StockImportAnalyzing || state is StockImportUpdating,
                        ),
                        SizedBox(height: 16.h),
                        _TemplateCard(onTap: () => _downloadTemplate(context)),
                        if (state case StockImportAnalyzed(:final preview) ||
                            StockImportUpdating(:final preview)) ...[
                          SizedBox(height: 24.h),
                          _AnalysisCard(preview: preview),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
                  child: AppCustomButton(
                    text: switch (state) {
                      StockImportAnalyzed() || StockImportUpdating() || StockImportUpdated() =>
                        'تحديث المنتجات',
                      _ => 'تحليل الملف',
                    },
                    isLoading: state is StockImportAnalyzing || state is StockImportUpdating,
                    textStyle: AppTextStyles.pharmacyPageSubtitle,
                    onPressed: () => _onPrimaryTap(context, state),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The dashed box: the invitation to pick a spreadsheet, or — once one is
/// picked — its name and size with a way to swap it.
class _UploadBox extends StatelessWidget {
  final PickedStockFile? file;
  final VoidCallback onPick;
  final bool isBusy;

  const _UploadBox({required this.file, required this.onPick, required this.isBusy});

  @override
  Widget build(BuildContext context) {
    final file = this.file;
    return DashedBorderBox(
      color: AppColors.mainTeal,
      backgroundColor: file == null ? AppColors.permissionIconBg : Colors.white,
      radius: 8.r,
      dashLength: 8.w,
      gapLength: 8.w,
      child: Container(
        constraints: BoxConstraints(minHeight: 215.h),
        alignment: Alignment.center,
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _IconTile(
              child: SvgPicture.asset(
                file == null
                    ? 'assets/icons/upload_icon.svg'
                    : 'assets/icons/file_text_blue_icon.svg',
                width: 24.w,
                height: 24.w,
              ),
            ),
            SizedBox(height: 13.h),
            if (file == null) ...[
              Text(
                'رفع ملف المنتجات',
                textAlign: TextAlign.center,
                style: AppTextStyles.pharmacyUploadTitle,
              ),
              Text(
                'ارفع ملف Excel يحتوي على منتجات الصيدلية.',
                textAlign: TextAlign.center,
                style: AppTextStyles.pharmacyUploadSubtitle,
              ),
            ] else ...[
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.pharmacyUploadTitle.copyWith(fontSize: 15.sp),
                ),
              ),
              Text(
                'جاهز للتحليل · ${_formatSize(file.sizeBytes)}',
                textAlign: TextAlign.center,
                style: AppTextStyles.pharmacyUploadSubtitle,
              ),
            ],
            SizedBox(height: 14.h),
            _OutlinedPill(
              label: file == null ? 'اختيار ملف' : 'استبدال الملف',
              onTap: isBusy ? null : onPick,
            ),
            if (file != null) ...[
              SizedBox(height: 8.h),
              Text(
                'XLSX أو XLS',
                style: AppTextStyles.pharmacyUploadSubtitle.copyWith(fontSize: 11.sp),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatSize(int bytes) {
    if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    final kilobytes = (bytes / 1024).ceil();
    return '${kilobytes < 1 ? 1 : kilobytes} KB';
  }
}

class _IconTile extends StatelessWidget {
  final Widget child;

  const _IconTile({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52.w,
      height: 52.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.iconBlueBorder, width: 0.8),
      ),
      child: child,
    );
  }
}

class _OutlinedPill extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _OutlinedPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 142.w,
        height: 44.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppColors.mainTeal),
        ),
        child: Text(label, style: AppTextStyles.pharmacyUploadButton),
      ),
    );
  }
}

/// "تنزيل قالب Excel": saves the backend's template spreadsheet.
class _TemplateCard extends StatelessWidget {
  final VoidCallback onTap;

  const _TemplateCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: AppColors.accountIconBg,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: SvgPicture.asset(
                'assets/icons/file_text_blue_icon.svg',
                width: 22.w,
                height: 22.w,
                fit: BoxFit.scaleDown,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('تنزيل قالب Excel', style: AppTextStyles.pharmacySearchText),
                  Text(
                    'استخدم القالب لإضافة منتجاتك بالصيغة المطلوبة.',
                    style: AppTextStyles.pharmacyUploadSubtitle.copyWith(fontSize: 11.sp),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: AppColors.accountIconBg,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(Icons.file_download_outlined, size: 22.sp, color: AppColors.mainTeal),
            ),
          ],
        ),
      ),
    );
  }
}

/// "تم تحليل الملف بنجاح" and the four figures the backend found in it.
class _AnalysisCard extends StatelessWidget {
  final InventoryImportPreview preview;

  const _AnalysisCard({required this.preview});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FCFB),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFCFE9E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE6F5EF),
                ),
                child: Icon(Icons.check, size: 22.sp, color: AppColors.productAvailableText),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('تم تحليل الملف بنجاح', style: AppTextStyles.pharmacyUploadTitle),
                    Text(
                      'تم العثور على ${preview.totalCount} منتجًا ويمكنك تحديث قائمة منتجاتك.',
                      style: AppTextStyles.pharmacyUploadSubtitle.copyWith(fontSize: 11.sp),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(child: _StatTile(value: preview.totalCount, label: 'عدد المنتجات')),
              SizedBox(width: 8.w),
              Expanded(child: _StatTile(value: preview.updatedCount, label: 'منتجات محدثة')),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(child: _StatTile(value: preview.newCount, label: 'منتجات جديدة')),
              SizedBox(width: 8.w),
              Expanded(child: _StatTile(value: preview.errorCount, label: 'تحتوي على اخطاء')),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final int value;
  final String label;

  const _StatTile({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: AppTextStyles.pharmacyUploadTitle.copyWith(color: AppColors.mainTeal),
          ),
          Text(label, style: AppTextStyles.pharmacyUploadSubtitle.copyWith(fontSize: 11.sp)),
        ],
      ),
    );
  }
}
