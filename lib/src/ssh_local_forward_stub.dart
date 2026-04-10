import 'package:dartssh2/src/socket/ssh_socket.dart';
import 'package:dartssh2/src/ssh_forward.dart';

Future<SSHLocalForwardServer> bindLocalForwardServer({
  required String localHost,
  required int? localPort,
  required String remoteHost,
  required int remotePort,
  required Future<SSHSocket> Function(String originatorHost, int originatorPort)
      openChannel,
}) {
  throw UnsupportedError(
    'Local port forwarding listeners require dart:io and are not supported '
    'on web.',
  );
}
