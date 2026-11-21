import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../../features/auth/domain/entities/account_type.dart';
import '../../features/auth/domain/repositories/push_token_source.dart';
import '../../features/auth/domain/usecases/get_session_usecase.dart';
import '../../features/auth/domain/usecases/register_device_token_usecase.dart';
import '../routing/app_navigator.dart';
import '../routing/routes.dart';
import 'notification_service.dart';

/// Wires FCM into the app: shows pushes that arrive in the foreground, opens
/// the notifications screen when a push is tapped (app in the background or
/// closed) and re-registers the device when Firebase rotates its token.
/// Registration at login / logout is handled by
/// DeviceTokenSyncingSessionRepository.
///
/// A push that arrives while the app is in the background or closed is drawn by
/// the system itself, as long as it carries a `notification` block.
class PushNotificationService {
  final PushTokenSource _tokenSource;
  final GetSessionUseCase _getSession;
  final RegisterDeviceTokenUseCase _register;

  const PushNotificationService(this._tokenSource, this._getSession, this._register);

  Future<void> init() async {
    final messaging = FirebaseMessaging.instance;
    // iOS draws foreground pushes itself; Android needs showPush below.
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    if (Platform.isIOS) await messaging.requestPermission();

    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null || !Platform.isAndroid) return;
      NotificationService.showPush(
        id: message.hashCode,
        title: notification.title,
        body: notification.body,
      );
    });

    // A push tapped while the app was in the background.
    FirebaseMessaging.onMessageOpenedApp.listen((_) => unawaited(_openNotifications()));

    _tokenSource.onTokenRefresh.listen(_registerFor);
    // Already signed in: this launch's token may be new to the backend.
    unawaited(_registerFor(null));
  }

  /// Call once the app's first frame is up: a push tapped while the app was
  /// closed launched it, and should land on the notifications screen.
  Future<void> openNotificationsIfLaunchedByPush() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) await _openNotifications();
  }

  Future<void> _openNotifications() async {
    try {
      final session = await _getSession();
      final navigator = appNavigatorKey.currentState;
      if (session == null || navigator == null) return;
      await navigator.pushNamed(
        session.accountType == AccountType.pharmacy
            ? Routes.pharmacyNotificationsScreen
            : Routes.patientNotificationsScreen,
      );
    } catch (_) {}
  }

  Future<void> _registerFor(String? fcmToken) async {
    try {
      final session = await _getSession();
      if (session == null) return;
      await _register(authToken: session.token, fcmToken: fcmToken);
    } catch (_) {}
  }
}
