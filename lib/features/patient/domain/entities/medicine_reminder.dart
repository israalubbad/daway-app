import '../../../../core/helpers/smart_date_formatter.dart';

import '../../../../core/localization/translations.dart';

/// How often a reminder repeats — replaces the old weekday-multi-select
/// model (redesigned 2026-09-28: one reminder now fires at fixed times
/// through every day instead of on chosen days of the week).
enum ReminderFrequency {
  daily,
  every12Hours,
  every6Hours;

  int get timesPerDay => switch (this) {
        ReminderFrequency.daily => 1,
        ReminderFrequency.every12Hours => 2,
        ReminderFrequency.every6Hours => 4,
      };

  String get chipLabel => switch (this) {
        ReminderFrequency.daily => 'كل يوم'.tr,
        ReminderFrequency.every12Hours => 'كل 12 ساعة'.tr,
        ReminderFrequency.every6Hours => 'كل 6 ساعة'.tr,
      };
}

class MedicineReminder {
  final String id;
  final String name;
  final ReminderFrequency frequency;

  /// The first reminder of the day — for [ReminderFrequency.every12Hours]/
  /// [ReminderFrequency.every6Hours] the rest of the day's times are spaced
  /// evenly from this one (see [dailyTimes]).
  final int hour;
  final int minute;

  const MedicineReminder({
    required this.id,
    required this.name,
    required this.frequency,
    required this.hour,
    required this.minute,
  });

  String get formattedTime => formatClockHourMinute(hour, minute);

  String get scheduleLabel => frequency.chipLabel;

  String get alertLabel => switch (frequency) {
        ReminderFrequency.daily => 'تنبيه يومياً الساعة {0}'.trArgs([formattedTime]),
        ReminderFrequency.every12Hours ||
        ReminderFrequency.every6Hours =>
          'تنبيه {0} بدءاً من {1}'.trArgs([frequency.chipLabel, formattedTime]),
      };

  /// The clock times this reminder fires at, every day — [hour]/[minute]
  /// plus evenly-spaced repeats (24h / [ReminderFrequency.timesPerDay]),
  /// wrapping past midnight. [NotificationService] schedules one repeating
  /// (daily-at-that-time) notification per entry.
  List<(int hour, int minute)> get dailyTimes {
    final timesPerDay = frequency.timesPerDay;
    final stepMinutes = (24 * 60) ~/ timesPerDay;
    final startMinutes = hour * 60 + minute;
    return List.generate(timesPerDay, (i) {
      final totalMinutes = (startMinutes + i * stepMinutes) % (24 * 60);
      return (totalMinutes ~/ 60, totalMinutes % 60);
    });
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'frequency': frequency.name,
        'hour': hour,
        'minute': minute,
      };

  factory MedicineReminder.fromJson(Map<String, dynamic> json) {
    return MedicineReminder(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      frequency: ReminderFrequency.values.firstWhere(
        (f) => f.name == json['frequency'],
        orElse: () => ReminderFrequency.daily,
      ),
      hour: json['hour'] as int? ?? 8,
      minute: json['minute'] as int? ?? 0,
    );
  }
}
