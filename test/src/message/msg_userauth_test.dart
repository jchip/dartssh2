import 'package:dartssh2/src/message/msg_userauth.dart';
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
