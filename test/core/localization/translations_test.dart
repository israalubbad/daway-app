import 'dart:io';

import 'package:daway_app/core/localization/en_strings.dart';
import 'package:daway_app/core/localization/translations.dart';
import 'package:flutter_test/flutter_test.dart';

/// The text a Dart string literal body stands for (escapes interpreted).
String _unescape(String t) {
  final out = StringBuffer();
  for (var i = 0; i < t.length; i++) {
    if (t[i] != r'\' || i + 1 >= t.length) {
      out.write(t[i]);
      continue;
    }
    final n = t[++i];
    switch (n) {
      case 'n':
        out.write('\n');
      case 'u':
        if (t[i + 1] == '{') {
          final close = t.indexOf('}', i);
          out.writeCharCode(int.parse(t.substring(i + 2, close), radix: 16));
          i = close;
        } else {
          out.writeCharCode(int.parse(t.substring(i + 1, i + 5), radix: 16));
          i += 4;
        }
      default:
        out.write(n);
    }
  }
  return out.toString();
}

void main() {
  tearDown(() => Translations.use('ar'));

  group('lookup', () {
    test('Arabic shows the text itself', () {
      Translations.use('ar');

      expect('قريباً'.tr, 'قريباً');
      expect('منذ {0}'.trArgs(['5 د']), 'منذ 5 د');
    });

    test('English shows the translation, and fills the holes', () {
      Translations.use('en');

      expect('قريباً'.tr, 'Coming soon');
      expect('اليوم، {0}'.trArgs(['9:40 AM']), 'Today, 9:40 AM');
    });

    test('a text with no translation falls back to the Arabic', () {
      Translations.use('en');

      expect('نص لا ترجمة له'.tr, 'نص لا ترجمة له');
    });

    test('any code but "en" is Arabic', () {
      Translations.use('fr');

      expect(Translations.isEnglish, isFalse);
    });
  });

  group('the English table', () {
    test('has no blank translation and keeps every {n} hole of its key', () {
      final hole = RegExp(r'\{\d+\}');
      for (final entry in enStrings.entries) {
        expect(entry.value.trim(), isNotEmpty, reason: entry.key);
        final keyHoles = hole.allMatches(entry.key).map((m) => m.group(0)).toSet();
        final valueHoles = hole.allMatches(entry.value).map((m) => m.group(0)).toSet();
        expect(valueHoles, keyHoles, reason: 'holes of "${entry.key}"');
      }
    });

    test('has an entry for every Arabic text wrapped in .tr in lib/', () {
      final literal = RegExp(
        r"""'((?:[^'\\\n]|\\.)*)'\.tr(?:Args)?\b|"((?:[^"\\\n]|\\.)*)"\.tr(?:Args)?\b""",
      );
      final arabic = RegExp(r'[؀-ۿ]');
      final missing = <String>{};
      for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart') || file.path.contains('localization')) continue;
        for (final m in literal.allMatches(file.readAsStringSync())) {
          final key = _unescape(m.group(1) ?? m.group(2)!);
          if (arabic.hasMatch(key) && !enStrings.containsKey(key)) missing.add(key);
        }
      }

      expect(missing, isEmpty, reason: 'Arabic texts with no English:\n${missing.join('\n')}');
    });
  });
}
