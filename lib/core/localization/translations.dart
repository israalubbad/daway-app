import 'en_strings.dart';

/// The language the app is showing right now. Plain Dart (no Flutter import),
/// so a cubit or a use case can word a message the same way a widget does.
///
/// The app's texts are written in Arabic in the code; [TranslateText.tr] looks
/// a text up in the English table when English is on, and falls back to the
/// Arabic itself when a text has no translation yet, so a missing entry shows
/// Arabic instead of a blank or a key.
abstract final class Translations {
  static const arabicCode = 'ar';
  static const englishCode = 'en';

  static String _code = arabicCode;

  static String get code => _code;

  static bool get isEnglish => _code == englishCode;

  /// Switches the language; anything but English is Arabic.
  static void use(String code) => _code = code == englishCode ? englishCode : arabicCode;
}

extension TranslateText on String {
  /// This text in the current language.
  String get tr => Translations.isEnglish ? (enStrings[this] ?? this) : this;

  /// A text with `{0}`, `{1}`... holes, in the current language, the holes
  /// filled with [args]. Used where the sentence has a value in the middle
  /// (`'عدد {0} دواء'.trArgs([n])`): the translation is of the whole sentence,
  /// so the words can move around the value.
  String trArgs(List<Object?> args) {
    var text = tr;
    for (var i = 0; i < args.length; i++) {
      text = text.replaceAll('{$i}', '${args[i]}');
    }
    return text;
  }
}
