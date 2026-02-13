import 'dart:async';
import 'dart:typed_data';

import 'package:dartssh2/src/ssh_client.dart';
import 'package:dartssh2/src/ssh_errors.dart';
import 'package:dartssh2/src/socket/ssh_socket.dart';
import 'package:test/test.dart';

class _MockSSHSocket implements SSHSocket {
  final _streamController = StreamController<Uint8List>();
  final _sinkController = StreamController<List<int>>();
  final _doneCompleter = Completer<void>();

  @override
  Stream<Uint8List> get stream => _streamController.stream;

  @override
  StreamSink<List<int>> get sink => _sinkController.sink;

  @override
  Future<void> get done => _doneCompleter.future;

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
  group('SSHClient close cleanup', () {
    test('DS2-41: clears pending waiters on transport close', () async {
      final socket = _MockSSHSocket();
      final client = SSHClient(
        socket,
        username: 'test',
        keepAliveInterval: null,
      );

      final globalRequestWaiter = client.waitGlobalRequestReplyForTesting();
      final channelOpenWaiter = client.waitChannelOpenReplyForTesting(1);

      expect(client.pendingGlobalRequestReplyWaiters, equals(1));
      expect(client.pendingChannelOpenReplyWaiters, equals(1));

      client.handleTransportClosedForTesting();

      await expectLater(
        globalRequestWaiter,
        throwsA(
          isA<SSHStateError>().having(
            (e) => e.message,
            'message',
            'Connection closed',
          ),
        ),
      );
      await expectLater(
        channelOpenWaiter,
        throwsA(
          isA<SSHStateError>().having(
            (e) => e.message,
            'message',
            'Connection closed',
          ),
        ),
      );
      expect(client.pendingGlobalRequestReplyWaiters, equals(0));
      expect(client.pendingChannelOpenReplyWaiters, equals(0));

      socket.destroy();
    });
  });
}
