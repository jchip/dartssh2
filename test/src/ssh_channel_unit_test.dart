import 'dart:typed_data';

import 'package:dartssh2/src/message/msg_channel.dart';
import 'package:dartssh2/src/ssh_channel.dart';
import 'package:dartssh2/src/ssh_message.dart';
import 'package:test/test.dart';

void main() {
  group('SSHChannel', () {
    test('channelId returns local ID and remoteChannelId returns remote ID',
        () {
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
          reason:
              'sendEnv must use wantReply:false to avoid reply queue poisoning');
    });

    test('sends window-adjust for consumed incoming data', () async {
      final sentMessages = <SSHMessage>[];
      final controller = SSHChannelController(
        localId: 1,
        localMaximumPacketSize: 32768,
        localInitialWindowSize: 1024,
        remoteId: 42,
        remoteMaximumPacketSize: 32768,
        remoteInitialWindowSize: 1024,
        sendMessage: sentMessages.add,
      );
      final sub = controller.channel.stream.listen((_) {});

      controller.handleMessage(
        SSH_Message_Channel_Data(
          recipientChannel: controller.localId,
          data: Uint8List(64),
        ),
      );

      final adjustMessages =
          sentMessages.whereType<SSH_Message_Channel_Window_Adjust>().toList();
      expect(adjustMessages.length, 1);
      expect(adjustMessages.single.recipientChannel, 42);
      expect(adjustMessages.single.bytesToAdd, 64);

      await sub.cancel();
      controller.destroy();
    });

    test('defers window-adjust while stream is paused and sends on resume',
        () async {
      final sentMessages = <SSHMessage>[];
      final controller = SSHChannelController(
        localId: 1,
        localMaximumPacketSize: 32768,
        localInitialWindowSize: 1024,
        remoteId: 42,
        remoteMaximumPacketSize: 32768,
        remoteInitialWindowSize: 1024,
        sendMessage: sentMessages.add,
      );

      final sub = controller.channel.stream.listen((_) {});
      sub.pause();

      controller.handleMessage(
        SSH_Message_Channel_Data(
          recipientChannel: controller.localId,
          data: Uint8List(32),
        ),
      );

      expect(
        sentMessages.whereType<SSH_Message_Channel_Window_Adjust>(),
        isEmpty,
      );

      sub.resume();
      await Future<void>.delayed(Duration.zero);

      final adjustMessages =
          sentMessages.whereType<SSH_Message_Channel_Window_Adjust>().toList();
      expect(adjustMessages.length, 1);
      expect(adjustMessages.single.bytesToAdd, 32);

      await sub.cancel();
      controller.destroy();
    });

    test('splits outgoing channel data to remote maximum packet size',
        () async {
      final sentMessages = <SSHMessage>[];
      final controller = SSHChannelController(
        localId: 1,
        localMaximumPacketSize: 32768,
        localInitialWindowSize: 1024,
        remoteId: 42,
        remoteMaximumPacketSize: 32,
        remoteInitialWindowSize: 100,
        sendMessage: sentMessages.add,
      );

      controller.channel.addData(Uint8List(100));

      for (var i = 0; i < 50; i++) {
        if (sentMessages.whereType<SSH_Message_Channel_Data>().length == 4) {
          break;
        }
        await Future<void>.delayed(Duration.zero);
      }

      final dataMessages =
          sentMessages.whereType<SSH_Message_Channel_Data>().toList();
      final lengths = dataMessages.map((m) => m.data.length).toList();

      expect(dataMessages.length, 4);
      expect(lengths, [32, 32, 32, 4]);
      expect(lengths.every((len) => len <= 32), isTrue);

      controller.destroy();
    });

    test('sendShell resolves from channel request success/failure replies',
        () async {
      final sentMessages = <SSHMessage>[];
      final controller = SSHChannelController(
        localId: 1,
        localMaximumPacketSize: 32768,
        localInitialWindowSize: 1024,
        remoteId: 42,
        remoteMaximumPacketSize: 32768,
        remoteInitialWindowSize: 0,
        sendMessage: sentMessages.add,
      );

      final successFuture = controller.sendShell();
      expect(
        sentMessages.single,
        isA<SSH_Message_Channel_Request>()
            .having((m) => m.requestType, 'requestType', 'shell')
            .having((m) => m.wantReply, 'wantReply', true),
      );

      controller.handleMessage(
        SSH_Message_Channel_Success(recipientChannel: controller.localId),
      );
      expect(await successFuture, isTrue);

      final failureFuture = controller.sendShell();
      controller.handleMessage(
        SSH_Message_Channel_Failure(recipientChannel: controller.localId),
      );
      expect(await failureFuture, isFalse);

      controller.destroy();
    });
  });
}
