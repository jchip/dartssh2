import 'dart:typed_data';

import 'package:dartssh2/src/utils/chunk_buffer.dart';
import 'package:test/test.dart';

void main() {
  group('ChunkBuffer', () {
    late ChunkBuffer buffer;

    setUp(() {
      buffer = ChunkBuffer();
    });

    test('starts empty', () {
      expect(buffer.isEmpty, isTrue);
      expect(buffer.isNotEmpty, isFalse);
      expect(buffer.length, equals(0));
    });

    test('add single chunk', () {
      buffer.add(Uint8List.fromList([1, 2, 3]));
      expect(buffer.length, equals(3));
      expect(buffer.isNotEmpty, isTrue);
      expect(buffer.isEmpty, isFalse);
      expect(buffer.data, equals(Uint8List.fromList([1, 2, 3])));
    });

    test('add multiple chunks merges them', () {
      buffer.add(Uint8List.fromList([1, 2, 3]));
      buffer.add(Uint8List.fromList([4, 5, 6]));
      expect(buffer.length, equals(6));
      expect(buffer.data, equals(Uint8List.fromList([1, 2, 3, 4, 5, 6])));
    });

    test('add three chunks in sequence', () {
      buffer.add(Uint8List.fromList([10]));
      buffer.add(Uint8List.fromList([20, 30]));
      buffer.add(Uint8List.fromList([40, 50, 60]));
      expect(buffer.length, equals(6));
      expect(
        buffer.data,
        equals(Uint8List.fromList([10, 20, 30, 40, 50, 60])),
      );
    });

    test('consume all without argument', () {
      buffer.add(Uint8List.fromList([1, 2, 3, 4, 5]));
      final consumed = buffer.consume();
      expect(consumed, equals(Uint8List.fromList([1, 2, 3, 4, 5])));
      expect(buffer.isEmpty, isTrue);
      expect(buffer.length, equals(0));
    });

    test('consume partial with length', () {
      buffer.add(Uint8List.fromList([1, 2, 3, 4, 5]));
      final consumed = buffer.consume(3);
      expect(consumed, equals(Uint8List.fromList([1, 2, 3])));
      expect(buffer.length, equals(2));
      expect(buffer.data, equals(Uint8List.fromList([4, 5])));
    });

    test('consume partial then consume remaining', () {
      buffer.add(Uint8List.fromList([10, 20, 30, 40]));

      final first = buffer.consume(2);
      expect(first, equals(Uint8List.fromList([10, 20])));
      expect(buffer.length, equals(2));

      final second = buffer.consume();
      expect(second, equals(Uint8List.fromList([30, 40])));
      expect(buffer.isEmpty, isTrue);
    });

    test('clear resets buffer', () {
      buffer.add(Uint8List.fromList([1, 2, 3]));
      expect(buffer.isNotEmpty, isTrue);
      buffer.clear();
      expect(buffer.isEmpty, isTrue);
      expect(buffer.length, equals(0));
    });

    test('view returns sublist without consuming', () {
      buffer.add(Uint8List.fromList([10, 20, 30, 40, 50]));
      final viewed = buffer.view(1, 3);
      expect(viewed, equals(Uint8List.fromList([20, 30, 40])));
      // buffer should remain unchanged
      expect(buffer.length, equals(5));
      expect(buffer.data, equals(Uint8List.fromList([10, 20, 30, 40, 50])));
    });

    test('view from start', () {
      buffer.add(Uint8List.fromList([1, 2, 3, 4]));
      final viewed = buffer.view(0, 2);
      expect(viewed, equals(Uint8List.fromList([1, 2])));
    });

    test('isEmpty and isNotEmpty reflect buffer state', () {
      expect(buffer.isEmpty, isTrue);
      expect(buffer.isNotEmpty, isFalse);

      buffer.add(Uint8List.fromList([1]));
      expect(buffer.isEmpty, isFalse);
      expect(buffer.isNotEmpty, isTrue);

      buffer.consume();
      expect(buffer.isEmpty, isTrue);
      expect(buffer.isNotEmpty, isFalse);
    });

    test('data getter returns current buffer contents', () {
      expect(buffer.data, equals(Uint8List(0)));
      buffer.add(Uint8List.fromList([7, 8, 9]));
      expect(buffer.data, equals(Uint8List.fromList([7, 8, 9])));
    });

    test('add after consume works correctly', () {
      buffer.add(Uint8List.fromList([1, 2, 3]));
      buffer.consume();
      buffer.add(Uint8List.fromList([4, 5, 6]));
      expect(buffer.length, equals(3));
      expect(buffer.data, equals(Uint8List.fromList([4, 5, 6])));
    });

    test('add after clear works correctly', () {
      buffer.add(Uint8List.fromList([1, 2, 3]));
      buffer.clear();
      buffer.add(Uint8List.fromList([7, 8]));
      expect(buffer.length, equals(2));
      expect(buffer.data, equals(Uint8List.fromList([7, 8])));
    });
  });
}
