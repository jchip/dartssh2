import 'dart:typed_data';

import 'package:dartssh2/src/utils/list.dart';
import 'package:test/test.dart';

void main() {
  group('randomBytes', () {
    test('returns Uint8List of requested length', () {
      expect(randomBytes(0).length, equals(0));
      expect(randomBytes(1).length, equals(1));
      expect(randomBytes(16).length, equals(16));
      expect(randomBytes(256).length, equals(256));
    });

    test('returns Uint8List type', () {
      expect(randomBytes(10), isA<Uint8List>());
    });

    test('different calls produce different values', () {
      // Generate large enough buffers so the chance of collision is negligible
      final a = randomBytes(32);
      final b = randomBytes(32);
      // The probability that two 32-byte random sequences are identical
      // is astronomically small (2^-256).
      expect(a.equals(b), isFalse);
    });

    test('bytes are in valid range 0-255', () {
      final bytes = randomBytes(1000);
      for (final byte in bytes) {
        expect(byte, greaterThanOrEqualTo(0));
        expect(byte, lessThanOrEqualTo(255));
      }
    });
  });

  group('ListX.equals', () {
    test('equal lists return true', () {
      expect([1, 2, 3].equals([1, 2, 3]), isTrue);
    });

    test('empty lists are equal', () {
      expect(<int>[].equals(<int>[]), isTrue);
    });

    test('single element equal lists return true', () {
      expect([42].equals([42]), isTrue);
    });

    test('different contents return false', () {
      expect([1, 2, 3].equals([1, 2, 4]), isFalse);
    });

    test('different lengths return false (first shorter)', () {
      expect([1, 2].equals([1, 2, 3]), isFalse);
    });

    test('different lengths return false (first longer)', () {
      expect([1, 2, 3].equals([1, 2]), isFalse);
    });

    test('same length but all different', () {
      expect([1, 2, 3].equals([4, 5, 6]), isFalse);
    });

    test('works with strings', () {
      expect(['a', 'b', 'c'].equals(['a', 'b', 'c']), isTrue);
      expect(['a', 'b', 'c'].equals(['a', 'b', 'd']), isFalse);
    });

    test('works with Uint8List', () {
      final a = Uint8List.fromList([10, 20, 30]);
      final b = Uint8List.fromList([10, 20, 30]);
      final c = Uint8List.fromList([10, 20, 31]);
      expect(a.equals(b), isTrue);
      expect(a.equals(c), isFalse);
    });

    test('first element differs', () {
      expect([9, 2, 3].equals([1, 2, 3]), isFalse);
    });

    test('last element differs', () {
      expect([1, 2, 3].equals([1, 2, 9]), isFalse);
    });
  });
}
