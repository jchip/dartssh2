import 'dart:typed_data';

import 'package:dartssh2/src/sftp/sftp_packet.dart';
import 'package:dartssh2/src/ssh_message.dart';
import 'package:test/test.dart';

void main() {
  group('DS2-25: SftpInitPacket.decode extensions parsing', () {
    test('decode parses extensions when present', () {
      // Build a packet: type(1) + version(4) + ext_name + ext_value
      final writer = SSHMessageWriter();
      writer.writeUint8(SftpInitPacket.packetType); // type = 1
      writer.writeUint32(3); // version = 3
      writer.writeUtf8('posix-rename@openssh.com');
      writer.writeUtf8('1');
      writer.writeUtf8('statvfs@openssh.com');
      writer.writeUtf8('2');
      final data = writer.takeBytes();

      final packet = SftpInitPacket.decode(data);
      expect(packet.version, equals(3));
      expect(packet.extensions, hasLength(2));
      expect(packet.extensions['posix-rename@openssh.com'], equals('1'));
      expect(packet.extensions['statvfs@openssh.com'], equals('2'));
    });

    test('decode returns empty extensions when none present', () {
      final writer = SSHMessageWriter();
      writer.writeUint8(SftpInitPacket.packetType);
      writer.writeUint32(3);
      final data = writer.takeBytes();

      final packet = SftpInitPacket.decode(data);
      expect(packet.version, equals(3));
      expect(packet.extensions, isEmpty);
    });

    test('encode then decode round-trips with extensions', () {
      final original = SftpInitPacket(3, {
        'ext1': 'val1',
        'ext2': 'val2',
      });
      final encoded = original.encode();
      final decoded = SftpInitPacket.decode(encoded);

      expect(decoded.version, equals(original.version));
      expect(decoded.extensions, equals(original.extensions));
    });

    test('encode then decode round-trips without extensions', () {
      final original = SftpInitPacket(3);
      final encoded = original.encode();
      final decoded = SftpInitPacket.decode(encoded);

      expect(decoded.version, equals(original.version));
      expect(decoded.extensions, isEmpty);
    });
  });

  group('DS2-26: SftpSymlinkPacket OpenSSH argument order', () {
    test('encode writes targetPath before linkPath (OpenSSH order)', () {
      final packet = SftpSymlinkPacket(1, '/path/to/link', '/path/to/target');
      final encoded = packet.encode();

      // Decode the raw bytes to verify wire order
      final reader = SSHMessageReader(encoded);
      reader.readUint8(); // packet type
      reader.readUint32(); // request id
      final firstString = reader.readUtf8();
      final secondString = reader.readUtf8();

      // OpenSSH convention: targetPath comes first on the wire
      expect(firstString, equals('/path/to/target'));
      expect(secondString, equals('/path/to/link'));
    });

    test('decode reads targetPath first then linkPath (OpenSSH order)', () {
      // Build a packet with OpenSSH wire order: targetPath first, linkPath second
      final writer = SSHMessageWriter();
      writer.writeUint8(SftpSymlinkPacket.packetType);
      writer.writeUint32(42); // request id
      writer.writeUtf8('/path/to/target'); // targetPath first (OpenSSH order)
      writer.writeUtf8('/path/to/link'); // linkPath second
      final data = writer.takeBytes();

      final packet = SftpSymlinkPacket.decode(data);
      expect(packet.requestId, equals(42));
      expect(packet.linkPath, equals('/path/to/link'));
      expect(packet.targetPath, equals('/path/to/target'));
    });

    test('encode then decode round-trips correctly', () {
      final original = SftpSymlinkPacket(7, '/my/link', '/my/target');
      final encoded = original.encode();
      final decoded = SftpSymlinkPacket.decode(encoded);

      expect(decoded.requestId, equals(original.requestId));
      expect(decoded.linkPath, equals(original.linkPath));
      expect(decoded.targetPath, equals(original.targetPath));
    });

    test('link and target paths are not swapped after round-trip', () {
      const linkPath = '/home/user/shortcut';
      const targetPath = '/var/data/actual-file';

      final original = SftpSymlinkPacket(99, linkPath, targetPath);
      final decoded = SftpSymlinkPacket.decode(original.encode());

      expect(decoded.linkPath, equals(linkPath));
      expect(decoded.targetPath, equals(targetPath));
      // Explicitly verify they are not swapped
      expect(decoded.linkPath, isNot(equals(targetPath)));
      expect(decoded.targetPath, isNot(equals(linkPath)));
    });
  });

  group('DS2-28: SftpExtendedReplyPacket encode/decode symmetry', () {
    test('encode uses raw bytes (not length-prefixed)', () {
      final payload = Uint8List.fromList([1, 2, 3, 4, 5]);
      final packet = SftpExtendedReplyPacket(1, payload);
      final encoded = packet.encode();

      // Expected: type(1) + requestId(4) + raw payload(5) = 10 bytes
      // If writeString was used: type(1) + requestId(4) + length(4) + payload(5) = 14 bytes
      expect(encoded.length, equals(10));
    });

    test('encode then decode round-trips correctly', () {
      final payload = Uint8List.fromList([10, 20, 30, 40, 50, 60]);
      final original = SftpExtendedReplyPacket(42, payload);
      final encoded = original.encode();
      final decoded = SftpExtendedReplyPacket.decode(encoded);

      expect(decoded.requestId, equals(original.requestId));
      expect(decoded.payload, equals(original.payload));
    });

    test('empty payload round-trips correctly', () {
      final payload = Uint8List(0);
      final original = SftpExtendedReplyPacket(1, payload);
      final encoded = original.encode();
      final decoded = SftpExtendedReplyPacket.decode(encoded);

      expect(decoded.requestId, equals(1));
      expect(decoded.payload, isEmpty);
    });

    test('large payload round-trips correctly', () {
      final payload = Uint8List.fromList(List.generate(1024, (i) => i % 256));
      final original = SftpExtendedReplyPacket(99, payload);
      final encoded = original.encode();
      final decoded = SftpExtendedReplyPacket.decode(encoded);

      expect(decoded.requestId, equals(99));
      expect(decoded.payload, equals(payload));
    });

    test('decode output matches encode input byte-for-byte', () {
      final payload = Uint8List.fromList([0xDE, 0xAD, 0xBE, 0xEF]);
      final original = SftpExtendedReplyPacket(7, payload);
      final encoded = original.encode();
      final decoded = SftpExtendedReplyPacket.decode(encoded);
      final reEncoded = decoded.encode();

      // The re-encoded output must be identical to the first encoding
      expect(reEncoded, equals(encoded));
    });
  });

  group('SftpExtendedPacket encode/decode (reference for DS2-28)', () {
    test('SftpExtendedPacket uses writeBytes and round-trips correctly', () {
      // SftpExtendedPacket already uses writeBytes correctly,
      // confirming the pattern that SftpExtendedReplyPacket should follow
      final payload = Uint8List.fromList([1, 2, 3]);
      final original = SftpExtendedPacket(5, payload);
      final encoded = original.encode();
      final decoded = SftpExtendedPacket.decode(encoded);

      expect(decoded.requestId, equals(original.requestId));
      expect(decoded.payload, equals(original.payload));
    });
  });

  group('SftpVersionPacket extensions (reference for DS2-25)', () {
    test('SftpVersionPacket correctly parses extensions', () {
      // SftpVersionPacket already uses !reader.isDone correctly,
      // confirming the pattern that SftpInitPacket should follow
      final writer = SSHMessageWriter();
      writer.writeUint8(SftpVersionPacket.packetType);
      writer.writeUint32(3);
      writer.writeUtf8('ext-a');
      writer.writeUtf8('1');
      final data = writer.takeBytes();

      final packet = SftpVersionPacket.decode(data);
      expect(packet.version, equals(3));
      expect(packet.extensions['ext-a'], equals('1'));
    });
  });
}
