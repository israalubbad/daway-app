import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_fonts.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/filter_tabs_row.dart';
import '../../../../core/widgets/profile_load_error.dart';
import '../../../patient/presentation/widgets/patient_sub_screen_header.dart';
import '../../domain/entities/notification.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';
import '../widgets/pharmacy_dashboard_tab_scope.dart';
import '../widgets/pharmacy_notification_item.dart';

/// "الإشعارات", laid out like the patient's: a back chip, the title, filter
/// tabs with counts, then one row per notification.
///
/// Pushed on top of the shell rather than being one of its tabs, so tapping a
/// notification that belongs to a tab (stock → المخزون, inquiry → المراسلات)
/// pops this screen with that [PharmacyDashboardTab] as the result — the
/// caller (the bell icon that pushed this screen, itself inside the shell)
/// is what actually switches tabs, since it's the one with
/// [PharmacyDashboardTabScope] in its context.
class PharmacyNotificationsScreen extends StatelessWidget {
  const PharmacyNotificationsScreen({super.key});

  Future<void> _handleTap(BuildContext context, AppNotification notification) async {
    if (!notification.isRead) {
      await context.read<NotificationsCubit>().markAsRead(notification.id);
    }
    if (!context.mounted) return;
    final tab = switch (notification.type) {
      NotificationType.lowStock ||
      NotificationType.outOfStock => PharmacyDashboardTab.inventory,
      NotificationType.newInquiry => PharmacyDashboardTab.inquiries,
      NotificationType.newRating || NotificationType.other => null,
    };
    if (tab != null) Navigator.of(context).pop(tab);
  }

  Future<void> _handleMarkAllAsRead(BuildContext context) async {
    final error = await context.read<NotificationsCubit>().markAllAsRead();
    if (error != null && context.mounted) {
      AppSnackbar.show(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<NotificationsCubit, NotificationsState>(
          builder: (context, state) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: const PatientSubScreenHeader(
                      title: 'الإشعارات',
                      description: 'تابع مخزونك واستفسارات عملائك',
                    ),
                  ),
                  SizedBox(height: 24.h),
                  switch (state) {
                    NotificationsLoading() => Padding(
                      padding: EdgeInsets.only(top: 48.h),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    NotificationsLoadFailure(:final message) => ProfileLoadError(
                      message: message,
                      onRetry: () => context.read<NotificationsCubit>().load(),
                    ),
                    NotificationsLoaded() => _buildLoaded(context, state),
                  },
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, NotificationsLoaded state) {
    final cubit = context.read<NotificationsCubit>();
    final all = state.notifications;
    int count(NotificationFilter filter) => NotificationsLoaded(
      notifications: all,
      unreadCount: state.unreadCount,
      filter: filter,
    ).filteredNotifications.length;
    final visible = state.filteredNotifications;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilterTabsRow<NotificationFilter>(
          selected: state.filter,
          onSelected: cubit.filterChanged,
          tabs: [
            FilterTabItem(
              value: NotificationFilter.all,
              label: 'الكل (${count(NotificationFilter.all)})',
            ),
            FilterTabItem(
              value: NotificationFilter.unread,
              label: 'غير مقروءة (${count(NotificationFilter.unread)})',
            ),
            FilterTabItem(
              value: NotificationFilter.inventory,
              label: 'المخزون (${count(NotificationFilter.inventory)})',
            ),
            FilterTabItem(
              value: NotificationFilter.inquiries,
              label: 'الاستفسارات (${count(NotificationFilter.inquiries)})',
            ),
          ],
        ),
        if (state.unreadCount > 0)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 0),
              child: TextButton(
                onPressed: state.markingAllAsRead ? null : () => _handleMarkAllAsRead(context),
                child: Text(
                  'تحديد الكل كمقروء',
                  style: AppFonts.tajawal(
                    TextStyle(fontSize: 13.sp, color: AppColors.mainTeal),
                    FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        SizedBox(height: 16.h),
        if (visible.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: const EmptyStateView(
              imageAsset: 'assets/images/empty_notifications.png',
              title: 'لا توجد إشعارات',
              topSpacing: 64,
            ),
          )
        else
          for (final notification in visible)
            PharmacyNotificationItem(
              notification: notification,
              onTap: () => _handleTap(context, notification),
            ),
      ],
    );
  }
}
