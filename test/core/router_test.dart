import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:devspace/core/router.dart';
import 'package:devspace/core/theme/theme.dart';
import 'package:devspace/providers/auth_provider.dart';
import 'package:devspace/providers/engagement_provider.dart';
import 'package:devspace/providers/users_provider.dart';
import 'package:devspace/providers/posts_provider.dart';
import 'package:devspace/providers/questions_provider.dart';
import 'package:devspace/providers/notifications_provider.dart';
import 'package:devspace/providers/messages_provider.dart';
import 'package:devspace/providers/practice_provider.dart';
import 'package:devspace/features/play/screens/play_screen.dart';
import 'package:devspace/features/path/screens/path_screen.dart';
import 'package:devspace/features/ranks/screens/ranks_screen.dart';
import 'package:devspace/features/community/screens/community_screen.dart';
import 'package:devspace/features/profile/screens/profile_screen.dart';
import 'package:devspace/models/user_model.dart';
import 'package:devspace/features/quiz/screens/quiz_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final testUser = UserModel(
    id: 'test-user-id',
    name: 'Harshit Raj',
    handle: 'harshit',
    email: 'harshit@example.com',
    avatar: '',
    color: Colors.black,
    aura: 715,
    roles: const ['Student'],
    year: '3rd Year',
    branch: 'CSE',
    building: 'DevSpace',
    stack: const ['Flutter', 'Postgres'],
    followers: 10,
    following: 5,
    bio: 'Building things',
    college: 'Test College',
    githubHandle: 'harshit',
    profileCompleted: true,
    currentStreak: 7,
  );

  Widget createTestApp({required String initialLocation}) {
    final testRouter = createRouter(
      initialLocation: initialLocation,
      enableAuthRedirect: false,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            initialUser: testUser,
            listenToAuthChanges: false,
          ),
        ),
        ChangeNotifierProvider(create: (_) => EngagementProvider()),
        ChangeNotifierProvider(create: (_) => UsersProvider()),
        ChangeNotifierProvider(create: (_) => PostsProvider()),
        ChangeNotifierProvider(create: (_) => QuestionsProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ChangeNotifierProvider(create: (_) => MessagesProvider()),
        ChangeNotifierProvider(create: (_) => PracticeProvider()),
      ],
      child: MaterialApp.router(
        theme: buildTheme(),
        routerConfig: testRouter,
      ),
    );
  }

  testWidgets('Router loads /play by default and renders PlayScreen with DsNavBar', (tester) async {
    await tester.pumpWidget(createTestApp(initialLocation: '/play'));
    await tester.pumpAndSettle();

    expect(find.byType(PlayScreen), findsOneWidget);
    expect(find.text('DEVSPACE'), findsOneWidget);
    expect(find.text('QUEUE UP'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Path'), findsOneWidget);
  });

  testWidgets('Tapping Path nav tab switches branch to PathScreen', (tester) async {
    await tester.pumpWidget(createTestApp(initialLocation: '/play'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Path'));
    await tester.pumpAndSettle();

    expect(find.byType(PathScreen), findsOneWidget);
    expect(find.text('PATH'), findsOneWidget);
    expect(find.textContaining('NODES'), findsOneWidget);
  });

  testWidgets('Tapping Ranks nav tab switches branch to RanksScreen', (tester) async {
    await tester.pumpWidget(createTestApp(initialLocation: '/play'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ranks'));
    await tester.pumpAndSettle();

    expect(find.byType(RanksScreen), findsOneWidget);
    expect(find.text('RANKS'), findsOneWidget);
  });

  testWidgets('Tapping Community nav tab switches branch to CommunityScreen', (tester) async {
    await tester.pumpWidget(createTestApp(initialLocation: '/play'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Community'));
    await tester.pumpAndSettle();

    expect(find.byType(CommunityScreen), findsOneWidget);
    expect(find.text('COMMUNITY'), findsOneWidget);
  });

  testWidgets('Tapping Profile nav tab switches branch to ProfileScreen', (tester) async {
    await tester.pumpWidget(createTestApp(initialLocation: '/play'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('PROFILE'), findsOneWidget);
  });

  testWidgets('Navigating to full-screen /quiz/ranked loads QuizScreen without DsNavBar', (tester) async {
    await tester.pumpWidget(createTestApp(initialLocation: '/quiz/ranked'));
    await tester.pumpAndSettle();

    expect(find.byType(QuizScreen), findsOneWidget);
    expect(find.text('HARD'), findsOneWidget);
    expect(find.text('Play'), findsNothing);
  });
}
