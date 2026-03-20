import 'dart:async';
import 'dart:typed_data';

import 'package:dartssh2/src/message/msg_channel.dart';
import 'package:dartssh2/src/message/msg_request.dart';
import 'package:dartssh2/src/message/msg_userauth.dart';
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

    test('dispatches global request reply to pending waiter', () async {
      final socket = _MockSSHSocket();
      final client = SSHClient(
        socket,
        username: 'test',
        keepAliveInterval: null,
      );

      final waiter = client.waitGlobalRequestReplyForTesting();
      expect(client.pendingGlobalRequestReplyWaiters, equals(1));

      client.handlePacket(
        SSH_Message_Request_Success(Uint8List.fromList([1, 2, 3])).encode(),
      );

      final reply = await waiter;
      expect(reply, isA<SSH_Message_Request_Success>());
      expect(
        (reply as SSH_Message_Request_Success).requestData,
        Uint8List.fromList([1, 2, 3]),
      );
      expect(client.pendingGlobalRequestReplyWaiters, equals(0));

      socket.destroy();
    });

    test('dispatches channel-open confirmation to matching waiter', () async {
      final socket = _MockSSHSocket();
      final client = SSHClient(
        socket,
        username: 'test',
        keepAliveInterval: null,
      );

      final waiter = client.waitChannelOpenReplyForTesting(7);
      expect(client.pendingChannelOpenReplyWaiters, equals(1));

      client.handlePacket(
        SSH_Message_Channel_Confirmation(
          recipientChannel: 7,
          senderChannel: 9,
          initialWindowSize: 2048,
          maximumPacketSize: 1024,
          data: Uint8List(0),
        ).encode(),
      );

      final reply = await waiter;
      expect(reply, isA<SSH_Message_Channel_Confirmation>());
      expect(
        (reply as SSH_Message_Channel_Confirmation).senderChannel,
        equals(9),
      );
      expect(client.pendingChannelOpenReplyWaiters, equals(0));

      socket.destroy();
    });
  });

  group('SSHClient session channel sizing', () {
    test('shell uses custom local initial window size for session channels',
        () async {
      final socket = _MockSSHSocket();
      final traceLines = <String>[];
      final client = SSHClient(
        socket,
        username: 'test',
        keepAliveInterval: null,
        printTrace: (line) => traceLines.add(line ?? ''),
      );

      client.handlePacket(SSH_Message_Userauth_Success().encode());

      final shellFuture = client.shell(localInitialWindowSize: 64 * 1024);
      await Future<void>.delayed(Duration.zero);

      expect(
        traceLines.where(
          (line) =>
              line.contains('SSH_Message_Channel_Open') &&
              line.contains('initialWindowSize: 65536'),
        ),
        isNotEmpty,
      );

      client.handleTransportClosedForTesting();
      await expectLater(shellFuture, throwsA(isA<SSHStateError>()));
      socket.destroy();
    });

    test('shell rejects non-positive local initial window size', () async {
      final socket = _MockSSHSocket();
      final client = SSHClient(
        socket,
        username: 'test',
        keepAliveInterval: null,
      );

      client.handlePacket(SSH_Message_Userauth_Success().encode());

      await expectLater(
        () => client.shell(localInitialWindowSize: 0),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.name,
            'name',
            'localInitialWindowSize',
          ),
        ),
      );

      socket.destroy();
    });
  });
}
