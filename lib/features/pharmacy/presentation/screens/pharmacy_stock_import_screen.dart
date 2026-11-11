import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../core/helpers/api_result.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_fonts.dart';
import '../../../../core/theming/app_text_styles.dart';
import '../../../../core/widgets/app_custom_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/dashed_border_box.dart';
import '../../domain/entities/inventory_import_preview.dart';
import '../cubit/pharmacy_stock_import_cubit.dart';
import '../cubit/pharmacy_stock_import_state.dart';
import '../widgets/pharmacy_products_header.dart';

import '../../../../core/localization/translations.dart';

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

  /// Fetches a spreadsheet and hands it to the system's save dialog.
  Future<void> _saveSpreadsheet(
    BuildContext context, {
    required Future<ApiResult<Uint8List>> Function() fetch,
    required String fileName,
  }) async {
    final result = await fetch();
    if (!context.mounted) return;

    switch (result) {
      case Success(:final data):
        final saved = await FilePicker.saveFile(
          dialogTitle: 'حفظ ملف Excel'.tr,
          fileName: fileName,
          bytes: data,
        );
        if (saved != null && context.mounted) {
          AppSnackbar.show(context, 'تم حفظ الملف'.tr);
        }
      case ApiError(:final failure):
        AppSnackbar.show(context, failure.message);
    }
  }

  void _onPrimaryTap(BuildContext context, PharmacyStockImportState state) {
    final cubit = context.read<PharmacyStockImportCubit>();
    switch (state) {
      case StockImportIdle(file: null):
        AppSnackbar.show(context, 'اختر ملف المنتجات أولاً'.tr);
      case StockImportIdle():
        cubit.analyze();
      case StockImportAnalyzed(:final preview) when !preview.canCommit:
        AppSnackbar.show(context, 'لا يمكن تحديث المنتجات من هذا الملف، راجع الأخطاء فيه'.tr);
      case StockImportAnalyzed():
        cubit.update();
      case StockImportAnalyzing() || StockImportUpdating() || StockImportUpdated():
    }
  }

  static String _todayStamp() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}$month$day';
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PharmacyStockImportCubit>();

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
                          title: 'تحديث المنتجات'.tr,
                          subtitle: 'حدث قائمة منتجاتك بسهولة'.tr,
                          onBack: () => Navigator.of(context).pop(false),
                        ),
                        SizedBox(height: 24.h),
                        _UploadBox(
                          file: state.file,
                          onPick: () => _pickFile(context),
                          isBusy: state is StockImportAnalyzing || state is StockImportUpdating,
                        ),
                        SizedBox(height: 24.h),
                        _DownloadCard(
                          title: 'تنزيل قالب Excel'.tr,
                          subtitle: 'استخدم القالب لإضافة منتجاتك بالصيغة المطلوبة.'.tr,
                          leading: _DownloadCardIcon(
                            background: AppColors.accountIconBg,
                            size: 40,
                            child: SvgPicture.asset(
                              'assets/icons/file_text_blue_icon.svg',
                              width: 24.w,
                              height: 24.w,
                            ),
                          ),
                          onTap: () => _saveSpreadsheet(
                            context,
                            fetch: cubit.downloadTemplate,
                            fileName: 'products-template.xlsx',
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Text('ملف المنتجات الحالي'.tr, style: AppTextStyles.pharmacySearchText),
                        SizedBox(height: 12.h),
                        _DownloadCard(
                          title: 'inventory-current-${_todayStamp()}.xlsx',
                          subtitle: 'كل منتجاتك الحالية مع الأسعار والكميات'.tr,
                          ltrTitle: true,
                          leading: _DownloadCardIcon(
                            background: const Color(0xFFEBF8F2),
                            size: 43,
                            child: SvgPicture.asset(
                              'assets/icons/excel_file_icon.svg',
                              width: 26.w,
                              height: 26.w,
                            ),
                          ),
                          onTap: () => _saveSpreadsheet(
                            context,
                            fetch: cubit.exportCurrentInventory,
                            fileName: 'inventory-current-${_todayStamp()}.xlsx',
                          ),
                        ),
                        if (state case StockImportAnalyzed(:final preview) ||
                            StockImportUpdating(:final preview)) ...[
                          SizedBox(height: 16.h),
                          _AnalysisCard(preview: preview),
                          SizedBox(height: 16.h),
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
                        'تحديث المنتجات'.tr,
                      _ => 'تحليل الملف'.tr,
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
      backgroundColor: AppColors.permissionIconBg,
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
            Container(
              width: 52.w,
              height: 52.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: const Color(0xFFB9DFED), width: 0.8),
              ),
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
                'رفع ملف منتجاتك'.tr,
                textAlign: TextAlign.center,
                style: AppTextStyles.pharmacyUploadTitle,
              ),
              Text(
                'ارفع ملف Excel يحتوي على منتجات الصيدلية.'.tr,
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
                  style: AppTextStyles.pharmacyUploadTitle,
                ),
              ),
              Text(
                'جاهز للتحليل · {0}'.trArgs([_formatSize(file.sizeBytes)]),
                textAlign: TextAlign.center,
                style: AppTextStyles.pharmacyUploadSubtitle,
              ),
            ],
            SizedBox(height: 14.h),
            GestureDetector(
              onTap: isBusy ? null : onPick,
              behavior: HitTestBehavior.opaque,
              child: Container(
                constraints: BoxConstraints(minWidth: 142.w),
                height: 43.h,
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: 18.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: AppColors.iconBlueBorder, width: 0.8),
                ),
                child: Text(
                  file == null ? 'اختيار ملف'.tr : 'استبدال الملف'.tr,
                  style: AppTextStyles.pharmacyUploadButton,
                ),
              ),
            ),
            if (file != null) ...[
              SizedBox(height: 8.h),
              Text(
                'XLSX أو XLS'.tr,
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

/// A 392x75.6 outlined row: a [leading] tile, a title and a line under it, and
/// a download button at the far end. The whole row saves its file when tapped.
class _DownloadCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget leading;
  final bool ltrTitle;
  final VoidCallback onTap;

  const _DownloadCard({
    required this.title,
    required this.subtitle,
    required this.leading,
    this.ltrTitle = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final titleText = Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.pharmacySearchText,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        constraints: BoxConstraints(minHeight: 75.6.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            leading,
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ltrTitle
                      ? Directionality(textDirection: TextDirection.ltr, child: titleText)
                      : titleText,
                  Text(
                    subtitle,
                    style: AppTextStyles.pharmacyUploadSubtitle.copyWith(fontSize: 11.sp),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            _DownloadCardIcon(
              background: AppColors.accountIconBg,
              size: 40,
              child: SvgPicture.asset('assets/icons/download_icon.svg', width: 24.w, height: 24.w),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadCardIcon extends StatelessWidget {
  final Color background;
  final double size;
  final Widget child;

  const _DownloadCardIcon({required this.background, required this.size, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.w,
      height: size.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(8.r)),
      child: child,
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
        color: const Color(0xFFFBFEFD),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFBFE6D6), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF8F2),
                  borderRadius: BorderRadius.circular(19.r),
                ),
                child: Icon(Icons.check, size: 22.sp, color: AppColors.productAvailableText),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تم تحليل الملف بنجاح'.tr,
                      style: AppFonts.tajawal(
                        TextStyle(
                          fontSize: 15.sp,
                          height: 22.5 / 15,
                          color: AppColors.onboardingText,
                        ),
                        FontWeight.w700,
                      ),
                    ),
                    Text(
                      'تم العثور على {0} منتجًا ويمكنك تحديث قائمة منتجاتك.'.trArgs([preview.totalCount]),
                      style: AppTextStyles.pharmacyUploadSubtitle.copyWith(fontSize: 11.sp),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(child: _StatTile(value: preview.totalCount, label: 'عدد المنتجات'.tr)),
              SizedBox(width: 8.w),
              Expanded(child: _StatTile(value: preview.updatedCount, label: 'منتجات محدثة'.tr)),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(child: _StatTile(value: preview.newCount, label: 'منتجات جديدة'.tr)),
              SizedBox(width: 8.w),
              Expanded(child: _StatTile(value: preview.errorCount, label: 'تحتوي على اخطاء'.tr)),
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
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: AppColors.cardBorder, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: AppFonts.tajawal(
              TextStyle(fontSize: 17.sp, height: 25.5 / 17, color: AppColors.mainTeal),
              FontWeight.w700,
            ),
          ),
          Text(label, style: AppTextStyles.pharmacyUploadSubtitle.copyWith(fontSize: 11.sp)),
        ],
      ),
    );
  }
}
