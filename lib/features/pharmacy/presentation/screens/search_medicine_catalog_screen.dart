import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_text_styles.dart';
import '../../../../core/widgets/app_custom_button.dart';
import '../../domain/entities/medicine_catalog_item.dart';
import '../cubit/add_medicine_cubit.dart';
import '../cubit/add_medicine_state.dart';
import '../widgets/pharmacy_form_field.dart';
import '../widgets/pharmacy_products_header.dart';

/// The second page of "إضافة منتج جديد": search the catalog by name, and tap a
/// result to fill the form with it (the page then closes).
///
/// Expects the [AddMedicineCubit] of the form above it.
class SearchMedicineCatalogScreen extends StatefulWidget {
  const SearchMedicineCatalogScreen({super.key});

  @override
  State<SearchMedicineCatalogScreen> createState() => _SearchMedicineCatalogScreenState();
}

class _SearchMedicineCatalogScreenState extends State<SearchMedicineCatalogScreen> {
  late final TextEditingController _queryController;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _search() {
    FocusScope.of(context).unfocus();
    context.read<AddMedicineCubit>().search(_queryController.text);
  }

  void _select(MedicineCatalogItem medicine) {
    context.read<AddMedicineCubit>().medicineSelected(medicine);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PharmacyProductsHeader(
                title: 'إضافة منتج جديد',
                subtitle: 'أضف بيانات الدواء او المنتج',
                onBack: () => Navigator.of(context).pop(),
              ),
              SizedBox(height: 24.h),
              PharmacyFormField(
                label: 'اسم الدواء/ المنتج',
                controller: _queryController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
              ),
              SizedBox(height: 24.h),
              BlocBuilder<AddMedicineCubit, AddMedicineState>(
                buildWhen: (previous, current) =>
                    previous.formData.isSearching != current.formData.isSearching,
                builder: (context, state) => AppCustomButton(
                  text: 'بحث عن الدواء/المنتج',
                  isLoading: state.formData.isSearching,
                  textStyle: AppTextStyles.pharmacyPageSubtitle,
                  onPressed: _search,
                ),
              ),
              SizedBox(height: 16.h),
              _Results(onSelected: _select),
            ],
          ),
        ),
      ),
    );
  }
}

/// What the last search found — or why there is nothing to show.
class _Results extends StatelessWidget {
  final ValueChanged<MedicineCatalogItem> onSelected;

  const _Results({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddMedicineCubit, AddMedicineState>(
      buildWhen: (previous, current) =>
          previous.formData.suggestions != current.formData.suggestions ||
          previous.formData.searchError != current.formData.searchError ||
          previous.formData.hasSearched != current.formData.hasSearched,
      builder: (context, state) {
        final formData = state.formData;
        final error = formData.searchError;

        if (error != null) {
          return Text(error, textAlign: TextAlign.center, style: AppTextStyles.errorText);
        }
        if (formData.hasSearched && formData.suggestions.isEmpty) {
          return Padding(
            padding: EdgeInsets.only(top: 16.h),
            child: Text(
              'لا توجد نتائج. يمكنك إضافته كمنتج جديد.',
              textAlign: TextAlign.center,
              style: AppTextStyles.cardDescription,
            ),
          );
        }

        return Column(
          children: [
            for (final item in formData.suggestions) ...[
              _ResultTile(item: item, onTap: () => onSelected(item)),
              SizedBox(height: 8.h),
            ],
          ],
        );
      },
    );
  }
}

class _ResultTile extends StatelessWidget {
  final MedicineCatalogItem item;
  final VoidCallback onTap;

  const _ResultTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final subtitle = item.activeIngredient;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: AppTextStyles.cardTitle.copyWith(fontSize: 14.sp)),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(subtitle, style: AppTextStyles.footerText),
                  ],
                ],
              ),
            ),
            if (item.type != null) _SourceBadge(type: item.type!),
          ],
        ),
      ),
    );
  }
}

/// Mirrors the pharmacy web dashboard's "القائمة العامة"/"وزارة الصحة"
/// pills — `type` is `"medicine"` for the pharmacy's general catalog
/// (`data.medicines`) or `"moh"` for a Ministry of Health entry
/// (`data.moh_catalog`), both confirmed against a live response.
class _SourceBadge extends StatelessWidget {
  final String type;

  const _SourceBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final label = type == 'moh' ? 'وزارة الصحة' : 'القائمة العامة';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.primaryTeal.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600, color: AppColors.primaryTeal),
      ),
    );
  }
}
