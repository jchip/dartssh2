import 'dart:io';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:test/test.dart';

void main() {
  group('SSHSocket', () {
    test('can establish tcp connections', () async {
      // Use a local TCP server instead of an external one
      final server = await ServerSocket.bind('127.0.0.1', 0);
      final port = server.port;

      server.listen((client) {
        client.add(Uint8List.fromList([72, 101, 108, 108, 111])); // "Hello"
        client.close();
      });

      try {
        final socket = await SSHSocket.connect('127.0.0.1', port);
        final firstPacket = await socket.stream.first;
        expect(firstPacket, isNotEmpty);
        await socket.close();
      } finally {
        await server.close();
      }
    });

    test('throws on connection to non-existent server', () async {
      expect(
        () => SSHSocket.connect('127.0.0.1', 1,
            timeout: const Duration(seconds: 2)),
        throwsA(anything),
      );
    });
  });
}
