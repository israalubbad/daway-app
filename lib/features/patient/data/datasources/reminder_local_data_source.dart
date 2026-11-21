import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/local_storage/secure_storage_service.dart';
import '../../domain/entities/medicine_reminder.dart';

/// The patient's medicine reminders. They name medicines, which is health
/// information, so they are kept in the platform's secure storage (the Android
/// Keystore / iOS Keychain) rather than in plain preferences.
class ReminderLocalDataSource {
  static const _key = 'medicine_reminders';

  final SecureStorageService _secureStorage;

  const ReminderLocalDataSource(this._secureStorage);

  Future<List<MedicineReminder>> getReminders() async {
    final stored = await _secureStorage.read(key: _key);
    if (stored != null) return _decode((jsonDecode(stored) as List).cast<Object?>());
    return _moveFromPreferences();
  }

  Future<void> saveReminders(List<MedicineReminder> reminders) async {
    await _secureStorage.write(
      key: _key,
      value: jsonEncode([for (final reminder in reminders) reminder.toJson()]),
    );
    await _forgetPreferencesCopy();
  }

  List<MedicineReminder> _decode(List<Object?> raw) => [
    for (final item in raw)
      MedicineReminder.fromJson((item is String ? jsonDecode(item) : item) as Map<String, dynamic>),
  ];

  /// Reminders saved by an earlier version sit in plain preferences: they are
  /// read once, put in secure storage, and the plain copy is removed.
  Future<List<MedicineReminder>> _moveFromPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    final legacy = preferences.getStringList(_key);
    if (legacy == null) return [];
    final reminders = _decode(legacy);
    await saveReminders(reminders);
    return reminders;
  }

  Future<void> _forgetPreferencesCopy() async {
    final preferences = await SharedPreferences.getInstance();
    if (preferences.containsKey(_key)) await preferences.remove(_key);
  }
}
