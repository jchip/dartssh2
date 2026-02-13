import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:test/test.dart';

/// A mock SSHSocket that allows feeding data through a StreamController
/// and captures anything written to the sink.
class MockSSHSocket implements SSHSocket {
  final _streamController = StreamController<Uint8List>();
  final _sinkController = StreamController<List<int>>();
  final _doneCompleter = Completer<void>();

  @override
  Stream<Uint8List> get stream => _streamController.stream;

  @override
  StreamSink<List<int>> get sink => _sinkController.sink;

  @override
  Future<void> get done => _doneCompleter.future;

  /// Feed raw bytes into the socket stream (simulating data from the remote).
  void feedData(Uint8List data) {
    if (!_streamController.isClosed) {
      _streamController.add(data);
    }
  }

  /// Feed a string as latin1-encoded bytes.
  void feedString(String s) {
    feedData(Uint8List.fromList(latin1.encode(s)));
  }

  @override
  Future<void> close() async {
    if (!_doneCompleter.isCompleted) {
      _doneCompleter.complete();
    }
    await _streamController.close();
    await _sinkController.close();
  }

  @override
  void destroy() {
    if (!_doneCompleter.isCompleted) {
      _doneCompleter.complete();
    }
    _streamController.close();
    _sinkController.close();
  }
}

