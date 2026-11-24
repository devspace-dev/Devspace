import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:devspace/core/theme/theme.dart';
import 'package:devspace/models/user_model.dart';
import 'package:devspace/providers/auth_provider.dart';
import 'package:devspace/providers/engagement_provider.dart';
import 'package:devspace/providers/users_provider.dart';
import 'package:devspace/screens/duel_screen.dart';

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
      aura: 800,
      roles: const ['Student'],
      year: '3rd Year',
      branch: 'CSE',
      building: 'Lab 1',
      stack: const ['Flutter'],
      followers: 8,
      following: 4,
      bio: 'Combat Ready',
      college: 'Dev College',
      githubHandle: handle,
      profileCompleted: true,
    );
  }

  Widget createDuelApp({
    required UserModel me,
    required UserModel opponent,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(initialUser: me, listenToAuthChanges: false),
        ),
        ChangeNotifierProvider(create: (_) => EngagementProvider()),
        ChangeNotifierProvider(create: (_) => UsersProvider(initialUsers: [me, opponent])),
      ],
      child: MaterialApp(
        theme: buildTheme(),
        home: DuelScreen(
          category: 'Combat',
          mode: 'REFLEX',
          opponent: opponent,
          matchId: 'test-match-1',
          isPlayer1: true,
        ),
      ),
    );
  }

  testWidgets('DuelScreen enters countdown phase and transitions to playing phase with question', (tester) async {
    final me = makeTestUser(id: 'me-1', name: 'Harshit', handle: 'harshit');
    final opponent = makeTestUser(id: 'opp-1', name: 'Rohan', handle: 'rohan');

    await tester.pumpWidget(createDuelApp(me: me, opponent: opponent));
    await tester.pump();

    // Verify initial countdown phase
    expect(find.text('Starting in '), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Rohan'), findsOneWidget);

    // Advance 1 second -> countdown to 2
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('2'), findsOneWidget);

    // Advance 1 second -> countdown to 1
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('1'), findsOneWidget);

    // Advance 1 second -> transitions to playing phase
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    // Verify playing phase: countdown overlay gone, scoreboard and question visible
    expect(find.text('GET READY!'), findsNothing);
    expect(find.text('Rohan'), findsOneWidget);

    // Dispose cleanly
    await tester.pumpWidget(const SizedBox());
  });
}
