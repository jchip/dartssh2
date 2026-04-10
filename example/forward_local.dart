import 'dart:io';

import 'package:dartssh2/dartssh2.dart';

void main(List<String> args) async {
  final socket = await SSHSocket.connect('localhost', 22);

  final client = SSHClient(
    socket,
    username: 'root',
    onPasswordRequest: () {
      stdout.write('Password: ');
      stdin.echoMode = false;
      return stdin.readLineSync() ?? exit(1);
    },
  );

  await client.authenticated;

  final forward = await client.bindLocalForward(
    'httpbin.org',
    80,
    localHost: '127.0.0.1',
    localPort: 8080,
  );

  print('Listening on ${forward.localHost}:${forward.localPort}');

  await forward.done;

  client.close();
  await client.done;
}
