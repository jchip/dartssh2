import 'dart:typed_data';

import 'package:dartssh2/src/utils/int.dart';
import 'package:test/test.dart';

void main() {
  group('IntX', () {
    group('toUint32', () {
      test('big-endian encoding of 0', () {
        expect(
          0.toUint32(),
          equals(Uint8List.fromList([0, 0, 0, 0])),
        );
      });

      test('big-endian encoding of 1', () {
        expect(
          1.toUint32(),
          equals(Uint8List.fromList([0, 0, 0, 1])),
        );
      });

      test('big-endian encoding of 0x01020304', () {
        expect(
          0x01020304.toUint32(),
          equals(Uint8List.fromList([1, 2, 3, 4])),
        );
      });

      test('big-endian encoding of max uint32 (0xFFFFFFFF)', () {
        expect(
          0xFFFFFFFF.toUint32(),
          equals(Uint8List.fromList([255, 255, 255, 255])),
        );
      });

      test('little-endian encoding of 0x01020304', () {
        expect(
          0x01020304.toUint32(Endian.little),
          equals(Uint8List.fromList([4, 3, 2, 1])),
        );
      });

      test('little-endian encoding of 1', () {
        expect(
          1.toUint32(Endian.little),
          equals(Uint8List.fromList([1, 0, 0, 0])),
        );
      });

      test('returns Uint8List of length 4', () {
        expect(256.toUint32().length, equals(4));
      });
    });

    group('toUint64', () {
      test('big-endian encoding of 0', () {
        expect(
          0.toUint64(),
          equals(Uint8List.fromList([0, 0, 0, 0, 0, 0, 0, 0])),
        );
      });

      test('big-endian encoding of 1', () {
        expect(
          1.toUint64(),
          equals(Uint8List.fromList([0, 0, 0, 0, 0, 0, 0, 1])),
        );
      });

      test('big-endian encoding of 0x0102030405060708', () {
        expect(
          0x0102030405060708.toUint64(),
          equals(Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8])),
        );
      });

      test('little-endian encoding of 0x0102030405060708', () {
        expect(
          0x0102030405060708.toUint64(Endian.little),
          equals(Uint8List.fromList([8, 7, 6, 5, 4, 3, 2, 1])),
        );
      });

      test('returns Uint8List of length 8', () {
        expect(256.toUint64().length, equals(8));
      });
    });

    group('toOctal', () {
      test('0 in octal is "0"', () {
        expect(0.toOctal(), equals('0'));
      });

      test('7 in octal is "7"', () {
        expect(7.toOctal(), equals('7'));
      });

      test('8 in octal is "10"', () {
        expect(8.toOctal(), equals('10'));
      });

      test('255 in octal is "377"', () {
        expect(255.toOctal(), equals('377'));
      });

      test('438 (0o666) in octal is "666"', () {
        expect(438.toOctal(), equals('666'));
      });

      test('493 (0o755) in octal is "755"', () {
        expect(493.toOctal(), equals('755'));
      });
    });

    group('toColonHex', () {
      test('0 produces colon-separated hex padded to 8 digits', () {
        expect(0.toColonHex(), equals(':00:00:00:00'));
      });

      test('0xFF produces correct colon-separated hex', () {
        expect(0xFF.toColonHex(), equals(':00:00:00:ff'));
      });

      test('0xAABBCCDD produces correct colon-separated hex', () {
        expect(0xAABBCCDD.toColonHex(), equals(':aa:bb:cc:dd'));
      });

      test('0x01020304 produces correct colon-separated hex', () {
        expect(0x01020304.toColonHex(), equals(':01:02:03:04'));
      });

      test('1 produces correct colon-separated hex', () {
        expect(1.toColonHex(), equals(':00:00:00:01'));
      });
    });
  });
}
