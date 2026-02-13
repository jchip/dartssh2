import 'package:dartssh2/src/message/msg_disconnect.dart';
import 'package:test/test.dart';

void main() {
  group('SSH_Message_Disconnect', () {
    test('encode/decode round-trip preserves all fields', () {
      final original = SSH_Message_Disconnect(
        reasonCode: 11,
        description: 'Disconnected by application',
        languageTag: 'en',
      );

      final encoded = original.encode();
      final decoded = SSH_Message_Disconnect.decode(encoded);

      expect(decoded.reasonCode, 11);
      expect(decoded.description, 'Disconnected by application');
      expect(decoded.languageTag, 'en');
    });

    test('encode/decode round-trip with empty languageTag', () {
      final original = SSH_Message_Disconnect(
        reasonCode: 2,
        description: 'Protocol error',
      );

      final encoded = original.encode();
      final decoded = SSH_Message_Disconnect.decode(encoded);

      expect(decoded.reasonCode, 2);
      expect(decoded.description, 'Protocol error');
      expect(decoded.languageTag, '');
    });

    test('encode/decode round-trip with empty description', () {
      final original = SSH_Message_Disconnect(
        reasonCode: 1,
        description: '',
        languageTag: '',
      );

      final encoded = original.encode();
      final decoded = SSH_Message_Disconnect.decode(encoded);

      expect(decoded.reasonCode, 1);
      expect(decoded.description, '');
      expect(decoded.languageTag, '');
    });

    test('fromReason factory produces correct code and description', () {
      final msg = SSH_Message_Disconnect.fromReason(
        SSHDisconnectReason.protocolError,
      );

      expect(msg.reasonCode, 2);
      expect(msg.description, 'Protocol error');
      expect(msg.languageTag, '');
    });

    test('fromReason round-trips through encode/decode', () {
      final original = SSH_Message_Disconnect.fromReason(
        SSHDisconnectReason.keyExchangeFailed,
      );

      final encoded = original.encode();
      final decoded = SSH_Message_Disconnect.decode(encoded);

      expect(decoded.reasonCode, 3);
      expect(decoded.description, 'Key exchange failed');
      expect(decoded.languageTag, '');
    });

    test('encoded bytes start with correct message id', () {
      final msg = SSH_Message_Disconnect(
        reasonCode: 1,
        description: 'test',
      );
      final encoded = msg.encode();
      expect(encoded[0], SSH_Message_Disconnect.messageId);
      expect(encoded[0], 1);
    });
  });

  group('SSHDisconnectReason', () {
    test('hostNotAllowedToConnect has code 1', () {
      expect(SSHDisconnectReason.hostNotAllowedToConnect.code, 1);
      expect(
        SSHDisconnectReason.hostNotAllowedToConnect.description,
        'Host not allowed to connect',
      );
    });

    test('protocolError has code 2', () {
      expect(SSHDisconnectReason.protocolError.code, 2);
      expect(SSHDisconnectReason.protocolError.description, 'Protocol error');
    });

    test('keyExchangeFailed has code 3', () {
      expect(SSHDisconnectReason.keyExchangeFailed.code, 3);
      expect(
        SSHDisconnectReason.keyExchangeFailed.description,
        'Key exchange failed',
      );
    });

    test('reserved has code 4', () {
      expect(SSHDisconnectReason.reserved.code, 4);
    });

    test('macError has code 5', () {
      expect(SSHDisconnectReason.macError.code, 5);
      expect(SSHDisconnectReason.macError.description, 'MAC error');
    });

    test('compressionError has code 6', () {
      expect(SSHDisconnectReason.compressionError.code, 6);
    });

    test('serviceNotAvailable has code 7', () {
      expect(SSHDisconnectReason.serviceNotAvailable.code, 7);
    });

    test('protocolVersionNotSupported has code 8', () {
      expect(SSHDisconnectReason.protocolVersionNotSupported.code, 8);
    });

    test('hostKeyNotVerifiable has code 9', () {
      expect(SSHDisconnectReason.hostKeyNotVerifiable.code, 9);
    });

    test('connectionLost has code 10', () {
      expect(SSHDisconnectReason.connectionLost.code, 10);
    });

    test('byApplication has code 11', () {
      expect(SSHDisconnectReason.byApplication.code, 11);
    });

    test('tooManyConnections has code 12', () {
      expect(SSHDisconnectReason.tooManyConnections.code, 12);
    });

    test('authCancelledByUser has code 13', () {
      expect(SSHDisconnectReason.authCancelledByUser.code, 13);
    });

    test('noMoreAuthMethodsAvailable has code 14', () {
      expect(SSHDisconnectReason.noMoreAuthMethodsAvailable.code, 14);
    });

    test('illegalUserName has code 15', () {
      expect(SSHDisconnectReason.illegalUserName.code, 15);
    });
  });
}
