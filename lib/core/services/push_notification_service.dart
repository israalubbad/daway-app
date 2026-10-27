import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../../features/auth/domain/repositories/push_token_source.dart';
import '../../features/auth/domain/usecases/get_session_usecase.dart';
import '../../features/auth/domain/usecases/register_device_token_usecase.dart';
import 'notification_service.dart';

/// Wires FCM into the app: shows pushes that arrive in the foreground and
/// re-registers the device when Firebase rotates its token. Registration at
/// login / logout is handled by DeviceTokenSyncingSessionRepository.
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

    _tokenSource.onTokenRefresh.listen(_registerFor);
    // Already signed in: this launch's token may be new to the backend.
    unawaited(_registerFor(null));
  }

  Future<void> _registerFor(String? fcmToken) async {
    try {
      final session = await _getSession();
      if (session == null) return;
      await _register(authToken: session.token, fcmToken: fcmToken);
    } catch (_) {}
  }
}
