import 'dart:typed_data';

import 'package:dartssh2/src/ssh_message.dart';
import 'package:test/test.dart';

void main() {
  group('SSHMessageReader', () {
    test('readBytes works correctly with non-zero offset view', () {
      // Create a larger buffer and make a view starting at offset 10
      final fullBuffer = Uint8List(20);
      for (var i = 0; i < 20; i++) {
        fullBuffer[i] = i;
      }

      // Create a view starting at offset 10 with length 10
      final view = Uint8List.sublistView(fullBuffer, 10, 20);
      // view should contain [10, 11, 12, 13, 14, 15, 16, 17, 18, 19]

      final reader = SSHMessageReader(view);
      final bytes = reader.readBytes(5);

      // Should read [10, 11, 12, 13, 14], not [0, 1, 2, 3, 4]
      expect(bytes, equals(Uint8List.fromList([10, 11, 12, 13, 14])));
    });

    test('readBytes works with zero-offset data', () {
      final data = Uint8List.fromList([42, 43, 44, 45]);
      final reader = SSHMessageReader(data);
      final bytes = reader.readBytes(4);
      expect(bytes, equals(data));
    });

    test('readBytes advances offset correctly', () {
      final data = Uint8List.fromList([1, 2, 3, 4, 5, 6]);
      final reader = SSHMessageReader(data);

      final first = reader.readBytes(3);
      expect(first, equals(Uint8List.fromList([1, 2, 3])));

      final second = reader.readBytes(3);
      expect(second, equals(Uint8List.fromList([4, 5, 6])));

      expect(reader.isDone, isTrue);
    });

    test('readUint8 works correctly', () {
      final data = Uint8List.fromList([0xFF, 0x00, 0x42]);
      final reader = SSHMessageReader(data);
      expect(reader.readUint8(), 0xFF);
      expect(reader.readUint8(), 0x00);
      expect(reader.readUint8(), 0x42);
    });

    test('readUint32 reads big-endian', () {
      final data = Uint8List.fromList([0x00, 0x00, 0x00, 0x0A]);
      final reader = SSHMessageReader(data);
      expect(reader.readUint32(), 10);
    });

    test('readBool works correctly', () {
      final data = Uint8List.fromList([0, 1]);
      final reader = SSHMessageReader(data);
      expect(reader.readBool(), false);
      expect(reader.readBool(), true);
    });

    test('readNameList returns empty list for empty name-list', () {
      // An empty name-list is a zero-length string: uint32(0)
      final writer = SSHMessageWriter();
      writer.writeNameList([]);
      final bytes = writer.takeBytes();

      final reader = SSHMessageReader(bytes);
      final list = reader.readNameList();
      expect(list, isEmpty);
      expect(list, equals([]));
    });

    test('readNameList returns single item for one name', () {
      final writer = SSHMessageWriter();
      writer.writeNameList(['ssh-rsa']);
      final bytes = writer.takeBytes();

      final reader = SSHMessageReader(bytes);
      final list = reader.readNameList();
      expect(list, equals(['ssh-rsa']));
    });

    test('readNameList returns multiple items for comma-separated names', () {
      final writer = SSHMessageWriter();
      writer.writeNameList(['ssh-rsa', 'ssh-ed25519', 'ecdsa-sha2-nistp256']);
      final bytes = writer.takeBytes();

      final reader = SSHMessageReader(bytes);
      final list = reader.readNameList();
      expect(list, equals(['ssh-rsa', 'ssh-ed25519', 'ecdsa-sha2-nistp256']));
    });

    test('readMpint returns zero for empty mpint', () {
      // mpint with zero length data
      final writer = SSHMessageWriter();
      writer.writeMpint(BigInt.zero);
      final bytes = writer.takeBytes();

      final reader = SSHMessageReader(bytes);
      final value = reader.readMpint();
      expect(value, equals(BigInt.zero));
    });

    test('readMpint reads positive values correctly', () {
      final writer = SSHMessageWriter();
      writer.writeMpint(BigInt.from(255));
      final bytes = writer.takeBytes();

      final reader = SSHMessageReader(bytes);
      final value = reader.readMpint();
      expect(value, equals(BigInt.from(255)));
    });

    test('readMpint reads negative values correctly (high bit set)', () {
      // RFC 4251 example: value -1 is represented as 0xFF
      // Manually construct an mpint with magnitude [0xFF]
      // which has high bit set, meaning negative in two's complement
      final data = Uint8List.fromList([
        0x00, 0x00, 0x00, 0x01, // length = 1
        0xFF, // magnitude with high bit set => negative
      ]);

      final reader = SSHMessageReader(data);
      final value = reader.readMpint();
      expect(value.isNegative, isTrue);
    });

    test('readMpint reads positive value with leading zero pad', () {
      // A value like 128 (0x80) needs a leading 0x00 to stay positive
      // because 0x80 has high bit set
      final writer = SSHMessageWriter();
      writer.writeMpint(BigInt.from(128));
      final bytes = writer.takeBytes();

      final reader = SSHMessageReader(bytes);
      final value = reader.readMpint();
      expect(value, equals(BigInt.from(128)));
      expect(value.isNegative, isFalse);
    });

    test('readMpint round-trip for large positive value', () {
      final bigValue = BigInt.parse('123456789012345678901234567890');
      final writer = SSHMessageWriter();
      writer.writeMpint(bigValue);
      final bytes = writer.takeBytes();

      final reader = SSHMessageReader(bytes);
      final value = reader.readMpint();
      expect(value, equals(bigValue));
    });
  });

  group('SSHMessageWriter', () {
    test('writeUint8 produces correct byte', () {
      final writer = SSHMessageWriter();
      writer.writeUint8(42);
      final bytes = writer.takeBytes();
      expect(bytes, equals(Uint8List.fromList([42])));
    });

    test('writeUint32 produces big-endian bytes', () {
      final writer = SSHMessageWriter();
      writer.writeUint32(256);
      final bytes = writer.takeBytes();
      expect(bytes, equals(Uint8List.fromList([0, 0, 1, 0])));
    });

    test('writeString writes length-prefixed data', () {
      final writer = SSHMessageWriter();
      writer.writeString(Uint8List.fromList([1, 2, 3]));
      final bytes = writer.takeBytes();
      // 4 bytes length (0x00000003) + 3 bytes data
      expect(bytes, equals(Uint8List.fromList([0, 0, 0, 3, 1, 2, 3])));
    });
  });
}
