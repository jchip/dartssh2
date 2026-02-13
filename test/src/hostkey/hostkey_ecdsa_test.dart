import 'dart:typed_data';

import 'package:dartssh2/src/hostkey/hostkey_ecdsa.dart';
import 'package:pointycastle/export.dart';
import 'package:test/test.dart';

void main() {
  group('SSHEcdsaPublicKey.verify', () {
    late ECPrivateKey ecPrivateKey;
    late ECPublicKey ecPublicKey;
    late SSHEcdsaPublicKey sshPublicKey;
    late Uint8List testMessage;

    setUp(() {
      final params = ECCurve_secp256r1();
      final keyGen = ECKeyGenerator()
        ..init(ParametersWithRandom(
          ECKeyGeneratorParameters(params),
          FortunaRandom()..seed(KeyParameter(Uint8List(32)..fillRange(0, 32, 42))),
        ));
      final keyPair = keyGen.generateKeyPair();
      ecPrivateKey = keyPair.privateKey as ECPrivateKey;
      ecPublicKey = keyPair.publicKey as ECPublicKey;

      sshPublicKey = SSHEcdsaPublicKey(
        type: 'ecdsa-sha2-nistp256',
        curveId: 'nistp256',
        q: ecPublicKey.Q!.getEncoded(false),
      );

      testMessage = Uint8List.fromList([1, 2, 3, 4, 5]);
    });

    ECSignature _sign(Uint8List message) {
      final signer = ECDSASigner(SHA256Digest())
        ..init(
          true,
          ParametersWithRandom(
            PrivateKeyParameter(ecPrivateKey),
            FortunaRandom()..seed(KeyParameter(Uint8List(32)..fillRange(0, 32, 99))),
          ),
        );
      return signer.generateSignature(message) as ECSignature;
    }

    test('accepts valid low-S signature', () {
      final sig = _sign(testMessage);
      final n = ECCurve_secp256r1().n;
      final halfN = n >> 1;

      // Normalize to low-S if needed
      var s = sig.s;
      if (s > halfN) {
        s = n - s;
      }

      final sshSig = SSHEcdsaSignature('ecdsa-sha2-nistp256', sig.r, s);
      expect(sshPublicKey.verify(testMessage, sshSig), isTrue);
    });

    test('rejects signature with s > n/2 (high-S malleability)', () {
      final sig = _sign(testMessage);
      final n = ECCurve_secp256r1().n;
      final halfN = n >> 1;

      // Force high-S
      var s = sig.s;
      if (s <= halfN) {
        s = n - s;
      }

      final sshSig = SSHEcdsaSignature('ecdsa-sha2-nistp256', sig.r, s);
      expect(sshPublicKey.verify(testMessage, sshSig), isFalse);
    });

    test('rejects signature with r = 0', () {
      final sshSig = SSHEcdsaSignature('ecdsa-sha2-nistp256', BigInt.zero, BigInt.one);
      expect(sshPublicKey.verify(testMessage, sshSig), isFalse);
    });

    test('rejects signature with s = 0', () {
      final sshSig = SSHEcdsaSignature('ecdsa-sha2-nistp256', BigInt.one, BigInt.zero);
      expect(sshPublicKey.verify(testMessage, sshSig), isFalse);
    });

    test('rejects signature with r >= n', () {
      final n = ECCurve_secp256r1().n;
      final sshSig = SSHEcdsaSignature('ecdsa-sha2-nistp256', n, BigInt.one);
      expect(sshPublicKey.verify(testMessage, sshSig), isFalse);
    });

    test('rejects signature with s >= n', () {
      final n = ECCurve_secp256r1().n;
      final sshSig = SSHEcdsaSignature('ecdsa-sha2-nistp256', BigInt.one, n);
      expect(sshPublicKey.verify(testMessage, sshSig), isFalse);
    });
  });
}
