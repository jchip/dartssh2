import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartssh2/dartssh2.dart';
import 'package:dartssh2/src/ssh_local_forward.dart';
import 'package:test/test.dart';

void main() {
  group('bindLocalForwardServer', () {
    test('binds to a loopback port and closes cleanly', () async {
      final targetServer = await ServerSocket.bind('127.0.0.1', 0);
      addTearDown(targetServer.close);

      targetServer.listen((socket) {
        socket.destroy();
      });

      final forward = await bindLocalForwardServer(
        localHost: '127.0.0.1',
        localPort: null,
        remoteHost: 'example.internal',
        remotePort: 8080,
        openChannel: (originatorHost, originatorPort) {
          return SSHSocket.connect('127.0.0.1', targetServer.port);
        },
      );
      addTearDown(forward.close);

      expect(forward.localHost, equals('127.0.0.1'));
      expect(forward.localPort, greaterThan(0));
      expect(forward.remoteHost, equals('example.internal'));
      expect(forward.remotePort, equals(8080));

      await forward.close();
      await forward.done;
    });

    test('bridges bytes between local clients and the opened channel',
        () async {
      final receivedPayload = Completer<String>();
      final targetServer = await ServerSocket.bind('127.0.0.1', 0);
      addTearDown(targetServer.close);

      targetServer.listen((socket) async {
        final body = utf8.decode(await socket.first);
        if (!receivedPayload.isCompleted) {
          receivedPayload.complete(body);
        }
        socket.write('pong');
        await socket.flush();
        await socket.close();
      });

      String? seenOriginatorHost;
      int? seenOriginatorPort;
      final forward = await bindLocalForwardServer(
        localHost: '127.0.0.1',
        localPort: null,
        remoteHost: 'db.internal',
        remotePort: 5432,
        openChannel: (originatorHost, originatorPort) async {
          seenOriginatorHost = originatorHost;
          seenOriginatorPort = originatorPort;
          return SSHSocket.connect('127.0.0.1', targetServer.port);
        },
      );
      addTearDown(forward.close);

      final localClient = await Socket.connect('127.0.0.1', forward.localPort);
      addTearDown(localClient.close);

      localClient.write('ping');
      await localClient.flush();

      final response = utf8.decode(await localClient.first);

      expect(response, equals('pong'));
      expect(await receivedPayload.future, equals('ping'));
      expect(seenOriginatorHost, equals('127.0.0.1'));
      expect(seenOriginatorPort, isNotNull);
      expect(seenOriginatorPort, greaterThan(0));
    });
  });
}