void main() {
  group('SSHTransport version exchange', () {
    // DS2-11: Version exchange should skip non-SSH banner lines per RFC 4253
    // Section 4.2.

    test('DS2-11: accepts version after a single banner line', () async {
      final socket = MockSSHSocket();
      final transport = SSHTransport(
        socket,
        isServer: false,
        version: 'TestSSH_1.0',
      );

      // Feed a banner line followed by the SSH version string.
      // Per RFC 4253 Section 4.2, lines not starting with 'SSH-' should be
      // silently ignored.
      socket.feedString('Welcome to SSH Server\r\n');

      // Allow the stream event to be processed.
      await Future.delayed(Duration.zero);

      // remoteVersion should still be null because the banner line was skipped
      // and no SSH version line has arrived yet.
      expect(transport.remoteVersion, isNull);

      // Now send the actual SSH version.
      socket.feedString('SSH-2.0-OpenSSH_8.9\r\n');
      await Future.delayed(Duration.zero);

      expect(transport.remoteVersion, equals('SSH-2.0-OpenSSH_8.9'));

      transport.close();
      // Wait for close to avoid dangling futures.
      await transport.done.catchError((_) {});
    });

    test('DS2-11: accepts version after multiple non-SSH banner lines',
        () async {
      final socket = MockSSHSocket();
      final transport = SSHTransport(
        socket,
        isServer: false,
        version: 'TestSSH_1.0',
      );

      // Feed multiple banner lines before the SSH version.
      socket.feedString(
        'Welcome to Example Server\r\n'
        'Authorized users only\r\n'
        'Contact admin@example.com for access\r\n'
        'SSH-2.0-OpenSSH_8.9\r\n',
      );
      await Future.delayed(Duration.zero);

      expect(transport.remoteVersion, equals('SSH-2.0-OpenSSH_8.9'));

      transport.close();
      await transport.done.catchError((_) {});
    });

    test(
        'DS2-11: skips banner lines delivered in separate chunks before version',
        () async {
      final socket = MockSSHSocket();
      final transport = SSHTransport(
        socket,
        isServer: false,
        version: 'TestSSH_1.0',
      );

      socket.feedString('Banner line 1\r\n');
      await Future.delayed(Duration.zero);
      expect(transport.remoteVersion, isNull);

      socket.feedString('Banner line 2\r\n');
      await Future.delayed(Duration.zero);
      expect(transport.remoteVersion, isNull);

      socket.feedString('SSH-2.0-MyServer_1.0\r\n');
      await Future.delayed(Duration.zero);
      expect(transport.remoteVersion, equals('SSH-2.0-MyServer_1.0'));

      transport.close();
      await transport.done.catchError((_) {});
    });

    // DS2-12: Version exchange should buffer partial data instead of throwing.

    test('DS2-12: buffers partial version data across multiple chunks',
        () async {
      final socket = MockSSHSocket();
      final transport = SSHTransport(
        socket,
        isServer: false,
        version: 'TestSSH_1.0',
      );

      // Send the version string in fragments. Before DS2-12, this would throw
      // because the code didn't handle incomplete lines.
      socket.feedString('SSH-2.0-');
      await Future.delayed(Duration.zero);
      expect(transport.remoteVersion, isNull,
          reason: 'No complete line yet, should buffer');
      expect(transport.isClosed, isFalse,
          reason: 'Should not close on partial data');

      socket.feedString('Ope');
      await Future.delayed(Duration.zero);
      expect(transport.remoteVersion, isNull,
          reason: 'Still no complete line, should continue buffering');
      expect(transport.isClosed, isFalse);

      socket.feedString('nSSH_8.9\r\n');
      await Future.delayed(Duration.zero);
      expect(transport.remoteVersion, equals('SSH-2.0-OpenSSH_8.9'));

      transport.close();
      await transport.done.catchError((_) {});
    });

    test('DS2-12: buffers partial banner line without throwing', () async {
      final socket = MockSSHSocket();
      final transport = SSHTransport(
        socket,
        isServer: false,
        version: 'TestSSH_1.0',
      );

      // Send a partial banner line (no newline yet).
      socket.feedString('Welcome to');
      await Future.delayed(Duration.zero);
      expect(transport.remoteVersion, isNull);
      expect(transport.isClosed, isFalse,
          reason: 'Should not close on partial banner data');

      // Complete the banner and send the version.
      socket.feedString(' the server\r\nSSH-2.0-Test_1.0\r\n');
      await Future.delayed(Duration.zero);
      expect(transport.remoteVersion, equals('SSH-2.0-Test_1.0'));

      transport.close();
      await transport.done.catchError((_) {});
    });

    // Normal case: direct version string.

    test('accepts SSH-2.0 version string directly', () async {
      final socket = MockSSHSocket();
      final transport = SSHTransport(
        socket,
        isServer: false,
        version: 'TestSSH_1.0',
      );

      socket.feedString('SSH-2.0-OpenSSH_8.9\r\n');
      await Future.delayed(Duration.zero);

      expect(transport.remoteVersion, equals('SSH-2.0-OpenSSH_8.9'));

      transport.close();
      await transport.done.catchError((_) {});
    });

    test('accepts version string terminated by bare LF', () async {
      final socket = MockSSHSocket();
      final transport = SSHTransport(
        socket,
        isServer: false,
        version: 'TestSSH_1.0',
      );

      // Some implementations terminate version exchange with \n only.
      socket.feedString('SSH-2.0-Synology_DS120j\n');
      await Future.delayed(Duration.zero);

      expect(transport.remoteVersion, equals('SSH-2.0-Synology_DS120j'));

      transport.close();
      await transport.done.catchError((_) {});
    });

    // Error case: SSH-1.0 is not supported.

    test('rejects SSH-1.0 version and closes with error', () async {
      final socket = MockSSHSocket();
      final transport = SSHTransport(
        socket,
        isServer: false,
        version: 'TestSSH_1.0',
      );

      // Eagerly attach an error handler to prevent the completeError from
      // being treated as an uncaught async error in the test zone.
      Object? caughtError;
      transport.done.catchError((Object e) {
        caughtError = e;
      });

      socket.feedString('SSH-1.0-Old\r\n');
      await Future.delayed(Duration.zero);

      // The transport should have closed with an SSHHandshakeError.
      expect(transport.isClosed, isTrue);
      expect(caughtError, isA<SSHHandshakeError>());
    });

    test('rejects SSH-1.99 version and closes with error', () async {
      final socket = MockSSHSocket();
      final transport = SSHTransport(
        socket,
        isServer: false,
        version: 'TestSSH_1.0',
      );

      Object? caughtError;
      transport.done.catchError((Object e) {
        caughtError = e;
      });

      socket.feedString('SSH-1.99-Compat\r\n');
      await Future.delayed(Duration.zero);

      expect(transport.isClosed, isTrue);
      expect(caughtError, isA<SSHHandshakeError>());
    });

    test('rejects invalid SSH version after banner lines', () async {
      final socket = MockSSHSocket();
      final transport = SSHTransport(
        socket,
        isServer: false,
        version: 'TestSSH_1.0',
      );

      Object? caughtError;
      transport.done.catchError((Object e) {
        caughtError = e;
      });

      // Banner lines are skipped, but the SSH-1.0 line should cause an error.
      socket.feedString(
        'Welcome\r\n'
        'SSH-1.0-OldServer\r\n',
      );
      await Future.delayed(Duration.zero);

      expect(transport.isClosed, isTrue);
      expect(caughtError, isA<SSHHandshakeError>());
    });

    // Edge cases.

    test('handles version string with extra metadata after version', () async {
      final socket = MockSSHSocket();
      final transport = SSHTransport(
        socket,
        isServer: false,
        version: 'TestSSH_1.0',
      );

      // RFC 4253 allows optional comments after the software version.
      socket.feedString('SSH-2.0-OpenSSH_8.9 Ubuntu-1\r\n');
      await Future.delayed(Duration.zero);

      expect(
          transport.remoteVersion, equals('SSH-2.0-OpenSSH_8.9 Ubuntu-1'));

      transport.close();
      await transport.done.catchError((_) {});
    });

    test('remoteVersion is null before any data is received', () async {
      final socket = MockSSHSocket();
      final transport = SSHTransport(
        socket,
        isServer: false,
        version: 'TestSSH_1.0',
      );

      // No data fed yet.
      expect(transport.remoteVersion, isNull);

      transport.close();
      await transport.done.catchError((_) {});
    });
  });
}
