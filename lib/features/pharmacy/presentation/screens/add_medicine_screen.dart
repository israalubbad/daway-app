import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/helpers/digits_only_formatter.dart';
import '../../../../core/helpers/text_controller_sync.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_text_styles.dart';
import '../../../../core/widgets/app_custom_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../cubit/add_medicine_cubit.dart';
import '../cubit/add_medicine_state.dart';
import '../widgets/medicine_image_picker.dart';
import '../widgets/pharmacy_form_field.dart';
import '../widgets/pharmacy_products_header.dart';
import 'search_medicine_catalog_screen.dart';

import '../../../../core/localization/translations.dart';

/// "إضافة منتج جديد": the photo, the names, the active ingredient, the
/// category, and the stock and price. The medicine is added by name from what
/// is typed here, unless it was picked from the catalog on the search page —
/// then its names and ingredient are filled in and locked.
///
/// Expects an [AddMedicineCubit] above it, and pops `true` once saved.
class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _activeIngredientController;
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;
  bool _attemptedSave = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _activeIngredientController = TextEditingController();
    _priceController = TextEditingController();
    _quantityController = TextEditingController();
    context.read<AddMedicineCubit>().loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _activeIngredientController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _openSearch() async {
    final cubit = context.read<AddMedicineCubit>()..searchReset();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: const SearchMedicineCatalogScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocConsumer<AddMedicineCubit, AddMedicineState>(
          listener: (context, state) {
            if (state is AddMedicineFailure) {
              AppSnackbar.show(context, state.message);
            }
            if (state is AddMedicineSuccess) {
              Navigator.of(context).pop(true);
            }
          },
          builder: (context, state) {
            final cubit = context.read<AddMedicineCubit>();
            final formData = state.formData;
            _nameController.syncText(formData.nameQuery);
            _activeIngredientController.syncText(formData.activeIngredient);
            _priceController.syncText(formData.price);
            _quantityController.syncText(formData.quantity);

            final isFromCatalog = !formData.isManualEntry;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PharmacyProductsHeader(
                    title: 'إضافة منتج جديد'.tr,
                    subtitle: 'أضف بيانات الدواء او المنتج'.tr,
                    onBack: () => Navigator.of(context).pop(false),
                  ),
                  SizedBox(height: 16.h),
                  _SearchEntry(
                    selectedName: formData.selectedMedicine?.name,
                    onSearchTap: _openSearch,
                    onClearTap: cubit.selectionCleared,
                  ),
                  SizedBox(height: 16.h),
                  MedicineImagePicker(
                    imageLocalPath: formData.imageLocalPath,
                    imageUrl: formData.imageUrl,
                    isUploading: formData.isUploadingImage,
                    errorMessage: formData.imageError,
                    onImagePicked: cubit.imageSelected,
                  ),
                  SizedBox(height: 24.h),
                  PharmacyFormField(
                    label: 'اسم الدواء/ المنتج (بالإنجليزي)'.tr,
                    controller: _nameController,
                    readOnly: isFromCatalog,
                    onChanged: cubit.nameChanged,
                    errorText: formData.nameHasArabicChars
                        ? 'يجب أن يكون الاسم بالإنجليزي فقط'.tr
                        : (_attemptedSave && formData.nameQuery.trim().isEmpty
                              ? 'هذا الحقل مطلوب'.tr
                              : null),
                  ),
                  SizedBox(height: 16.h),
                  PharmacyFormField(
                    label: 'المادة الفعالة'.tr,
                    controller: _activeIngredientController,
                    readOnly: isFromCatalog,
                    onChanged: cubit.activeIngredientChanged,
                  ),
                  if (!isFromCatalog) ...[
                    SizedBox(height: 16.h),
                    _CategoryField(
                      formData: formData,
                      showRequiredError: _attemptedSave,
                      onChanged: cubit.categorySelected,
                      onRetry: cubit.loadCategories,
                    ),
                  ],
                  SizedBox(height: 16.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: PharmacyFormField(
                          label: 'الكمية المتوفرة'.tr,
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [DigitsOnlyFormatter()],
                          onChanged: cubit.quantityChanged,
                          errorText: _attemptedSave && (formData.quantityValue ?? 0) <= 0
                              ? 'هذا الحقل مطلوب'.tr
                              : null,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: PharmacyFormField(
                          label: 'السعر'.tr,
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          onChanged: cubit.priceChanged,
                          errorText: _attemptedSave && (formData.priceValue ?? 0) <= 0
                              ? 'هذا الحقل مطلوب'.tr
                              : null,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32.h),
                  AppCustomButton(
                    text: 'حفظ المنتج'.tr,
                    isLoading: state is AddMedicineSaving,
                    textStyle: AppTextStyles.pharmacyPageSubtitle,
                    onPressed: () {
                      setState(() => _attemptedSave = true);
                      if (formData.canSubmit) cubit.save();
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The way into the search page — or, once a medicine was picked there, what
/// was picked and how to drop it.
class _SearchEntry extends StatelessWidget {
  final String? selectedName;
  final VoidCallback onSearchTap;
  final VoidCallback onClearTap;

  const _SearchEntry({
    required this.selectedName,
    required this.onSearchTap,
    required this.onClearTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = selectedName;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.permissionIconBg,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.iconBlueBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 20.sp, color: AppColors.mainTeal),
          SizedBox(width: 8.w),
          Expanded(
            child: name == null
                ? GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onSearchTap,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 6.h),
                      child: Text(
                        'الدواء موجود في القائمة؟ ابحث عنه'.tr,
                        style: AppTextStyles.pharmacySearchText.copyWith(
                          color: AppColors.mainTeal,
                        ),
                      ),
                    ),
                  )
                : Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.pharmacySearchText,
                  ),
          ),
          if (name != null)
            IconButton(
              tooltip: 'إلغاء الاختيار'.tr,
              onPressed: onClearTap,
              icon: Icon(Icons.close, size: 20.sp, color: AppColors.mainTeal),
            ),
        ],
      ),
    );
  }
}

class _CategoryField extends StatelessWidget {
  final AddMedicineFormData formData;
  final bool showRequiredError;
  final ValueChanged<int> onChanged;
  final VoidCallback onRetry;

  const _CategoryField({
    required this.formData,
    required this.showRequiredError,
    required this.onChanged,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final error = formData.categoriesError;
    if (error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('التصنيف'.tr, style: AppTextStyles.pharmacySearchText),
          SizedBox(height: 8.h),
          Text(error, style: AppTextStyles.errorText),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(onPressed: onRetry, child: Text('إعادة المحاولة'.tr)),
          ),
        ],
      );
    }

    return PharmacyDropdownField<int>(
      label: 'التصنيف'.tr,
      hintText: formData.isLoadingCategories ? 'جارٍ التحميل...'.tr : 'اختر التصنيف'.tr,
      value: formData.categoryId,
      items: [
        for (final category in formData.categories)
          DropdownMenuItem(value: category.id, child: Text(category.nameAr)),
      ],
      onChanged: formData.isLoadingCategories
          ? null
          : (value) {
              if (value != null) onChanged(value);
            },
      errorText: showRequiredError && formData.categoryId == null ? 'اختر التصنيف'.tr : null,
    );
  }
}
