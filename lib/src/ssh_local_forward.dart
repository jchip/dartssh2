import 'package:dartssh2/src/socket/ssh_socket.dart';
import 'package:dartssh2/src/ssh_forward.dart';

import 'package:dartssh2/src/ssh_local_forward_stub.dart'
    if (dart.library.io) 'package:dartssh2/src/ssh_local_forward_io.dart'
    as impl;

typedef SSHLocalForwardChannelOpener = Future<SSHSocket> Function(
  String originatorHost,
  int originatorPort,
);

Future<SSHLocalForwardServer> bindLocalForwardServer({
  required String localHost,
  required int? localPort,
  required String remoteHost,
  required int remotePort,
  required SSHLocalForwardChannelOpener openChannel,
}) {
  return impl.bindLocalForwardServer(
    localHost: localHost,
    localPort: localPort,
    remoteHost: remoteHost,
    remotePort: remotePort,
    openChannel: openChannel,
  );
}
