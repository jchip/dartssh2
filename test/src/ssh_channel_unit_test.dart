import 'package:dartssh2/src/message/msg_channel.dart';
import 'package:dartssh2/src/ssh_channel.dart';
import 'package:dartssh2/src/ssh_message.dart';
import 'package:test/test.dart';

void main() {
  group('SSHChannel', () {
    test('channelId returns local ID and remoteChannelId returns remote ID', () {
      final controller = SSHChannelController(
        localId: 1,
        localMaximumPacketSize: 32768,
        localInitialWindowSize: 2097152,
        remoteId: 42,
        remoteMaximumPacketSize: 32768,
        remoteInitialWindowSize: 2097152,
        sendMessage: (SSHMessage msg) {},
      );

      final channel = controller.channel;

      expect(channel.channelId, 1);
      expect(channel.remoteChannelId, 42);
      expect(channel.channelId != channel.remoteChannelId, isTrue,
          reason: 'local and remote IDs should be different');
    });

    test('toString contains both local and remote IDs', () {
      final controller = SSHChannelController(
        localId: 5,
        localMaximumPacketSize: 32768,
        localInitialWindowSize: 2097152,
        remoteId: 99,
        remoteMaximumPacketSize: 32768,
        remoteInitialWindowSize: 2097152,
        sendMessage: (SSHMessage msg) {},
      );

      final channel = controller.channel;
      expect(channel.toString(), contains('5'));
      expect(channel.toString(), contains('99'));
    });

    test('sendEnv uses wantReply:false to avoid poisoning reply queue', () {
      final sentMessages = <SSHMessage>[];
      final controller = SSHChannelController(
        localId: 1,
        localMaximumPacketSize: 32768,
        localInitialWindowSize: 2097152,
        remoteId: 10,
        remoteMaximumPacketSize: 32768,
        remoteInitialWindowSize: 0,
        sendMessage: (SSHMessage msg) {
          sentMessages.add(msg);
        },
      );

      controller.sendEnv('LANG', 'en_US.UTF-8');

      expect(sentMessages.length, 1);
      final msg = sentMessages.first as SSH_Message_Channel_Request;
      expect(msg.wantReply, isFalse,
          reason: 'sendEnv must use wantReply:false to avoid reply queue poisoning');
    });
  });
}
