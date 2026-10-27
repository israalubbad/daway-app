/// Where this device's push token and identity come from.
abstract class PushTokenSource {
  /// Null when push is not available (permission denied, no APNs token yet).
  Future<String?> fcmToken();

  Stream<String> get onTokenRefresh;

  /// Stable per install; lets the backend replace a rotated token instead of
  /// piling up stale ones.
  Future<String> deviceId();

  /// `android` or `ios`.
  String get platform;
}
