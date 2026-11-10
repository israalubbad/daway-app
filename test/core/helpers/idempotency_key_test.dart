import 'package:daway_app/core/helpers/idempotency_key.dart';
import 'package:daway_app/core/helpers/optional_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('newIdempotencyKey', () {
    test('is a prefix and 128 bits of hex', () {
      expect(newIdempotencyKey(), matches(RegExp(r'^dawak-[0-9a-f]{32}$')));
    });

    test('is different every time', () {
      final keys = {for (var i = 0; i < 200; i++) newIdempotencyKey()};

      expect(keys.length, 200);
    });
  });

  group('optionalText', () {
    test('trims the text', () {
      expect(optionalText('  سبب  '), 'سبب');
    });

    test('is null for blank or missing text', () {
      expect(optionalText(null), isNull);
      expect(optionalText(''), isNull);
      expect(optionalText('   '), isNull);
    });
  });
}
