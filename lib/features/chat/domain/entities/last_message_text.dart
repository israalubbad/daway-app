import '../../../../core/localization/translations.dart';

/// The text an inquiry's `last_message` stands for. The backend sends either
/// the text itself or the message object: its text, or — for a picture — a
/// "صورة" stand-in. Null when there is no last message.
String? lastMessageText(Object? value) {
  if (value is String) return value.isEmpty ? null : value;
  if (value is Map) {
    final text = value['message'];
    if (text is String && text.isNotEmpty) return text;
    if (value['media_url'] != null) return 'صورة'.tr;
  }
  return null;
}
