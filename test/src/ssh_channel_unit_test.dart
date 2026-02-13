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
  });
}
