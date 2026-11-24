import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:devspace/core/theme/colors.dart';
import 'package:devspace/core/theme/theme.dart';
import 'package:devspace/features/community/screens/builder_search_screen.dart';
import 'package:devspace/features/community/screens/community_screen.dart';
import 'package:devspace/models/conversation_model.dart';
import 'package:devspace/models/event_access_model.dart';
import 'package:devspace/models/post_model.dart';
import 'package:devspace/models/user_model.dart';
import 'package:devspace/providers/auth_provider.dart';
import 'package:devspace/providers/engagement_provider.dart';
import 'package:devspace/providers/messages_provider.dart';
import 'package:devspace/providers/posts_provider.dart';
import 'package:devspace/providers/users_provider.dart';
import 'package:devspace/screens/messages_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final testUser = UserModel(
    id: 'u-self',
    name: 'Harshit Raj',
    handle: 'harshit',
    email: 'harshit@example.com',
    avatar: '',
    color: Colors.black,
    aura: 820,
    roles: const ['Student'],
    year: '3rd Year',
    branch: 'CSE',
    building: 'DevSpace',
    stack: const ['Flutter', 'PostgreSQL'],
    followers: 15,
    following: 10,
    bio: 'Student builder',
    college: 'IIIT Delhi',
    githubHandle: 'harshit',
    profileCompleted: true,
    currentStreak: 6,
  );

  final samplePost = PostModel(
    id: 'p-1',
    userId: 'u-self',
    content:
        'Building the new DevSpace dark gaming UI with chunky 3D buttons and Aura currency!',
    tags: const ['flutter', 'buildInPublic'],
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    likes: 8,
    comments: 3,
  );

  const sampleEvent = EventAccessModel(
    id: 'e-1',
    title: 'HackDev 2026',
    description: 'National college hackathon',
    requiredAura: 200,
    link: 'https://example.com',
    type: 'hackathon',
    unlocked: true,
    locked: false,
    date: 'Oct 30, 2026',
    organizer: 'DevSpace Community',
    location: 'Bengaluru, India',
  );

  Widget createCommunityApp({
    List<PostModel>? posts,
    PostsPageLoader? postsPageLoader,
    List<EventAccessModel>? events,
    List<UserModel>? users,
    MessagesProvider? messagesProvider,
  }) {
    final msgP = messagesProvider ??
        MessagesProvider(
          conversationStreamLoader: (_) => Stream.value(const []),
          unreadCountsLoader: (_, __) async => const {},
        );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            initialUser: testUser,
            listenToAuthChanges: false,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => PostsProvider(
            initialPosts: posts ?? [samplePost],
            postsPageLoader: postsPageLoader ??
                ({required limit, required offset}) async =>
                    posts ?? [samplePost],
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => UsersProvider(
            initialUsers: users ?? [testUser],
            usersPageLoader: ({int limit = 20, int offset = 0, String? query}) async =>
                users ?? [testUser],
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => EngagementProvider(
            eligibleEventsLoader: () async => events ?? [sampleEvent],
          ),
        ),
        ChangeNotifierProvider<MessagesProvider>.value(value: msgP),
      ],
      child: MaterialApp(
        theme: buildTheme(),
        home: const CommunityScreen(),
      ),
    );
  }

  testWidgets(
      'CommunityScreen renders Community title, inbox button, 2 tabs only, and create post button',
      (tester) async {
    await tester.pumpWidget(createCommunityApp());
    await tester.pumpAndSettle();

    expect(find.text('Community'), findsOneWidget);
    expect(find.text('FEED'), findsOneWidget);
    expect(find.text('EVENTS'), findsOneWidget);
    expect(find.text('Q&A'), findsNothing);
    expect(find.text('PEOPLE'), findsNothing);
    expect(find.byIcon(Icons.mail_outline_rounded), findsOneWidget);
    expect(
      find.bySemanticsLabel('Inbox, 0 unread messages'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(
      find.text('Search builders by name, @handle or stack'),
      findsOneWidget,
    );
  });

  testWidgets('Inbox button shows coral dot only when unread messages > 0 and opens MessagesScreen with back button',
      (tester) async {
    final messagesP = MessagesProvider(
      conversationStreamLoader: (_) => Stream.value([
        ConversationModel(
          id: 'c-1',
          participants: const ['u-self', 'u-other'],
          createdAt: DateTime.now(),
          unreadCount: 3,
        ),
      ]),
      unreadCountsLoader: (_, ids) async => {for (final id in ids) id: 3},
    );
    await messagesP.init('u-self');

    await tester.pumpWidget(createCommunityApp(messagesProvider: messagesP));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel('Inbox, 3 unread messages'),
      findsOneWidget,
    );
    final coralDotFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).color == Ds.hot &&
          (widget.decoration as BoxDecoration).shape == BoxShape.circle,
    );
    expect(coralDotFinder, findsOneWidget);

    await tester.tap(find.byIcon(Icons.mail_outline_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(MessagesScreen), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
  });

  testWidgets('CommunityScreen renders feed post, switches to Events tab, and opens BuilderSearchScreen',
      (tester) async {
    await tester.pumpWidget(createCommunityApp());
    await tester.pumpAndSettle();

    expect(find.text('Harshit Raj'), findsOneWidget);
    expect(find.textContaining('Building the new DevSpace'), findsOneWidget);
    expect(find.text('8'), findsOneWidget); // likes
    expect(find.text('3'), findsOneWidget); // comments

    // Switch to EVENTS tab -> search bar is only under Feed
    await tester.tap(find.text('EVENTS'));
    await tester.pumpAndSettle();
    expect(
      find.text('Search builders by name, @handle or stack'),
      findsNothing,
    );

    // Switch back to FEED and tap search bar -> opens BuilderSearchScreen
    await tester.tap(find.text('FEED'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Search builders by name, @handle or stack'));
    await tester.pumpAndSettle();

    expect(find.byType(BuilderSearchScreen), findsOneWidget);
  });

  testWidgets('Feed shows error with retry when fetchFeed fails and list is empty',
      (tester) async {
    await tester.pumpWidget(
      createCommunityApp(
        posts: const [],
        postsPageLoader: ({required limit, required offset}) async {
          throw Exception('Network error');
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unable to load feed'), findsOneWidget);
    expect(find.text('RETRY'), findsOneWidget);
  });
}
