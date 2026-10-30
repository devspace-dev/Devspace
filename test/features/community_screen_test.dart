import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:devspace/core/theme/theme.dart';
import 'package:devspace/models/event_access_model.dart';
import 'package:devspace/models/post_model.dart';
import 'package:devspace/models/question_model.dart';
import 'package:devspace/models/user_model.dart';
import 'package:devspace/providers/auth_provider.dart';
import 'package:devspace/providers/engagement_provider.dart';
import 'package:devspace/providers/posts_provider.dart';
import 'package:devspace/providers/questions_provider.dart';
import 'package:devspace/providers/users_provider.dart';
import 'package:devspace/features/community/screens/community_screen.dart';

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
    content: 'Building the new DevSpace dark gaming UI with chunky 3D buttons and Aura currency!',
    tags: const ['flutter', 'buildInPublic'],
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    likes: 8,
    comments: 3,
  );

  final sampleEvent = const EventAccessModel(
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

  final sampleQuestion = QuestionModel(
    id: 'q-1',
    userId: 'u-self',
    title: 'How to structure GoRouter with StatefulShellRoute?',
    body: 'Looking for best practices in Flutter when using indexedStack.',
    tags: const ['flutter', 'routing'],
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    upvotesCount: 14,
    repliesCount: 4,
    solvedReplyId: 'r-1',
  );

  Widget createCommunityApp({
    List<PostModel>? posts,
    List<QuestionModel>? questions,
    List<EventAccessModel>? events,
    List<UserModel>? users,
  }) {
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
            postsPageLoader: ({required limit, required offset}) async => posts ?? [samplePost],
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => QuestionsProvider(
            initialQuestions: questions ?? [sampleQuestion],
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => UsersProvider(
            initialUsers: users ?? [testUser],
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => EngagementProvider(
            eligibleEventsLoader: () async => events ?? [sampleEvent],
          ),
        ),
      ],
      child: MaterialApp(
        theme: buildTheme(),
        home: const CommunityScreen(),
      ),
    );
  }

  testWidgets('CommunityScreen renders top bar, 4 tabs, and floating create post button', (tester) async {
    await tester.pumpWidget(createCommunityApp());
    await tester.pumpAndSettle();

    expect(find.text('COMMUNITY'), findsOneWidget);
    expect(find.text('FEED'), findsOneWidget);
    expect(find.text('EVENTS'), findsOneWidget);
    expect(find.text('Q&A'), findsOneWidget);
    expect(find.text('PEOPLE'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('CommunityScreen renders feed post with author, content, and engagement counts', (tester) async {
    await tester.pumpWidget(createCommunityApp());
    await tester.pumpAndSettle();

    expect(find.text('Harshit Raj'), findsOneWidget);
    expect(find.textContaining('Building the new DevSpace'), findsOneWidget);
    expect(find.text('8'), findsOneWidget); // likes
    expect(find.text('3'), findsOneWidget); // comments
  });

  testWidgets('CommunityScreen switches tabs to Q&A and People', (tester) async {
    await tester.pumpWidget(createCommunityApp());
    await tester.pumpAndSettle();

    // Switch to Q&A tab
    await tester.tap(find.text('Q&A'));
    await tester.pumpAndSettle();

    expect(find.text('How to structure GoRouter with StatefulShellRoute?'), findsOneWidget);
    expect(find.text('SOLVED'), findsOneWidget);
    expect(find.text('14'), findsOneWidget); // upvotes

    // Switch to PEOPLE tab
    await tester.tap(find.text('PEOPLE'));
    await tester.pumpAndSettle();

    expect(find.text('Harshit Raj'), findsOneWidget);
    expect(find.textContaining('@harshit'), findsOneWidget);
  });
}
