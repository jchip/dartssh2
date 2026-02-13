import 'dart:typed_data';

import 'package:dartssh2/src/ssh_errors.dart';
import 'package:dartssh2/src/ssh_kex.dart';
import 'package:dartssh2/src/utils/bigint.dart';
import 'package:dartssh2/src/utils/list.dart';
import 'package:pointycastle/ecc/curves/secp256r1.dart';
import 'package:pointycastle/ecc/curves/secp384r1.dart';
import 'package:pointycastle/ecc/curves/secp521r1.dart';
import 'package:pointycastle/pointycastle.dart';

/// The Elliptic Curve Diffie-Hellman (ECDH) key exchange method generates a
/// shared secret from an ephemeral local elliptic curve private key and
/// ephemeral remote elliptic curve public key.
class SSHKexNist implements SSHKexECDH {
  /// The elliptic curve domain parameters.
  final ECDomainParameters curve;

  /// The length of the shared secret in bytes.
  final int secretBits;

  /// Secret random number.
  late final BigInt privateKey;

  /// Public key.
  @override
  late final Uint8List publicKey;

  SSHKexNist({required this.curve, required this.secretBits}) {
    privateKey = _generatePrivateKey();
    final c = curve.G * privateKey;
    publicKey = c!.getEncoded(false);
  }

  SSHKexNist.p256() : this(curve: ECCurve_secp256r1(), secretBits: 256);

  SSHKexNist.p384() : this(curve: ECCurve_secp384r1(), secretBits: 384);

  SSHKexNist.p521() : this(curve: ECCurve_secp521r1(), secretBits: 521);

  /// Compute shared secret.
  /// RFC 5656 Section 4: client MUST verify remote public key is valid.
  @override
  BigInt computeSecret(Uint8List remotePubilcKey) {
    final s = curve.curve.decodePoint(remotePubilcKey);
    if (s == null || s.isInfinity) {
      throw SSHHandshakeError('ECDH remote public key is the point at infinity');
    }
    // Validate point is on the curve: y² = x³ + ax + b (mod p)
    final x = s.x!.toBigInteger()!;
    final y = s.y!.toBigInteger()!;
    final a = curve.curve.a!.toBigInteger()!;
    final b = curve.curve.b!.toBigInteger()!;
    final p = (curve.curve as dynamic).q as BigInt;
    final lhs = (y * y) % p;
    final rhs = (x * x * x + a * x + b) % p;
    if (lhs != rhs) {
      throw SSHHandshakeError('ECDH remote public key is not on the curve');
    }
    final result = (s * privateKey)!;
    if (result.isInfinity) {
      throw SSHHandshakeError('ECDH shared secret is the point at infinity');
    }
    return result.x!.toBigInteger()!;
  }

  BigInt _generatePrivateKey() {
    late BigInt x;
    do {
      x = decodeBigIntWithSign(1, randomBytes(secretBits ~/ 8)) % curve.n;
    } while (x == BigInt.zero);
    return x;
  }
}
