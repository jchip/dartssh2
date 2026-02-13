import 'package:dartssh2/src/message/msg_kex.dart';
import 'package:test/test.dart';

void main() {
  group('SSH_Message_KexInit', () {
    test('encode/decode round-trip preserves all algorithm lists', () {
      final original = SSH_Message_KexInit(
        kexAlgorithms: ['curve25519-sha256', 'diffie-hellman-group14-sha256'],
        serverHostKeyAlgorithms: ['ssh-ed25519', 'ssh-rsa'],
        encryptionClientToServer: ['aes128-ctr', 'aes256-ctr'],
        encryptionServerToClient: ['aes256-ctr', 'aes128-ctr'],
        macClientToServer: ['hmac-sha2-256', 'hmac-sha1'],
        macServerToClient: ['hmac-sha2-256', 'hmac-sha1'],
        compressionClientToServer: ['none', 'zlib'],
        compressionServerToClient: ['none'],
        languagesClientToServer: ['en'],
        languagesServerToClient: ['fr'],
        firstKexPacketFollows: false,
      );

      final encoded = original.encode();
      final decoded = SSH_Message_KexInit.decode(encoded);

      expect(decoded.kexAlgorithms, original.kexAlgorithms);
      expect(decoded.serverHostKeyAlgorithms, original.serverHostKeyAlgorithms);
      expect(
        decoded.encryptionClientToServer,
        original.encryptionClientToServer,
      );
      expect(
        decoded.encryptionServerToClient,
        original.encryptionServerToClient,
      );
      expect(decoded.macClientToServer, original.macClientToServer);
      expect(decoded.macServerToClient, original.macServerToClient);
      expect(
        decoded.compressionClientToServer,
        original.compressionClientToServer,
      );
      expect(
        decoded.compressionServerToClient,
        original.compressionServerToClient,
      );
      expect(
        decoded.languagesClientToServer,
        original.languagesClientToServer,
      );
      expect(
        decoded.languagesServerToClient,
        original.languagesServerToClient,
      );
      expect(decoded.firstKexPacketFollows, isFalse);
    });

    test('encode/decode preserves firstKexPacketFollows=true', () {
      final original = SSH_Message_KexInit(
        kexAlgorithms: ['curve25519-sha256'],
        serverHostKeyAlgorithms: ['ssh-ed25519'],
        encryptionClientToServer: ['aes128-ctr'],
        encryptionServerToClient: ['aes128-ctr'],
        macClientToServer: ['hmac-sha2-256'],
        macServerToClient: ['hmac-sha2-256'],
        compressionClientToServer: ['none'],
        compressionServerToClient: ['none'],
        firstKexPacketFollows: true,
      );

      final encoded = original.encode();
      final decoded = SSH_Message_KexInit.decode(encoded);

      expect(decoded.firstKexPacketFollows, isTrue);
    });

    test('encode/decode with single-element algorithm lists', () {
      final original = SSH_Message_KexInit(
        kexAlgorithms: ['curve25519-sha256'],
        serverHostKeyAlgorithms: ['ssh-ed25519'],
        encryptionClientToServer: ['aes256-ctr'],
        encryptionServerToClient: ['aes256-ctr'],
        macClientToServer: ['hmac-sha2-256'],
        macServerToClient: ['hmac-sha2-256'],
        compressionClientToServer: ['none'],
        compressionServerToClient: ['none'],
        firstKexPacketFollows: false,
      );

      final encoded = original.encode();
      final decoded = SSH_Message_KexInit.decode(encoded);

      expect(decoded.kexAlgorithms, ['curve25519-sha256']);
      expect(decoded.serverHostKeyAlgorithms, ['ssh-ed25519']);
      expect(decoded.encryptionClientToServer, ['aes256-ctr']);
      expect(decoded.encryptionServerToClient, ['aes256-ctr']);
      expect(decoded.macClientToServer, ['hmac-sha2-256']);
      expect(decoded.macServerToClient, ['hmac-sha2-256']);
      expect(decoded.compressionClientToServer, ['none']);
      expect(decoded.compressionServerToClient, ['none']);
    });

    test('encoded bytes start with correct message id', () {
      final msg = SSH_Message_KexInit(
        kexAlgorithms: ['a'],
        serverHostKeyAlgorithms: ['b'],
        encryptionClientToServer: ['c'],
        encryptionServerToClient: ['d'],
        macClientToServer: ['e'],
        macServerToClient: ['f'],
        compressionClientToServer: ['g'],
        compressionServerToClient: ['h'],
        firstKexPacketFollows: false,
      );
      final encoded = msg.encode();
      expect(encoded[0], SSH_Message_KexInit.messageId);
      expect(encoded[0], 20);
    });

    test('default language lists are empty', () {
      final original = SSH_Message_KexInit(
        kexAlgorithms: ['curve25519-sha256'],
        serverHostKeyAlgorithms: ['ssh-ed25519'],
        encryptionClientToServer: ['aes128-ctr'],
        encryptionServerToClient: ['aes128-ctr'],
        macClientToServer: ['hmac-sha2-256'],
        macServerToClient: ['hmac-sha2-256'],
        compressionClientToServer: ['none'],
        compressionServerToClient: ['none'],
        firstKexPacketFollows: false,
      );

      expect(original.languagesClientToServer, isEmpty);
      expect(original.languagesServerToClient, isEmpty);
    });

    test('encode produces different bytes on each call due to random cookie',
        () {
      final msg = SSH_Message_KexInit(
        kexAlgorithms: ['curve25519-sha256'],
        serverHostKeyAlgorithms: ['ssh-ed25519'],
        encryptionClientToServer: ['aes128-ctr'],
        encryptionServerToClient: ['aes128-ctr'],
        macClientToServer: ['hmac-sha2-256'],
        macServerToClient: ['hmac-sha2-256'],
        compressionClientToServer: ['none'],
        compressionServerToClient: ['none'],
        firstKexPacketFollows: false,
      );

      final encoded1 = msg.encode();
      final encoded2 = msg.encode();

      // The cookie (bytes 1..16) should differ between encodes
      // (extremely unlikely to collide with 16 random bytes)
      final cookie1 = encoded1.sublist(1, 17);
      final cookie2 = encoded2.sublist(1, 17);

      // The algorithm data after the cookie should be identical
      final payload1 = encoded1.sublist(17);
      final payload2 = encoded2.sublist(17);
      expect(payload1, equals(payload2));

      // Cookies should almost certainly differ
      // (we accept the astronomically unlikely false failure)
      expect(cookie1, isNot(equals(cookie2)));
    });
  });

  group('SSH_Message_NewKeys', () {
    test('encode produces correct message id', () {
      final msg = SSH_Message_NewKeys();
      final encoded = msg.encode();
      expect(encoded[0], SSH_Message_NewKeys.messageId);
      expect(encoded[0], 21);
    });

    test('encode produces exactly 1 byte', () {
      final msg = SSH_Message_NewKeys();
      final encoded = msg.encode();
      expect(encoded.length, 1);
    });
  });
}
