import 'dart:io';
import 'dart:math';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../../core/local_storage/secure_storage_service.dart';
import '../../domain/repositories/push_token_source.dart';

class FirebasePushTokenSource implements PushTokenSource {
  static const String _deviceIdKey = 'push_device_id';

  final SecureStorageService _storage;

  const FirebasePushTokenSource(this._storage);

  @override
  Future<String?> fcmToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      // iOS before the APNs token arrives, or Play services missing: skip,
      // onTokenRefresh delivers it later.
      return null;
    }
  }

  @override
  Stream<String> get onTokenRefresh => FirebaseMessaging.instance.onTokenRefresh;

  @override
  Future<String> deviceId() async {
    final saved = await _storage.read(key: _deviceIdKey);
    if (saved != null && saved.isNotEmpty) return saved;
    final random = Random.secure();
    final id = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    await _storage.write(key: _deviceIdKey, value: id);
    return id;
  }

  @override
  String get platform => Platform.isIOS ? 'ios' : 'android';
}
