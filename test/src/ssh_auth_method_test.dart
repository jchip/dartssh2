import 'dart:collection';
import 'dart:typed_data';

import 'package:dartssh2/src/ssh_userauth.dart';
import 'package:dartssh2/src/message/msg_userauth.dart';
import 'package:test/test.dart';

/// Mirrors the private _parseServerAuthMethods from SSHClient.
/// Used to test the mapping logic independently.
Set<SSHAuthMethod> parseServerAuthMethods(List<String> methodNames) {
  final methods = <SSHAuthMethod>{};
  for (final name in methodNames) {
    switch (name) {
      case 'password':
        methods.add(SSHAuthMethod.password);
        break;
      case 'publickey':
        methods.add(SSHAuthMethod.publicKey);
        break;
      case 'keyboard-interactive':
        methods.add(SSHAuthMethod.keyboardInteractive);
        break;
      case 'none':
        methods.add(SSHAuthMethod.none);
        break;
    }
  }
  return methods;
}

void main() {
  group('parseServerAuthMethods', () {
    test('maps "password" to SSHAuthMethod.password', () {
      final result = parseServerAuthMethods(['password']);
      expect(result, {SSHAuthMethod.password});
    });

    test('maps "publickey" to SSHAuthMethod.publicKey', () {
      final result = parseServerAuthMethods(['publickey']);
      expect(result, {SSHAuthMethod.publicKey});
    });

    test('maps "keyboard-interactive" to SSHAuthMethod.keyboardInteractive',
        () {
      final result = parseServerAuthMethods(['keyboard-interactive']);
      expect(result, {SSHAuthMethod.keyboardInteractive});
    });

    test('maps "none" to SSHAuthMethod.none', () {
      final result = parseServerAuthMethods(['none']);
      expect(result, {SSHAuthMethod.none});
    });

    test('maps all known method names at once', () {
      final result = parseServerAuthMethods([
        'password',
        'publickey',
        'keyboard-interactive',
        'none',
      ]);
      expect(result, {
        SSHAuthMethod.password,
        SSHAuthMethod.publicKey,
        SSHAuthMethod.keyboardInteractive,
        SSHAuthMethod.none,
      });
    });

    test('ignores unknown method names', () {
      final result = parseServerAuthMethods([
        'publickey',
        'gssapi-with-mic',
      ]);
      expect(result, {SSHAuthMethod.publicKey});
    });

    test('ignores all unrecognized method names', () {
      final result = parseServerAuthMethods([
        'gssapi-with-mic',
        'hostbased',
        'custom-auth',
      ]);
      expect(result, isEmpty);
    });

    test('returns empty set for empty input', () {
      final result = parseServerAuthMethods([]);
      expect(result, isEmpty);
    });

    test('handles duplicate method names without duplication', () {
      final result = parseServerAuthMethods([
        'password',
        'password',
        'publickey',
      ]);
      expect(result, {SSHAuthMethod.password, SSHAuthMethod.publicKey});
      expect(result.length, 2);
    });
  });

  group('auth method filtering (retainWhere simulation)', () {
    test('filters queue to only server-supported methods', () {
      final authMethodsLeft = Queue<SSHAuthMethod>.from([
        SSHAuthMethod.none,
        SSHAuthMethod.publicKey,
        SSHAuthMethod.password,
        SSHAuthMethod.keyboardInteractive,
      ]);

      final serverMethods =
          parseServerAuthMethods(['publickey', 'password']);

      authMethodsLeft.retainWhere(
        (method) => serverMethods.contains(method),
      );

      expect(
        authMethodsLeft.toList(),
        [SSHAuthMethod.publicKey, SSHAuthMethod.password],
      );
    });

    test('removes all methods when server sends empty list', () {
      final authMethodsLeft = Queue<SSHAuthMethod>.from([
        SSHAuthMethod.none,
        SSHAuthMethod.publicKey,
        SSHAuthMethod.password,
        SSHAuthMethod.keyboardInteractive,
      ]);

      final serverMethods = parseServerAuthMethods([]);

      authMethodsLeft.retainWhere(
        (method) => serverMethods.contains(method),
      );

      expect(authMethodsLeft, isEmpty);
    });

    test('retains only publicKey when server sends publickey and unknown', () {
      final authMethodsLeft = Queue<SSHAuthMethod>.from([
        SSHAuthMethod.publicKey,
        SSHAuthMethod.password,
        SSHAuthMethod.keyboardInteractive,
      ]);

      final serverMethods =
          parseServerAuthMethods(['publickey', 'gssapi-with-mic']);

      authMethodsLeft.retainWhere(
        (method) => serverMethods.contains(method),
      );

      expect(authMethodsLeft.toList(), [SSHAuthMethod.publicKey]);
    });

    test('preserves order of remaining methods in queue', () {
      final authMethodsLeft = Queue<SSHAuthMethod>.from([
        SSHAuthMethod.keyboardInteractive,
        SSHAuthMethod.password,
        SSHAuthMethod.publicKey,
      ]);

      final serverMethods =
          parseServerAuthMethods(['publickey', 'keyboard-interactive']);

      authMethodsLeft.retainWhere(
        (method) => serverMethods.contains(method),
      );

      expect(authMethodsLeft.toList(), [
        SSHAuthMethod.keyboardInteractive,
        SSHAuthMethod.publicKey,
      ]);
    });

    test('retains all methods when server supports all of them', () {
      final authMethodsLeft = Queue<SSHAuthMethod>.from([
        SSHAuthMethod.publicKey,
        SSHAuthMethod.password,
      ]);

      final serverMethods =
          parseServerAuthMethods(['publickey', 'password', 'none']);

      authMethodsLeft.retainWhere(
        (method) => serverMethods.contains(method),
      );

      expect(authMethodsLeft.toList(), [
        SSHAuthMethod.publicKey,
        SSHAuthMethod.password,
      ]);
    });

    test('handles single method in queue matching server', () {
      final authMethodsLeft = Queue<SSHAuthMethod>.from([
        SSHAuthMethod.password,
      ]);

      final serverMethods = parseServerAuthMethods(['password']);

      authMethodsLeft.retainWhere(
        (method) => serverMethods.contains(method),
      );

      expect(authMethodsLeft.toList(), [SSHAuthMethod.password]);
    });

    test('handles single method in queue not matching server', () {
      final authMethodsLeft = Queue<SSHAuthMethod>.from([
        SSHAuthMethod.password,
      ]);

      final serverMethods = parseServerAuthMethods(['publickey']);

      authMethodsLeft.retainWhere(
        (method) => serverMethods.contains(method),
      );

      expect(authMethodsLeft, isEmpty);
    });

    test('handles empty queue gracefully', () {
      final authMethodsLeft = Queue<SSHAuthMethod>();

      final serverMethods =
          parseServerAuthMethods(['publickey', 'password']);

      authMethodsLeft.retainWhere(
        (method) => serverMethods.contains(method),
      );

      expect(authMethodsLeft, isEmpty);
    });
  });

  group('SSH_Message_Userauth_Failure encode/decode', () {
    test('preserves method list through encode/decode', () {
      final original = SSH_Message_Userauth_Failure(
        methodsLeft: ['publickey', 'password', 'keyboard-interactive'],
        partialSuccess: false,
      );

      final encoded = original.encode();
      final decoded = SSH_Message_Userauth_Failure.decode(encoded);

      expect(
        decoded.methodsLeft,
        ['publickey', 'password', 'keyboard-interactive'],
      );
      expect(decoded.partialSuccess, isFalse);
    });

    test('preserves single method through encode/decode', () {
      final original = SSH_Message_Userauth_Failure(
        methodsLeft: ['publickey'],
        partialSuccess: true,
      );

      final encoded = original.encode();
      final decoded = SSH_Message_Userauth_Failure.decode(encoded);

      expect(decoded.methodsLeft, ['publickey']);
      expect(decoded.partialSuccess, isTrue);
    });

    test('preserves empty method list through encode/decode', () {
      final original = SSH_Message_Userauth_Failure(
        methodsLeft: [],
        partialSuccess: false,
      );

      final encoded = original.encode();
      final decoded = SSH_Message_Userauth_Failure.decode(encoded);

      expect(decoded.methodsLeft, isEmpty);
      expect(decoded.partialSuccess, isFalse);
    });

    test('decoded methods can be parsed and used for filtering', () {
      final original = SSH_Message_Userauth_Failure(
        methodsLeft: ['publickey', 'keyboard-interactive'],
        partialSuccess: false,
      );

      final encoded = original.encode();
      final decoded = SSH_Message_Userauth_Failure.decode(encoded);

      final serverMethods = parseServerAuthMethods(decoded.methodsLeft);

      final authMethodsLeft = Queue<SSHAuthMethod>.from([
        SSHAuthMethod.none,
        SSHAuthMethod.publicKey,
        SSHAuthMethod.password,
        SSHAuthMethod.keyboardInteractive,
      ]);

      authMethodsLeft.retainWhere(
        (method) => serverMethods.contains(method),
      );

      expect(authMethodsLeft.toList(), [
        SSHAuthMethod.publicKey,
        SSHAuthMethod.keyboardInteractive,
      ]);
    });
  });

  group('SSHAuthMethod.name consistency', () {
    test('SSHAuthMethod names match parsing expectations', () {
      // Verify that the SSHAuthMethodX extension names are consistent
      // with what parseServerAuthMethods expects.
      expect(SSHAuthMethod.none.name, 'none');
      expect(SSHAuthMethod.password.name, 'password');
      expect(SSHAuthMethod.publicKey.name, 'publickey');
      expect(SSHAuthMethod.keyboardInteractive.name, 'keyboard-interactive');
    });

    test('round-trip: enum -> name -> parse returns same enum', () {
      for (final method in SSHAuthMethod.values) {
        final parsed = parseServerAuthMethods([method.name]);
        expect(parsed, contains(method),
            reason: '${method.name} should parse back to $method');
        expect(parsed.length, 1);
      }
    });
  });
}
