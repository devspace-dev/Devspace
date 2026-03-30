import 'package:devspace/models/conversation_model.dart';
import 'package:devspace/providers/messages_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('init loads conversations and merges unread counts', () async {
    final provider = MessagesProvider(
      conversationStreamLoader: (_) => Stream.value([
        _conversation(id: 'conv-1'),
        _conversation(id: 'conv-2'),
      ]),
      unreadCountsLoader: (_, ids) async {
        expect(ids, ['conv-1', 'conv-2']);
        return {'conv-1': 2};
      },
    );

    await provider.init('user-1');
    await Future<void>.delayed(Duration.zero);

    expect(provider.isLoading, isFalse);
    expect(provider.error, isNull);
    expect(provider.conversations, hasLength(2));
    expect(provider.conversations.first.unreadCount, 2);
    expect(provider.totalUnreadCount, 2);

    provider.dispose();
  });

  test('send exposes failure state for a conversation', () async {
    final provider = MessagesProvider(
      messageSender: ({
        required conversationId,
        required senderId,
        required content,
      }) async {
        throw StateError('backend unavailable');
      },
    );

    final success = await provider.send('conv-1', 'user-1', 'hello');

    expect(success, isFalse);
    expect(provider.isSending('conv-1'), isFalse);
    expect(
      provider.sendError('conv-1'),
      contains('Failed to send message'),
    );

    provider.dispose();
  });

  test('markConversationRead clears the local unread count', () async {
    var readCalls = 0;
    final provider = MessagesProvider(
      conversationStreamLoader: (_) => Stream.value([_conversation(id: 'conv-1')]),
      unreadCountsLoader: (_, __) async => {'conv-1': 3},
      conversationReadMarker: (_, __) async {
        readCalls += 1;
      },
    );

    await provider.init('user-1');
    await Future<void>.delayed(Duration.zero);
    await provider.markConversationRead('conv-1', 'user-1');

    expect(readCalls, 1);
    expect(provider.conversations.single.unreadCount, 0);

    provider.dispose();
  });

  test('refresh forces a new subscription load for the same user', () async {
    var loads = 0;
    final provider = MessagesProvider(
      conversationStreamLoader: (_) {
        loads += 1;
        return Stream.value([_conversation(id: 'conv-$loads')]);
      },
    );

    await provider.init('user-1');
    await Future<void>.delayed(Duration.zero);
    await provider.refresh();
    await Future<void>.delayed(Duration.zero);

    expect(loads, 2);
    expect(provider.conversations.single.id, 'conv-2');

    provider.dispose();
  });
}

ConversationModel _conversation({required String id}) {
  return ConversationModel(
    id: id,
    participants: const ['user-1', 'user-2'],
    createdAt: DateTime.utc(2026, 3, 28),
    lastMessageAt: DateTime.utc(2026, 3, 28, 9),
  );
}
