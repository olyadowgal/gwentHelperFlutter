import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/arch/json_extensions.dart';

void main() {
  group('parseObject', () {
    test('parses present key', () {
      final map = <String, dynamic>{
        'user': <String, dynamic>{'name': 'Bob'},
      };
      final name = map.parseObject('user', (m) => m['name'] as String);
      expect(name, 'Bob');
    });

    test('returns null for absent key', () {
      final map = <String, dynamic>{};
      expect(map.parseObject('user', (m) => m), isNull);
    });
  });

  group('parseEnum', () {
    test('parses present string value', () {
      final map = <String, dynamic>{'kind': 'two'};
      final value = map.parseEnum('kind', (v) => v == 'two' ? 2 : null);
      expect(value, 2);
    });

    test('returns null for absent key', () {
      final map = <String, dynamic>{};
      expect(map.parseEnum('kind', (v) => v), isNull);
    });
  });

  group('parseObjectsList', () {
    test('parses list and skips entries where parser returns null', () {
      final map = <String, dynamic>{
        'items': [
          <String, dynamic>{'v': 1},
          <String, dynamic>{'v': null},
          <String, dynamic>{'v': 3},
        ],
      };
      final list = map.parseObjectsList('items', (m) => m['v'] as int?);
      expect(list, [1, 3]);
    });

    test('returns null for absent key', () {
      final map = <String, dynamic>{};
      expect(map.parseObjectsList('items', (m) => m), isNull);
    });
  });

  group('parseStringsList', () {
    test('parses list of strings', () {
      final map = <String, dynamic>{
        'tags': ['a', 'b'],
      };
      expect(map.parseStringsList('tags'), ['a', 'b']);
    });

    test('returns null for absent key', () {
      expect(<String, dynamic>{}.parseStringsList('tags'), isNull);
    });
  });

  group('parseBoolInt', () {
    test('passes through booleans', () {
      expect(<String, dynamic>{'f': true}.parseBoolInt('f'), isTrue);
      expect(<String, dynamic>{'f': false}.parseBoolInt('f'), isFalse);
    });

    test('parses 1 as true and 0 as false', () {
      expect(<String, dynamic>{'f': 1}.parseBoolInt('f'), isTrue);
      expect(<String, dynamic>{'f': 0}.parseBoolInt('f'), isFalse);
    });

    test('returns false for absent key', () {
      expect(<String, dynamic>{}.parseBoolInt('f'), isFalse);
    });
  });

  group('parseNum', () {
    test('passes through num', () {
      expect(<String, dynamic>{'n': 5}.parseNum('n'), 5);
      expect(<String, dynamic>{'n': 4.5}.parseNum('n'), 4.5);
    });

    test('parses numeric string', () {
      expect(<String, dynamic>{'n': '4.5'}.parseNum('n'), 4.5);
    });

    test('returns null for absent key', () {
      expect(<String, dynamic>{}.parseNum('n'), isNull);
    });
  });

  group('getFirstKeyExists', () {
    test('returns first present key', () {
      final map = <String, dynamic>{'b': 1, 'c': 2};
      expect(map.getFirstKeyExists(['a', 'b', 'c']), 'b');
    });

    test('throws when no key is present', () {
      expect(
        () => <String, dynamic>{}.getFirstKeyExists(['a', 'b']),
        throwsException,
      );
    });
  });
}
