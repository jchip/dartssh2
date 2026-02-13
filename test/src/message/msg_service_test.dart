import 'package:dartssh2/src/message/msg_service.dart';
import 'package:test/test.dart';

void main() {
  group('SSH_Message_Service_Request', () {
    test('encode/decode round-trip preserves serviceName', () {
      final original = SSH_Message_Service_Request('ssh-userauth');

      final encoded = original.encode();
      final decoded = SSH_Message_Service_Request.decode(encoded);

      expect(decoded.serviceName, 'ssh-userauth');
    });

    test('encode/decode round-trip with ssh-connection', () {
      final original = SSH_Message_Service_Request('ssh-connection');

      final encoded = original.encode();
      final decoded = SSH_Message_Service_Request.decode(encoded);

      expect(decoded.serviceName, 'ssh-connection');
    });

    test('encoded bytes start with correct message id', () {
      final msg = SSH_Message_Service_Request('ssh-userauth');
      final encoded = msg.encode();
      expect(encoded[0], SSH_Message_Service_Request.messageId);
      expect(encoded[0], 5);
    });

    test('encode/decode round-trip with empty service name', () {
      final original = SSH_Message_Service_Request('');

      final encoded = original.encode();
      final decoded = SSH_Message_Service_Request.decode(encoded);

      expect(decoded.serviceName, '');
    });
  });

  group('SSH_Message_Service_Accept', () {
    test('encode/decode round-trip preserves serviceName', () {
      final original = SSH_Message_Service_Accept('ssh-userauth');

      final encoded = original.encode();
      final decoded = SSH_Message_Service_Accept.decode(encoded);

      expect(decoded.serviceName, 'ssh-userauth');
    });

    test('encode/decode round-trip with ssh-connection', () {
      final original = SSH_Message_Service_Accept('ssh-connection');

      final encoded = original.encode();
      final decoded = SSH_Message_Service_Accept.decode(encoded);

      expect(decoded.serviceName, 'ssh-connection');
    });

    test('encoded bytes start with correct message id', () {
      final msg = SSH_Message_Service_Accept('ssh-userauth');
      final encoded = msg.encode();
      expect(encoded[0], SSH_Message_Service_Accept.messageId);
      expect(encoded[0], 6);
    });

    test('encode/decode round-trip with empty service name', () {
      final original = SSH_Message_Service_Accept('');

      final encoded = original.encode();
      final decoded = SSH_Message_Service_Accept.decode(encoded);

      expect(decoded.serviceName, '');
    });
  });
}
