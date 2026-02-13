import 'dart:typed_data';

import 'package:dartssh2/src/hostkey/hostkey_rsa.dart';
import 'package:dartssh2/src/ssh_message.dart';
import 'package:pointycastle/export.dart' hide Signature;
import 'package:pointycastle/asymmetric/api.dart' as asymmetric;
import 'package:test/test.dart';

void main() {
  group('SSHRsaPublicKey', () {
    late asymmetric.RSAPublicKey publicKey;
    late asymmetric.RSAPrivateKey privateKey;
    late SSHRsaPublicKey sshPublicKey;
    late Uint8List testMessage;

    setUp(() {
      final seed = Uint8List(32)..fillRange(0, 32, 42);
      final keyGen = RSAKeyGenerator()
        ..init(ParametersWithRandom(
          RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64),
          FortunaRandom()..seed(KeyParameter(seed)),
        ));
      final pair = keyGen.generateKeyPair();
      publicKey = pair.publicKey as asymmetric.RSAPublicKey;
      privateKey = pair.privateKey as asymmetric.RSAPrivateKey;

      sshPublicKey = SSHRsaPublicKey(publicKey.publicExponent!, publicKey.modulus!);
      testMessage = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
    });

    group('encode/decode round-trip', () {
      test('preserves e and n values through encode then decode', () {
        final encoded = sshPublicKey.encode();
        final decoded = SSHRsaPublicKey.decode(encoded);

        expect(decoded.e, equals(sshPublicKey.e));
        expect(decoded.n, equals(sshPublicKey.n));
      });

      test('encoded data starts with ssh-rsa type string', () {
        final encoded = sshPublicKey.encode();
        final reader = SSHMessageReader(encoded);
        final type = reader.readUtf8();
        expect(type, equals('ssh-rsa'));
      });
    });

    group('verify', () {
      asymmetric.RSASignature _signWithDigest(
        Uint8List message,
        Digest digest,
        String digestId,
      ) {
        final signer = RSASigner(digest, digestId)
          ..init(
            true,
            PrivateKeyParameter<asymmetric.RSAPrivateKey>(privateKey),
          );
        return signer.generateSignature(message) as asymmetric.RSASignature;
      }

      test('accepts valid SHA-256 signature (DS2-22: no FortunaRandom needed)', () {
        final sig = _signWithDigest(
          testMessage,
          SHA256Digest(),
          '0609608648016503040201',
        );

        final sshSig = SSHRsaSignature(
          SSHRsaSignatureType.sha256,
          sig.bytes,
        );

        expect(sshPublicKey.verify(testMessage, sshSig), isTrue);
      });

      test('accepts valid SHA-1 signature', () {
        final sig = _signWithDigest(
          testMessage,
          SHA1Digest(),
          '06052b0e03021a',
        );

        final sshSig = SSHRsaSignature(
          SSHRsaSignatureType.sha1,
          sig.bytes,
        );

        expect(sshPublicKey.verify(testMessage, sshSig), isTrue);
      });

      test('accepts valid SHA-512 signature', () {
        final sig = _signWithDigest(
          testMessage,
          SHA512Digest(),
          '0609608648016503040203',
        );

        final sshSig = SSHRsaSignature(
          SSHRsaSignatureType.sha512,
          sig.bytes,
        );

        expect(sshPublicKey.verify(testMessage, sshSig), isTrue);
      });

      test('rejects tampered signature (flipped bit)', () {
        final sig = _signWithDigest(
          testMessage,
          SHA256Digest(),
          '0609608648016503040201',
        );

        final tamperedBytes = Uint8List.fromList(sig.bytes);
        // Flip a bit in the middle of the signature
        tamperedBytes[tamperedBytes.length ~/ 2] ^= 0x01;

        final sshSig = SSHRsaSignature(
          SSHRsaSignatureType.sha256,
          tamperedBytes,
        );

        expect(sshPublicKey.verify(testMessage, sshSig), isFalse);
      });

      test('rejects signature for wrong message', () {
        final sig = _signWithDigest(
          testMessage,
          SHA256Digest(),
          '0609608648016503040201',
        );

        final sshSig = SSHRsaSignature(
          SSHRsaSignatureType.sha256,
          sig.bytes,
        );

        final wrongMessage = Uint8List.fromList([9, 9, 9, 9]);
        expect(sshPublicKey.verify(wrongMessage, sshSig), isFalse);
      });

      test('throws FormatException for unknown signature type', () {
        final sshSig = SSHRsaSignature(
          'unknown-type',
          Uint8List(256),
        );

        expect(
          () => sshPublicKey.verify(testMessage, sshSig),
          throwsFormatException,
        );
      });
    });
  });

  group('SSHRsaSignature', () {
    test('encode/decode round-trip preserves type and signature bytes', () {
      final originalType = SSHRsaSignatureType.sha256;
      final originalBytes = Uint8List.fromList(
        List.generate(256, (i) => i % 256),
      );
      final original = SSHRsaSignature(originalType, originalBytes);

      final encoded = original.encode();
      final decoded = SSHRsaSignature.decode(encoded);

      expect(decoded.type, equals(originalType));
      expect(decoded.signature, equals(originalBytes));
    });

    test('encode/decode round-trip with SHA-1 type', () {
      final originalType = SSHRsaSignatureType.sha1;
      final originalBytes = Uint8List.fromList([0xDE, 0xAD, 0xBE, 0xEF]);
      final original = SSHRsaSignature(originalType, originalBytes);

      final encoded = original.encode();
      final decoded = SSHRsaSignature.decode(encoded);

      expect(decoded.type, equals(originalType));
      expect(decoded.signature, equals(originalBytes));
    });

    test('encode/decode round-trip with SHA-512 type', () {
      final originalType = SSHRsaSignatureType.sha512;
      final originalBytes = Uint8List(512)..fillRange(0, 512, 0xAB);
      final original = SSHRsaSignature(originalType, originalBytes);

      final encoded = original.encode();
      final decoded = SSHRsaSignature.decode(encoded);

      expect(decoded.type, equals(originalType));
      expect(decoded.signature, equals(originalBytes));
    });
  });

  group('SSHRsaPublicKey.decode', () {
    test('throws on invalid key type', () {
      final writer = SSHMessageWriter();
      writer.writeUtf8('ssh-ed25519');
      writer.writeMpint(BigInt.from(65537));
      writer.writeMpint(BigInt.from(12345));

      expect(
        () => SSHRsaPublicKey.decode(writer.takeBytes()),
        throwsException,
      );
    });
  });
}
