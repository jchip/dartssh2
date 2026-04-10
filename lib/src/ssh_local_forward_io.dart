import 'dart:async';
import 'dart:io';

import 'package:dartssh2/src/socket/ssh_socket.dart';
import 'package:dartssh2/src/ssh_forward.dart';

Future<SSHLocalForwardServer> bindLocalForwardServer({
  required String localHost,
  required int? localPort,
  required String remoteHost,
  required int remotePort,
  required Future<SSHSocket> Function(String originatorHost, int originatorPort)
      openChannel,
}) async {
  final serverSocket = await ServerSocket.bind(localHost, localPort ?? 0);
  return _SSHLocalForwardServerIO(
    serverSocket,
    localHost: localHost,
    remoteHost: remoteHost,
    remotePort: remotePort,
    openChannel: openChannel,
  )..start();
}

class _SSHLocalForwardServerIO implements SSHLocalForwardServer {
  _SSHLocalForwardServerIO(
    this._serverSocket, {
    required this.localHost,
    required this.remoteHost,
    required this.remotePort,
    required Future<SSHSocket> Function(
            String originatorHost, int originatorPort)
        openChannel,
  }) : _openChannel = openChannel;

  final ServerSocket _serverSocket;
  final Future<SSHSocket> Function(String originatorHost, int originatorPort)
      _openChannel;
  final _activeBridges = <_ActiveBridge>{};
  final _activeConnections = <Future<void>>{};
  final _doneCompleter = Completer<void>();

  StreamSubscription<Socket>? _subscription;
  bool _closing = false;

  @override
  final String localHost;

  @override
  int get localPort => _serverSocket.port;

  @override
  final String remoteHost;

  @override
  final int remotePort;

  @override
  Future<void> get done => _doneCompleter.future;

  void start() {
    _subscription = _serverSocket.listen(
      _handleSocket,
      onError: _completeWithError,
      onDone: _completeDone,
      cancelOnError: true,
    );
  }

  void _handleSocket(Socket socket) {
    if (_closing) {
      socket.destroy();
      return;
    }

    final bridge = _ActiveBridge(socket);
    _activeBridges.add(bridge);
    final trackedConnection = _bridgeSocket(bridge).catchError((_) {});
    _activeConnections.add(trackedConnection);
    trackedConnection.whenComplete(() {
      _activeBridges.remove(bridge);
      _activeConnections.remove(trackedConnection);
      if (_closing && _activeConnections.isEmpty) {
        _completeDone();
      }
    });
  }

  Future<void> _bridgeSocket(_ActiveBridge bridge) async {
    final localSocket = bridge.localSocket;
    try {
      bridge.forwardSocket = await _openChannel(
        localSocket.remoteAddress.address,
        localSocket.remotePort,
      );
      await Future.wait([
        bridge.forwardSocket!.stream.cast<List<int>>().pipe(localSocket),
        localSocket.cast<List<int>>().pipe(bridge.forwardSocket!.sink),
      ]);
    } finally {
      try {
        await localSocket.close();
      } catch (_) {}
      if (bridge.forwardSocket != null) {
        try {
          await bridge.forwardSocket!.close();
        } catch (_) {
          bridge.forwardSocket!.destroy();
        }
      }
    }
  }

  void _completeWithError(Object error, [StackTrace? stackTrace]) {
    if (_doneCompleter.isCompleted) {
      return;
    }
    _doneCompleter.completeError(error, stackTrace);
  }

  void _completeDone() {
    if (_doneCompleter.isCompleted) {
      return;
    }
    _doneCompleter.complete();
  }

  @override
  Future<void> close() async {
    if (_closing) {
      return done;
    }
    _closing = true;

    await _subscription?.cancel();
    await _serverSocket.close();
    for (final bridge in _activeBridges) {
      bridge.localSocket.destroy();
      bridge.forwardSocket?.destroy();
    }

    if (_activeConnections.isEmpty) {
      _completeDone();
    } else {
      await Future.wait(_activeConnections.toList(), eagerError: false);
      _completeDone();
    }

    await done;
  }
}

class _ActiveBridge {
  _ActiveBridge(this.localSocket);

  final Socket localSocket;
  SSHSocket? forwardSocket;
}
