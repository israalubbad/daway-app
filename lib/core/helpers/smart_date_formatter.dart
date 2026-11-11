import 'arabic_plural.dart';

import '../../core/localization/translations.dart';

List<String> get _arabicMonths => [
  'يناير'.tr,
  'فبراير'.tr,
  'مارس'.tr,
  'أبريل'.tr,
  'مايو'.tr,
  'يونيو'.tr,
  'يوليو'.tr,
  'أغسطس'.tr,
  'سبتمبر'.tr,
  'أكتوبر'.tr,
  'نوفمبر'.tr,
  'ديسمبر'.tr,
];

/// "اليوم، 9:40 ص" / "أمس، 4:20 م" / "3 مايو 2025، 11:15 ص" — shared by every
/// card that shows a record's timestamp (patient inquiries, ratings, ...) so
/// they all read the same way. Compares calendar-date components directly
/// (year/month/day), not a Duration subtracted between two DateTimes, so a
/// DST transition day (a real 23h or 25h gap between two local midnights)
/// can't misclassify "today" as "yesterday" or vice versa.
///
/// [now] is the clock to compare against (the current time by default); it
/// exists so a test can pin it.
String smartDate(DateTime dateTime, {DateTime? now}) {
  now ??= DateTime.now();
  final time = formatClockTime(dateTime);

  if (_isSameDate(dateTime, now)) return 'اليوم، {0}'.trArgs([time]);
  final yesterday = DateTime(now.year, now.month, now.day - 1);
  if (_isSameDate(dateTime, yesterday)) return 'أمس، {0}'.trArgs([time]);
  return '{0} {1} {2}، {3}'.trArgs([dateTime.day, _arabicMonths[dateTime.month - 1], dateTime.year, time]);
}

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// "الآن" / "منذ 5 دقائق" / "منذ ساعة" / "أمس" / falls back to [smartDate]
/// for anything older — used where a feed reads more naturally as relative
/// time (notifications) than the "اليوم، H:MM" style [smartDate] renders for
/// cards where the exact time of day matters (inquiries, ratings).
String relativeTimeAr(DateTime dateTime, {DateTime? now}) {
  return _relativeTime(
    dateTime,
    now: now,
    minutesAgo: (minutes) =>
        'منذ {0}'.trArgs([arabicCountedNoun(minutes, singular: 'دقيقة', dual: 'دقيقتين', plural: 'دقائق')]),
    hoursAgo: (hours) =>
        'منذ {0}'.trArgs([arabicCountedNoun(hours, singular: 'ساعة', dual: 'ساعتين', plural: 'ساعات')]),
  );
}

/// [relativeTimeAr] with the minutes and hours abbreviated ("منذ 5 د" /
/// "منذ 3 س") — for the tight spot on a card where the full words don't fit
/// (the pharmacy's order cards). Everything older than an hour reads the same
/// as in [relativeTimeAr].
String compactRelativeTimeAr(DateTime dateTime, {DateTime? now}) {
  return _relativeTime(
    dateTime,
    now: now,
    minutesAgo: (minutes) => 'منذ {0} د'.trArgs([minutes]),
    hoursAgo: (hours) => 'منذ {0} س'.trArgs([hours]),
  );
}

String _relativeTime(
  DateTime dateTime, {
  required DateTime? now,
  required String Function(int minutes) minutesAgo,
  required String Function(int hours) hoursAgo,
}) {
  now ??= DateTime.now();
  if (_isSameDate(dateTime, now)) {
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) return 'الآن'.tr;
    if (diff.inMinutes < 60) return minutesAgo(diff.inMinutes);
    return hoursAgo(diff.inHours);
  }
  final yesterday = DateTime(now.year, now.month, now.day - 1);
  if (_isSameDate(dateTime, yesterday)) return 'أمس'.tr;
  return smartDate(dateTime, now: now);
}

/// The time of day on a 12-hour clock, in Arabic: "9:05 ص", "12:30 م".
String formatClockTime(DateTime dateTime) => formatClockHourMinute(dateTime.hour, dateTime.minute);

/// [formatClockTime] for an hour (0-23) and a minute, where there is no
/// [DateTime] (a reminder's time of day).
String formatClockHourMinute(int hour, int minute) {
  final isAm = hour < 12;
  var hour12 = hour % 12;
  if (hour12 == 0) hour12 = 12;
  return '$hour12:${minute.toString().padLeft(2, '0')} ${isAm ? 'ص' : 'م'}';
}
