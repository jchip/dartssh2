import 'dart:typed_data';

import 'package:dartssh2/src/kex/kex_nist.dart';
import 'package:test/test.dart';

void main() {
  test('SSHKexECDH.nistp256', () {
    final kex1 = SSHKexNist.p256();
    final kex2 = SSHKexNist.p256();
    final secret1 = kex1.computeSecret(kex2.publicKey);
    final secret2 = kex2.computeSecret(kex1.publicKey);
    expect(secret1, secret2);
  });

  test('SSHKexECDH.nistp384', () {
    final kex1 = SSHKexNist.p384();
    final kex2 = SSHKexNist.p384();
    final secret1 = kex1.computeSecret(kex2.publicKey);
    final secret2 = kex2.computeSecret(kex1.publicKey);
    expect(secret1, secret2);
  });

  test('SSHKexECDH.nistp521', () {
    final kex1 = SSHKexNist.p521();
    final kex2 = SSHKexNist.p521();
    final secret1 = kex1.computeSecret(kex2.publicKey);
    final secret2 = kex2.computeSecret(kex1.publicKey);
    expect(secret1, secret2);
  });

  group('SSHKexNist', () {
    test('generate keys and compute shared secret (P-256)', () {
      final kex = SSHKexNist.p256();
      final remoteKex = SSHKexNist.p256();

      final secret1 = kex.computeSecret(remoteKex.publicKey);
      final secret2 = remoteKex.computeSecret(kex.publicKey);

      expect(secret1, equals(secret2), reason: 'Shared secrets do not match.');
    });

    test('generate keys and compute shared secret (P-384)', () {
      final kex = SSHKexNist.p384();
      final remoteKex = SSHKexNist.p384();

      final secret1 = kex.computeSecret(remoteKex.publicKey);
      final secret2 = remoteKex.computeSecret(kex.publicKey);

      expect(secret1, equals(secret2), reason: 'Shared secrets do not match.');
    });

    test('generate keys and compute shared secret (P-521)', () {
      final kex = SSHKexNist.p521();
      final remoteKex = SSHKexNist.p521();

      final secret1 = kex.computeSecret(remoteKex.publicKey);
      final secret2 = remoteKex.computeSecret(kex.publicKey);

      expect(secret1, equals(secret2), reason: 'Shared secrets do not match.');
    });

    test('generate private key within valid range', () {
      final kex = SSHKexNist.p256();
      final privateKey = kex.privateKey;

      expect(privateKey, isNot(equals(BigInt.zero)),
          reason: 'Private key should not be zero.');
      expect(privateKey < kex.curve.n, isTrue,
          reason: 'Private key should be less than curve order.');
    });

    test('should reject point at infinity (all zeros)', () {
      final kex = SSHKexNist.p256();
      // Point at infinity is encoded as a single 0x00 byte
      expect(
        () => kex.computeSecret(Uint8List.fromList([0x00])),
        throwsA(anything),
      );
    });

    test('should reject invalid point not on curve', () {
      final kex = SSHKexNist.p256();
      // Construct an uncompressed point with invalid coordinates
      // 0x04 prefix + 32 bytes x + 32 bytes y (all 0x01 = not on curve)
      final invalidPoint = Uint8List(65);
      invalidPoint[0] = 0x04; // uncompressed
      for (var i = 1; i < 65; i++) {
        invalidPoint[i] = 0x01;
      }
      expect(
        () => kex.computeSecret(invalidPoint),
        throwsA(anything),
      );
    });
  });
}
