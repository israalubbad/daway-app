import '../../../../core/erroring/error_handler.dart';
import '../../../../core/helpers/api_result.dart';
import '../../domain/entities/medicine_reminder.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../datasources/reminder_local_data_source.dart';

class ReminderRepositoryImpl implements ReminderRepository {
  final ReminderLocalDataSource _localDataSource;

  const ReminderRepositoryImpl(this._localDataSource);

  @override
  Future<ApiResult<List<MedicineReminder>>> getReminders() {
    return guardApi(() async {
      return Success(await _localDataSource.getReminders());
    });
  }

  @override
  Future<ApiResult<void>> saveReminder(MedicineReminder reminder) {
    return guardApi(() async {
      final reminders = await _localDataSource.getReminders();
      final index = reminders.indexWhere((r) => r.id == reminder.id);
      if (index >= 0) {
        reminders[index] = reminder;
      } else {
        reminders.add(reminder);
      }
      await _localDataSource.saveReminders(reminders);
      return const Success(null);
    });
  }

  @override
  Future<ApiResult<void>> deleteReminder(String id) {
    return guardApi(() async {
      final reminders = await _localDataSource.getReminders();
      reminders.removeWhere((r) => r.id == id);
      await _localDataSource.saveReminders(reminders);
      return const Success(null);
    });
  }
}
