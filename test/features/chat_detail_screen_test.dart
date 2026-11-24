import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:devspace/core/theme/theme.dart';
import 'package:devspace/models/conversation_model.dart';
import 'package:devspace/models/message_model.dart';
import 'package:devspace/models/user_model.dart';
import 'package:devspace/providers/auth_provider.dart';
import 'package:devspace/providers/messages_provider.dart';
import 'package:devspace/screens/chat_detail_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  UserModel makeTestUser({
    required String id,
    required String name,
    required String handle,
  }) {
    return UserModel(
      id: id,
      name: name,
      handle: handle,
      email: '$handle@example.com',
      avatar: '',
      color: Colors.blue,
      aura: 600,
      roles: const ['Student'],
      year: '3rd Year',
      branch: 'CSE',
      building: 'Lab 2',
      stack: const ['Flutter', 'Dart'],
      followers: 10,
      following: 5,
      bio: 'Building things',
      college: 'National Engineering College',
      githubHandle: handle,
      profileCompleted: true,
    );
  }

  ConversationModel makeTestConversation({
    required String id,
    required List<String> participants,
  }) {
    return ConversationModel(
      id: id,
      participants: participants,
      lastMessage: 'Hey there!',
      lastMessageAt: DateTime.now(),
      createdAt: DateTime.now(),
      unreadCount: 0,
    );
  }

  MessageModel makeTestMessage({
    required String id,
    required String conversationId,
    required String senderId,
    required String content,
  }) {
    return MessageModel(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      recipientId: senderId == 'user-me' ? 'user-other' : 'user-me',
      content: content,
      isRead: true,
      createdAt: DateTime.now(),
    );
  }

  testWidgets('ChatDetailScreen renders recipient header, messages list, and input field', (tester) async {
    final me = makeTestUser(id: 'user-me', name: 'Harshit', handle: 'harshit');
    final other = makeTestUser(id: 'user-other', name: 'Zara Dev', handle: 'zaradev');
    final conversation = makeTestConversation(id: 'conv-101', participants: ['user-me', 'user-other']);

    final messages = [
      makeTestMessage(id: 'm1', conversationId: 'conv-101', senderId: 'user-other', content: 'Hey, are you working on Flutter?'),
      makeTestMessage(id: 'm2', conversationId: 'conv-101', senderId: 'user-me', content: 'Yes, just testing the chat flow!'),
    ];

    final messagesProvider = MessagesProvider(
      messageStreamLoader: (_) => Stream.value(messages),
      conversationReadMarker: (_, __) async {},
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthProvider(initialUser: me, listenToAuthChanges: false),
          ),
          ChangeNotifierProvider.value(value: messagesProvider),
        ],
        child: MaterialApp(
          theme: buildTheme(),
          home: ChatDetailScreen(
            conversation: conversation,
            otherUser: other,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify header details
    expect(find.text('Zara Dev'), findsOneWidget);
    expect(find.text('3rd Year · CSE'), findsOneWidget);

    // Verify messages displayed
    expect(find.text('Hey, are you working on Flutter?'), findsOneWidget);
    expect(find.text('Yes, just testing the chat flow!'), findsOneWidget);

    // Verify compose input and send button
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.send_rounded), findsOneWidget);

    messagesProvider.dispose();
  });
}
