import 'package:flutter_test/flutter_test.dart';
import 'package:gwent_helper_flutter/arch/list_extensions.dart';

void main() {
  group('`operator -`', () {
    test('removes matching elements and returns a new list', () {
      final original = [1, 2, 3, 2];
      final result = original - [2];
      expect(result, [1, 3]);
      expect(original, [1, 2, 3, 2]);
    });

    test('removing nothing returns equal list', () {
      expect([1, 2] - <int>[], [1, 2]);
    });
  });

  group('`sorted`', () {
    test('returns sorted copy without mutating original', () {
      final original = [3, 1, 2];
      final result = original.sorted;
      expect(result, [1, 2, 3]);
      expect(original, [3, 1, 2]);
    });
  });
}
