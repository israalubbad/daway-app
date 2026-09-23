import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/routing/routes.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/widgets/profile_load_error.dart';
import '../../../auth/presentation/cubit/logout_cubit.dart';
import '../../../auth/presentation/cubit/logout_state.dart';
import '../../domain/entities/pharmacy_dashboard_stats.dart';
import '../cubit/pharmacy_dashboard_cubit.dart';
import '../cubit/pharmacy_dashboard_state.dart';
import '../helpers/notifications_navigation.dart';
import '../widgets/add_medicine_file_card.dart';
import '../widgets/pharmacy_dashboard_tab_scope.dart';
import '../widgets/pharmacy_home_header.dart';
import '../widgets/pharmacy_mini_stat_card.dart';
import '../widgets/pharmacy_orders_pending_section.dart';
import '../widgets/pharmacy_summary_stat_card.dart';

/// Home tab of the pharmacy dashboard shell — has no Scaffold/AppBar/Drawer
/// of its own (the redesign has no hamburger icon in the header, mirroring
/// the patient home screen); the drawer stays reachable from the other
/// tabs' own Scaffolds.
class PharmacyHomeScreen extends StatelessWidget {
  const PharmacyHomeScreen({super.key});

  Future<void> _openAddMedicine(BuildContext context) async {
    final added = await Navigator.of(
      context,
    ).pushNamed(Routes.addPharmacyMedicineScreen);
    if (added == true && context.mounted) {
      context.read<PharmacyDashboardCubit>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LogoutCubit, LogoutState>(
      listenWhen: (previous, current) =>
          !previous.isLoggedOut && current.isLoggedOut,
      listener: (context, state) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(Routes.accountTypeScreen, (route) => false);
      },
      child: SafeArea(
        child: BlocBuilder<PharmacyDashboardCubit, PharmacyDashboardState>(
          builder: (context, state) {
            return switch (state) {
              PharmacyDashboardLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              PharmacyDashboardLoadFailure(:final message) => ProfileLoadError(
                message: message,
                onRetry: () => context.read<PharmacyDashboardCubit>().load(),
              ),
              PharmacyDashboardLoaded(:final stats) => _buildLoaded(
                context,
                stats,
              ),
            };
          },
        ),
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, PharmacyDashboardStats stats) {
    final isEmpty = stats.totalMedicines == 0;

    return ListView(
      padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 24.h),
      children: [
        PharmacyHomeHeader(onNotificationsTap: () => openNotifications(context)),
        SizedBox(height: 24.h),
        if (isEmpty) ...[
          AddMedicineFileCard(onTap: () => _openAddMedicine(context)),
          SizedBox(height: 16.h),
        ],
        Row(
          children: [
            Expanded(
              child: PharmacySummaryStatCard(
                label: 'إجمالي المبيعات الشهرية',
                // No sales/orders API yet — kept as a placeholder instead
                // of a fabricated figure until the backend adds one.
                value: '—',
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: PharmacySummaryStatCard(
                label: 'إجمالي المنتجات',
                value: '${stats.totalMedicines}',
                showArrow: true,
                onTap: () =>
                    PharmacyDashboardTabScope.switchToTabOrShowComingSoon(
                      context,
                      PharmacyDashboardTab.medicines,
                    ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: PharmacyMiniStatCard(
                value: stats.averageRating?.toStringAsFixed(1) ?? '—',
                label: 'التقييمات',
                categoryColor: AppColors.statRatingColor,
                onTap: () =>
                    Navigator.of(context).pushNamed(Routes.pharmacyRatingsScreen),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: PharmacyMiniStatCard(
                value: '${stats.outOfStockCount}',
                label: 'نافذ',
                categoryColor: AppColors.statOutOfStockColor,
                onTap: () =>
                    PharmacyDashboardTabScope.switchToTabOrShowComingSoon(
                      context,
                      PharmacyDashboardTab.inventory,
                    ),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: PharmacyMiniStatCard(
                value: '${stats.lowStockCount}',
                label: 'مخزون منخفض',
                categoryColor: AppColors.statLowStockColor,
                onTap: () =>
                    PharmacyDashboardTabScope.switchToTabOrShowComingSoon(
                      context,
                      PharmacyDashboardTab.inventory,
                    ),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: PharmacyMiniStatCard(
                value: '${stats.availableCount}',
                label: 'متوفرة',
                categoryColor: AppColors.statAvailableColor,
                onTap: () =>
                    PharmacyDashboardTabScope.switchToTabOrShowComingSoon(
                      context,
                      PharmacyDashboardTab.inventory,
                    ),
              ),
            ),
          ],
        ),
        if (!isEmpty) ...[
          SizedBox(height: 24.h),
          const PharmacyOrdersPendingSection(),
        ],
      ],
    );
  }
}
