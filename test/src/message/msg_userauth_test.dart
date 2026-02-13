import 'dart:typed_data';

import 'package:dartssh2/src/message/msg_userauth.dart';
import 'package:dartssh2/src/ssh_message.dart';
import 'package:test/test.dart';

void main() {
  group('SSH_Message_Userauth_Request', () {
    test('password change encode/decode round-trip preserves field order', () {
      final original = SSH_Message_Userauth_Request.newPassword(
        user: 'testuser',
        oldPassword: 'oldpass123',
        newPassword: 'newpass456',
      );

      final encoded = original.encode();
      final decoded = SSH_Message_Userauth_Request.decode(encoded);

      expect(decoded.oldPassword, 'oldpass123');
      expect(decoded.password, 'newpass456');
      expect(decoded.user, 'testuser');
    });

    test('simple password encode/decode round-trip', () {
      final original = SSH_Message_Userauth_Request.password(
        user: 'bob',
        password: 'secret',
      );

      final encoded = original.encode();
      final decoded = SSH_Message_Userauth_Request.decode(encoded);

      expect(decoded.password, 'secret');
      expect(decoded.oldPassword, isNull);
      expect(decoded.user, 'bob');
    });

    test('none auth encode/decode round-trip', () {
      final original = SSH_Message_Userauth_Request.none(user: 'alice');
      final encoded = original.encode();
      final decoded = SSH_Message_Userauth_Request.decode(encoded);
      expect(decoded.user, 'alice');
      expect(decoded.methodName, 'none');
    });

    test('keyboard-interactive encode/decode round-trip', () {
      final original = SSH_Message_Userauth_Request.keyboardInteractive(
        user: 'charlie',
        languageTag: 'en',
        submethods: 'pam',
      );
      final encoded = original.encode();
      final decoded = SSH_Message_Userauth_Request.decode(encoded);
      expect(decoded.user, 'charlie');
      expect(decoded.methodName, 'keyboard-interactive');
      expect(decoded.languageTag, 'en');
      expect(decoded.submethods, 'pam');
    });

    test('publickey with signature encode/decode round-trip', () {
      final publicKey = Uint8List.fromList([1, 2, 3, 4]);
      final signature = Uint8List.fromList([5, 6, 7, 8]);
      final original = SSH_Message_Userauth_Request.publicKey(
        username: 'dave',
        publicKeyAlgorithm: 'ssh-rsa',
        publicKey: publicKey,
        signature: signature,
      );

      final encoded = original.encode();
      final decoded = SSH_Message_Userauth_Request.decode(encoded);

      expect(decoded.user, 'dave');
      expect(decoded.methodName, 'publickey');
      expect(decoded.publicKeyAlgorithm, 'ssh-rsa');
      expect(decoded.publicKey, equals(publicKey));
      expect(decoded.signature, equals(signature));
    });

    test('publickey query (no signature) encode/decode round-trip', () {
      final publicKey = Uint8List.fromList([10, 20, 30]);
      final original = SSH_Message_Userauth_Request.publicKey(
        username: 'eve',
        publicKeyAlgorithm: 'ssh-ed25519',
        publicKey: publicKey,
        signature: null,
      );

      final encoded = original.encode();
      final decoded = SSH_Message_Userauth_Request.decode(encoded);

      expect(decoded.user, 'eve');
      expect(decoded.methodName, 'publickey');
      expect(decoded.publicKeyAlgorithm, 'ssh-ed25519');
      expect(decoded.publicKey, equals(publicKey));
      expect(decoded.signature, isNull);
    });

    test('publickey query message decodes hasSignature=false correctly', () {
      // Manually construct a publickey message with hasSignature=false
      final writer = SSHMessageWriter();
      writer.writeUint8(SSH_Message_Userauth_Request.messageId);
      writer.writeUtf8('testuser');
      writer.writeUtf8('ssh-connection');
      writer.writeUtf8('publickey');
      writer.writeBool(false); // hasSignature = false
      writer.writeUtf8('ssh-rsa');
      writer.writeString(Uint8List.fromList([1, 2, 3]));
      // No signature follows

      final decoded = SSH_Message_Userauth_Request.decode(writer.takeBytes());
      expect(decoded.signature, isNull);
      expect(decoded.publicKeyAlgorithm, 'ssh-rsa');
    });
  });

  group('SSH_Message_Userauth_Failure', () {
    test('encode/decode round-trip', () {
      final original = SSH_Message_Userauth_Failure(
        methodsLeft: ['publickey', 'password'],
        partialSuccess: true,
      );
      final encoded = original.encode();
      final decoded = SSH_Message_Userauth_Failure.decode(encoded);
      expect(decoded.methodsLeft, ['publickey', 'password']);
      expect(decoded.partialSuccess, isTrue);
    });
  });
}
