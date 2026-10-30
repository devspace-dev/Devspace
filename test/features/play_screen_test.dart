import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:devspace/core/theme/theme.dart';
import 'package:devspace/models/user_model.dart';
import 'package:devspace/models/daily_challenge_model.dart';
import 'package:devspace/providers/auth_provider.dart';
import 'package:devspace/providers/engagement_provider.dart';
import 'package:devspace/features/play/screens/play_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final testUser = UserModel(
    id: 'user-1',
    name: 'Harshit Raj',
    handle: 'harshit',
    email: 'harshit@example.com',
    avatar: '',
    color: Colors.black,
    aura: 750,
    roles: const ['Student'],
    year: '3rd Year',
    branch: 'CSE',
    building: 'DevSpace',
    stack: const ['Flutter', 'Postgres'],
    followers: 12,
    following: 6,
    bio: 'Student builder',
    college: 'IIIT Delhi',
    githubHandle: 'harshit',
    profileCompleted: true,
    currentStreak: 5,
  );

  Widget createPlayScreenApp({
    UserModel? user,
    DailyChallengeModel? challenge,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            initialUser: user ?? testUser,
            listenToAuthChanges: false,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => EngagementProvider(
            initialDailyChallenge: challenge,
            dailyChallengeLoader: ({techStack}) async => challenge,
          ),
        ),
      ],
      child: MaterialApp(
        theme: buildTheme(),
        home: const PlayScreen(),
      ),
    );
  }

  testWidgets('PlayScreen renders speech bubble empty state when no mission today', (tester) async {
    await tester.pumpWidget(createPlayScreenApp());
    await tester.pumpAndSettle();

    expect(find.text('DEVSPACE'), findsOneWidget);
    expect(find.text('No mission today. Touch grass, or practice.'), findsOneWidget);
  });

  testWidgets('PlayScreen renders speech bubble with streak and user name when mission exists', (tester) async {
    final sampleChallenge = DailyChallengeModel(
      assignmentId: 'a-1',
      challengeId: 'c-1',
      assignedDate: DateTime.now(),
      selectedTechStack: 'Flutter',
      completed: false,
      completedAt: null,
      title: 'Daily puzzle: mate in 2',
      description: 'Solve puzzle',
      difficulty: 'Easy',
      techStack: 'Flutter',
      pointsReward: 10,
      missionType: 'mcq',
      question: 'Question?',
      options: const ['A', 'B'],
      link: '',
      isCorrect: false,
    );

    await tester.pumpWidget(createPlayScreenApp(challenge: sampleChallenge));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('DEVSPACE'), findsOneWidget);
    expect(find.text('Day 5 streak, Harshit. Do not ruin it.'), findsOneWidget);
  });

  testWidgets('PlayScreen renders Continue Path at the end and removes college rivalry', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createPlayScreenApp());
    await tester.pumpAndSettle();

    expect(find.text('CONTINUE PATH'), findsOneWidget);
    expect(find.text('REACT & STATE MANAGEMENT'), findsOneWidget);
    expect(find.text('CONTINUE'), findsOneWidget);

    // College rivalry should be removed
    expect(find.textContaining('vs Apex Tech'), findsNothing);
    expect(find.textContaining('You are 140 Aura ahead'), findsNothing);
  });

  testWidgets('PlayScreen renders Daily Puzzle and 2x2 lobby queue grid', (tester) async {
    await tester.pumpWidget(createPlayScreenApp());
    await tester.pumpAndSettle();

    expect(find.text('DAILY PUZZLE'), findsOneWidget);
    expect(find.text('QUEUE UP'), findsOneWidget);

    expect(find.text('NOOB LOBBY'), findsOneWidget);
    expect(find.text('SCRIMS'), findsOneWidget);
    expect(find.text('RANKED'), findsOneWidget);
    expect(find.text('FINAL CIRCLE'), findsOneWidget);

    expect(find.text('+5 AURA'), findsOneWidget);
    expect(find.text('+10 AURA'), findsOneWidget);
    expect(find.text('+15 AURA'), findsOneWidget);
    expect(find.text('+20 AURA'), findsOneWidget);
  });

  testWidgets('PlayScreen renders Combat 1v1 section with Reflex first and Code Combat second', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createPlayScreenApp());
    await tester.pumpAndSettle();

    expect(find.text('COMBAT'), findsOneWidget);
    expect(find.text('REFLEX 1v1'), findsOneWidget);
    expect(find.text('CODE COMBAT'), findsOneWidget);
    expect(find.text('+25 AURA'), findsOneWidget);
    expect(find.text('+50 AURA'), findsOneWidget);

    // Verify ordering: Mascot -> Daily Puzzle -> Solo (Queue Up) -> Combat -> Continue Path
    final mascotY = tester.getTopLeft(find.text('DEVSPACE')).dy;
    final puzzleY = tester.getTopLeft(find.text('DAILY PUZZLE')).dy;
    final queueY = tester.getTopLeft(find.text('QUEUE UP')).dy;
    final combatY = tester.getTopLeft(find.text('COMBAT')).dy;
    final continuePathY = tester.getTopLeft(find.text('CONTINUE PATH')).dy;

    expect(mascotY < puzzleY, isTrue);
    expect(puzzleY < queueY, isTrue);
    expect(queueY < combatY, isTrue);
    expect(combatY < continuePathY, isTrue);
  });
}
