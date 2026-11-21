import '../../domain/entities/notification.dart';

import '../../../../core/localization/translations.dart';

/// The backend's `message` is already a full sentence, so only the bold title
/// line, the category chip and the icon are derived from the type.
String notificationTitleFor(NotificationType type) {
  return switch (type) {
    NotificationType.outOfStock => 'دواء نافد من المخزون'.tr,
    NotificationType.lowStock => 'مخزون منخفض'.tr,
    NotificationType.newInquiry => 'استفسار جديد'.tr,
    NotificationType.newRating => 'تقييم جديد'.tr,
    NotificationType.other => 'إشعار'.tr,
  };
}

/// The small category chip on a notification.
String notificationCategoryFor(NotificationType type) {
  return switch (type) {
    NotificationType.outOfStock || NotificationType.lowStock => 'المخزون'.tr,
    NotificationType.newInquiry => 'الاستفسارات'.tr,
    NotificationType.newRating => 'التقييمات'.tr,
    NotificationType.other => 'عام'.tr,
  };
}

/// The icon in the box at the start of a notification.
String notificationIconAssetFor(NotificationType type) {
  return switch (type) {
    NotificationType.outOfStock || NotificationType.lowStock => 'assets/icons/order_icon.svg',
    NotificationType.newInquiry => 'assets/icons/massage_icon.svg',
    NotificationType.newRating || NotificationType.other => 'assets/icons/bell_icon.svg',
  };
}
