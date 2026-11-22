import 'package:daway_app/core/helpers/json_parsing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('jsonDouble', () {
    test('reads numbers and Laravel decimal strings', () {
      expect(jsonDouble(18), 18.0);
      expect(jsonDouble(12.5), 12.5);
      expect(jsonDouble('18.00'), 18.0);
      expect(jsonDouble(' 7.25 '), 7.25);
    });

    test('anything else reads as missing', () {
      expect(jsonDouble(null), isNull);
      expect(jsonDouble('abc'), isNull);
      expect(jsonDouble(''), isNull);
      expect(jsonDouble({'a': 1}), isNull);
      expect(jsonDouble(true), isNull);
    });
  });

  group('jsonInt', () {
    test('reads numbers and numeric strings', () {
      expect(jsonInt(3), 3);
      expect(jsonInt(3.9), 3);
      expect(jsonInt('42'), 42);
      expect(jsonInt('3.0'), 3);
    });

    test('anything else reads as missing', () {
      expect(jsonInt(null), isNull);
      expect(jsonInt('x'), isNull);
      expect(jsonInt([1]), isNull);
    });
  });

  group('jsonString and jsonMap', () {
    test('a string is text, a number or boolean reads as its text, anything else is missing', () {
      expect(jsonString(' a '), 'a');
      expect(jsonString(5), '5');
      expect(jsonString(true), 'true');
      expect(jsonString('  '), isNull);
      expect(jsonString([1]), isNull);
      expect(jsonString({'a': 1}), isNull);
      expect(jsonString(null), isNull);
    });

    test('only a map is a map, with string keys', () {
      expect(jsonMap({'a': 1}), {'a': 1});
      expect(jsonMap(<dynamic, dynamic>{'a': 1}), {'a': 1});
      expect(jsonMap([1]), isNull);
      expect(jsonMap('x'), isNull);
    });
  });

  group('jsonBool', () {
    test('reads booleans, 0/1 and their string forms', () {
      expect(jsonBool(true), isTrue);
      expect(jsonBool(false), isFalse);
      expect(jsonBool(1), isTrue);
      expect(jsonBool(0), isFalse);
      expect(jsonBool('1'), isTrue);
      expect(jsonBool('false'), isFalse);
    });

    test('anything else reads as missing', () {
      expect(jsonBool(null), isNull);
      expect(jsonBool('yes'), isNull);
      expect(jsonBool([1]), isNull);
    });
  });
}
