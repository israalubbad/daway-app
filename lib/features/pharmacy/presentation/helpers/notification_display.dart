import '../../domain/entities/notification.dart';

/// The backend's `message` is already a full sentence, so only the bold title
/// line, the category chip and the icon are derived from the type.
String notificationTitleFor(NotificationType type) {
  return switch (type) {
    NotificationType.outOfStock => 'دواء نافد من المخزون',
    NotificationType.lowStock => 'مخزون منخفض',
    NotificationType.newInquiry => 'استفسار جديد',
    NotificationType.newRating => 'تقييم جديد',
    NotificationType.other => 'إشعار',
  };
}

/// The small category chip on a notification.
String notificationCategoryFor(NotificationType type) {
  return switch (type) {
    NotificationType.outOfStock || NotificationType.lowStock => 'المخزون',
    NotificationType.newInquiry => 'الاستفسارات',
    NotificationType.newRating => 'التقييمات',
    NotificationType.other => 'عام',
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
