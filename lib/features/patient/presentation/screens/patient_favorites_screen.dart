import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/routing/routes.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/profile_load_error.dart';
import '../cubit/favorite_medicines_cubit.dart';
import '../cubit/favorite_medicines_state.dart';
import '../widgets/favorite_medicine_card.dart';
import '../widgets/patient_sub_screen_header.dart';

import '../../../../core/localization/translations.dart';

/// "الأدوية المحفوظة" — backed by the real `GET /patient/favorites/medicines`
/// endpoint. Expects a [FavoriteMedicinesCubit] to already be provided above
/// it (see [PatientAccountScreen]'s `_openFavorites`).
class PatientFavoritesScreen extends StatelessWidget {
  const PatientFavoritesScreen({super.key});

  void _openDetails(BuildContext context, int medicineId) =>
      Navigator.of(context).pushNamed(Routes.medicineDetailScreen, arguments: medicineId);

  void _browseProducts(BuildContext context) {
    Navigator.of(context).pushNamed(Routes.allCategoriesScreen);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PatientSubScreenHeader(
                title: 'الأدوية المحفوظة'.tr,
                description: 'الوصول السريع إلى أدويتك المحفوظة'.tr,
              ),
              SizedBox(height: 32.h),
              BlocBuilder<FavoriteMedicinesCubit, FavoriteMedicinesState>(
                builder: (context, state) {
                  return switch (state) {
                    FavoriteMedicinesLoading() => Padding(
                        padding: EdgeInsets.only(top: 48.h),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    FavoriteMedicinesLoadFailure(:final message) => ProfileLoadError(
                        message: message,
                        onRetry: () => context.read<FavoriteMedicinesCubit>().load(),
                      ),
                    FavoriteMedicinesLoaded(:final medicines) when medicines.isEmpty =>
                      EmptyStateView(
                        imageAsset: 'assets/images/save_image.png',
                        title: 'لا يوجد منتجات محفوظة'.tr,
                        subtitle: 'احفظ المنتجات لتظهر هنا'.tr,
                        actionLabel: 'تصفح المنتجات'.tr,
                        onActionTap: () => _browseProducts(context),
                      ),
                    FavoriteMedicinesLoaded(:final medicines) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final medicine in medicines) ...[
                            FavoriteMedicineCard(
                              medicine: medicine,
                              onDetailsTap: () => _openDetails(context, medicine.medicineId),
                            ),
                            SizedBox(height: 24.h),
                          ],
                        ],
                      ),
                  };
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
