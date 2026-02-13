import 'dart:typed_data';

import 'package:dartssh2/src/message/msg_kex_ecdh.dart';
import 'package:test/test.dart';

void main() {
  group('SSH_Message_KexECDH_Reply', () {
    test('encode/decode round-trip preserves field order (RFC 5656)', () {
      final hostKey = Uint8List.fromList([1, 2, 3, 4]);
      final ecdhKey = Uint8List.fromList([5, 6, 7, 8]);
      final sig = Uint8List.fromList([9, 10, 11, 12]);

      final original = SSH_Message_KexECDH_Reply(
        hostPublicKey: hostKey,
        ecdhPublicKey: ecdhKey,
        signature: sig,
      );

      final encoded = original.encode();
      final decoded = SSH_Message_KexECDH_Reply.decode(encoded);

      expect(decoded.hostPublicKey, equals(hostKey));
      expect(decoded.ecdhPublicKey, equals(ecdhKey));
      expect(decoded.signature, equals(sig));
    });

    test('encode writes K_S (host key) before Q_S (ECDH key)', () {
      final hostKey = Uint8List.fromList([0xAA]);
      final ecdhKey = Uint8List.fromList([0xBB]);
      final sig = Uint8List.fromList([0xCC]);

      final msg = SSH_Message_KexECDH_Reply(
        hostPublicKey: hostKey,
        ecdhPublicKey: ecdhKey,
        signature: sig,
      );

      final encoded = msg.encode();
      // Skip message ID byte (1), then read first string (4-byte length + data)
      // First string should be hostPublicKey (0xAA), not ecdhPublicKey (0xBB)
      final firstStringData = encoded[5]; // offset 1 (msgId) + 4 (length)
      expect(firstStringData, 0xAA, reason: 'First field should be host key');
    });
  });

  group('SSH_Message_KexECDH_Init', () {
    test('encode/decode round-trip', () {
      final pubKey = Uint8List.fromList([1, 2, 3, 4, 5]);
      final original = SSH_Message_KexECDH_Init(pubKey);
      final encoded = original.encode();
      final decoded = SSH_Message_KexECDH_Init.decode(encoded);
      expect(decoded.ecdhPublicKey, equals(pubKey));
    });
  });
}
