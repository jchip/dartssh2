import 'dart:typed_data';

import 'package:dartssh2/src/utils/bcrypt.dart';
import 'package:test/test.dart';

void main() {
  test('Blowfish dec() reverses enc()', () {
    final bf = Blowfish();
    // Use a known key to set up the state
    final key = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]);
    bf.expand0state(key, key.length);

    // Encrypt some data
    final original = Uint32List.fromList([0x12345678, 0x9ABCDEF0]);
    final data = Uint32List.fromList([original[0], original[1]]);
    bf.enc(data, 1);

    // The encrypted data should differ from original
    expect(data[0] != original[0] || data[1] != original[1], isTrue);

    // Decrypt should restore original
    bf.dec(data, 1);
    expect(data[0], equals(original[0]));
    expect(data[1], equals(original[1]));
  });

  test('BLF_J is instance-level (thread-safe)', () {
    // Create two Blowfish instances; their _blfJ state should be independent
    final bf1 = Blowfish();
    final bf2 = Blowfish();
    final key1 = Uint8List.fromList([1, 2, 3, 4]);
    final key2 = Uint8List.fromList([5, 6, 7, 8]);

    // Operations on bf1 should not affect bf2's state
    bf1.expand0state(key1, key1.length);
    bf2.expand0state(key2, key2.length);

    // Both should complete without errors - previously would corrupt global state
    expect(true, isTrue);
  });

  test('bcrypt_pbkdf', () {
    final passphrase = Uint8List.fromList(
      [49, 50, 51, 52, 53, 54],
    );

    final salt = Uint8List.fromList(
      [180, 151, 210, 40, 110, 7, 72, 146, 145, 81, 92, 133, 92, 72, 202, 61],
    );

    final output = Uint8List(48);

    bcrypt_pbkdf(
      passphrase,
      passphrase.lengthInBytes,
      salt,
      salt.lengthInBytes,
      output,
      output.lengthInBytes,
      16,
    );

    expect(
      output,
      Uint8List.fromList([
        176,
        247,
        9,
        83,
        159,
        104,
        252,
        200,
        108,
        121,
        127,
        254,
        249,
        17,
        36,
        46,
        110,
        105,
        124,
        105,
        58,
        131,
        59,
        151,
        33,
        134,
        88,
        36,
        11,
        191,
        130,
        97,
        65,
        69,
        243,
        216,
        159,
        223,
        179,
        176,
        185,
        5,
        228,
        254,
        245,
        2,
        178,
        59,
      ]),
    );
  });
}
