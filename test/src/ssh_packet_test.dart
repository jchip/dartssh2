import 'dart:typed_data';

import 'package:dartssh2/src/ssh_packet.dart';
import 'package:test/test.dart';

void main() {
  group('SSHPacket', () {
    test('pack() generates non-zero padding (random bytes)', () {
      final payload = Uint8List.fromList([1, 2, 3, 4]);
      final packet = SSHPacket.pack(payload, align: 8);

      // Extract padding from the packet
      final paddingLength = packet[4];
      final paddingStart = 5 + payload.length;
      final padding = packet.sublist(paddingStart, paddingStart + paddingLength);

      // With random padding, the probability of all zeros in >= 4 bytes
      // is astronomically low (1/256^4 at minimum). Run multiple times
      // to be safe.
      var hasNonZero = false;
      for (var attempt = 0; attempt < 10; attempt++) {
        final p = SSHPacket.pack(payload, align: 8);
        final pl = p[4];
        final ps = 5 + payload.length;
        final pad = p.sublist(ps, ps + pl);
        if (pad.any((b) => b != 0)) {
          hasNonZero = true;
          break;
        }
      }
      expect(hasNonZero, isTrue,
          reason: 'Padding should contain random bytes, not all zeros');
    });

    test('pack() produces correct packet structure', () {
      final payload = Uint8List.fromList([42]);
      final packet = SSHPacket.pack(payload, align: 8);

      // Verify packet length field
      final packetLength = ByteData.sublistView(packet).getUint32(0);
      expect(packetLength, packet.length - 4);

      // Verify padding length
      final paddingLength = packet[4];
      expect(paddingLength, greaterThanOrEqualTo(4));

      // Verify total alignment
      expect(packet.length % 8, 0);
    });

    test('paddingLength() returns at least 4', () {
      for (var i = 0; i < 32; i++) {
        final padding = SSHPacket.paddingLength(i, align: 8);
        expect(padding, greaterThanOrEqualTo(4));
      }
    });
  });

  group('SSHPacketSN', () {
    test('wraps around after 0xFFFFFFFF', () {
      final sn = SSHPacketSN(0xFFFFFFFF);
      sn.increase();
      expect(sn.value, 0);
    });

    test('increments normally', () {
      final sn = SSHPacketSN(0);
      sn.increase();
      expect(sn.value, 1);
    });
  });
}
