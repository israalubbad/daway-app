import 'dart:convert';

import 'package:daway_app/core/local_storage/secure_storage_service.dart';
import 'package:daway_app/features/patient/data/datasources/reminder_local_data_source.dart';
import 'package:daway_app/features/patient/domain/entities/medicine_reminder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSecureStorage implements SecureStorageService {
  final Map<String, String> values = {};

  @override
  Future<void> write({required String key, required String value}) async => values[key] = value;

  @override
  Future<String?> read({required String key}) async => values[key];

  @override
  Future<void> delete({required String key}) async => values.remove(key);
}

const _panadol = MedicineReminder(
  id: 'r1',
  name: 'بانادول',
  frequency: ReminderFrequency.every12Hours,
  hour: 9,
  minute: 30,
);

void main() {
  late _FakeSecureStorage storage;
  late ReminderLocalDataSource dataSource;

  setUp(() {
    storage = _FakeSecureStorage();
    dataSource = ReminderLocalDataSource(storage);
  });

  test('starts empty', () async {
    SharedPreferences.setMockInitialValues({});

    expect(await dataSource.getReminders(), isEmpty);
  });

  test('saved reminders go to secure storage, not to plain preferences', () async {
    SharedPreferences.setMockInitialValues({});

    await dataSource.saveReminders([_panadol]);

    expect(storage.values['medicine_reminders'], contains('بانادول'));
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.containsKey('medicine_reminders'), isFalse);
    final read = await dataSource.getReminders();
    expect(read.single.name, 'بانادول');
    expect(read.single.frequency, ReminderFrequency.every12Hours);
    expect(read.single.hour, 9);
  });

  test('reminders an earlier version kept in preferences move to secure storage', () async {
    SharedPreferences.setMockInitialValues({
      'medicine_reminders': [jsonEncode(_panadol.toJson())],
    });

    final read = await dataSource.getReminders();

    expect(read.single.name, 'بانادول');
    expect(storage.values['medicine_reminders'], contains('بانادول'));
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.containsKey('medicine_reminders'), isFalse, reason: 'the plain copy is gone');
    // And the next read comes from secure storage alone.
    expect((await dataSource.getReminders()).single.id, 'r1');
  });

  test('an empty list saved is an empty list read back, not a fall back to old data', () async {
    SharedPreferences.setMockInitialValues({});
    await dataSource.saveReminders([_panadol]);

    await dataSource.saveReminders([]);

    expect(await dataSource.getReminders(), isEmpty);
  });
}
