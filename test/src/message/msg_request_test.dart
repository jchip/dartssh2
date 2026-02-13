import 'dart:typed_data';

import 'package:dartssh2/src/message/msg_request.dart';
import 'package:test/test.dart';

void main() {
  group('SSH_Message_Global_Request', () {
    test('tcpipForward encode/decode round-trip', () {
      final original = SSH_Message_Global_Request.tcpipForward(
        '127.0.0.1',
        8080,
      );

      final encoded = original.encode();
      final decoded = SSH_Message_Global_Request.decode(encoded);

      expect(decoded.requestName, 'tcpip-forward');
      expect(decoded.wantReply, isTrue);
      expect(decoded.bindAddress, '127.0.0.1');
      expect(decoded.bindPort, 8080);
    });

    test('tcpipForward with wildcard address and port 0', () {
      final original = SSH_Message_Global_Request.tcpipForward('0.0.0.0', 0);

      final encoded = original.encode();
      final decoded = SSH_Message_Global_Request.decode(encoded);

      expect(decoded.requestName, 'tcpip-forward');
      expect(decoded.wantReply, isTrue);
      expect(decoded.bindAddress, '0.0.0.0');
      expect(decoded.bindPort, 0);
    });

    test('cancelTcpipForward encode/decode round-trip', () {
      final original = SSH_Message_Global_Request.cancelTcpipForward(
        bindAddress: '192.168.1.100',
        bindPort: 3000,
      );

      final encoded = original.encode();
      final decoded = SSH_Message_Global_Request.decode(encoded);

      expect(decoded.requestName, 'cancel-tcpip-forward');
      expect(decoded.wantReply, isTrue);
      expect(decoded.bindAddress, '192.168.1.100');
      expect(decoded.bindPort, 3000);
    });

    test('keepAlive encode/decode round-trip', () {
      final original = SSH_Message_Global_Request.keepAlive();

      final encoded = original.encode();
      final decoded = SSH_Message_Global_Request.decode(encoded);

      expect(decoded.requestName, 'keepalive@openssh.com');
      expect(decoded.wantReply, isTrue);
      expect(decoded.bindAddress, isNull);
      expect(decoded.bindPort, isNull);
    });

    test('encoded bytes start with correct message id', () {
      final msg = SSH_Message_Global_Request.keepAlive();
      final encoded = msg.encode();
      expect(encoded[0], SSH_Message_Global_Request.messageId);
      expect(encoded[0], 80);
    });

    test('unknown request name decode produces no address/port', () {
      final original = SSH_Message_Global_Request(
        requestName: 'custom-request',
        wantReply: false,
      );

      final encoded = original.encode();
      final decoded = SSH_Message_Global_Request.decode(encoded);

      expect(decoded.requestName, 'custom-request');
      expect(decoded.wantReply, isFalse);
      expect(decoded.bindAddress, isNull);
      expect(decoded.bindPort, isNull);
    });
  });

  group('SSH_Message_Request_Success', () {
    test('encode/decode round-trip with data', () {
      final data = Uint8List.fromList([0x00, 0x00, 0x1F, 0x90]);
      final original = SSH_Message_Request_Success(data);

      final encoded = original.encode();
      final decoded = SSH_Message_Request_Success.decode(encoded);

      expect(decoded.requestData, equals(data));
    });

    test('encode/decode round-trip with empty data', () {
      final data = Uint8List(0);
      final original = SSH_Message_Request_Success(data);

      final encoded = original.encode();
      final decoded = SSH_Message_Request_Success.decode(encoded);

      expect(decoded.requestData, isEmpty);
    });

    test('encoded bytes start with correct message id', () {
      final msg = SSH_Message_Request_Success(Uint8List(0));
      final encoded = msg.encode();
      expect(encoded[0], SSH_Message_Request_Success.messageId);
      expect(encoded[0], 81);
    });
  });

  group('SSH_Message_Request_Failure', () {
    test('encode/decode round-trip', () {
      final original = SSH_Message_Request_Failure();

      final encoded = original.encode();
      final decoded = SSH_Message_Request_Failure.decode(encoded);

      expect(decoded, isA<SSH_Message_Request_Failure>());
    });

    test('encoded bytes start with correct message id', () {
      final msg = SSH_Message_Request_Failure();
      final encoded = msg.encode();
      expect(encoded[0], SSH_Message_Request_Failure.messageId);
      expect(encoded[0], 82);
    });

    test('encoded message is exactly 1 byte', () {
      final msg = SSH_Message_Request_Failure();
      final encoded = msg.encode();
      expect(encoded.length, 1);
    });
  });
}
